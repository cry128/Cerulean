use std::{cell::RefCell, collections::HashMap, rc::Rc};

use anyhow::Result;
use nix_bindings_expr::{eval_state::EvalState, value::Value};
use nix_bindings_fetchers::FetchersSettings;
use nix_bindings_flake::{FlakeLockFlags, FlakeSettings, LockedFlake};
use nix_bindings_store::store::Store;

use crate::nix::FlakeRef;

#[derive(Debug, Clone)]
pub enum FlakeLockMode {
    /// Configures [LockedFlake::lock] to make incremental changes to the lock file as needed. Changes are written to file.
    WriteAsNeeded,

    /// Like [FlakeLockMode::WriteAsNeeded], but does not write to the lock file.
    Virtual,

    /// Make [LockedFlake::lock] check if the lock file is up to date. If not, an error is returned.
    Check,
}

pub struct FlakeBuilder {
    flake_ref: Rc<RefCell<FlakeRef>>,

    lock_mode: FlakeLockMode,
    lock_flags: FlakeLockFlags,
    eval_state: Option<EvalState>,
}

pub struct Flake {
    flake_ref: Rc<RefCell<FlakeRef>>,
    locked_flake: LockedFlake,

    lock_mode: FlakeLockMode,
    eval_state: EvalState,
}

impl FlakeBuilder {
    pub fn new(flake_ref: Rc<RefCell<FlakeRef>>, lock_mode: FlakeLockMode) -> Result<Self> {
        let mut lock_flags = FlakeLockFlags::new(&flake_ref.as_ref().borrow().flake_settings)?;

        match lock_mode {
            FlakeLockMode::WriteAsNeeded => lock_flags.set_mode_write_as_needed(),
            FlakeLockMode::Virtual => lock_flags.set_mode_virtual(),
            FlakeLockMode::Check => lock_flags.set_mode_check(),
        }?;

        Ok(FlakeBuilder {
            flake_ref: flake_ref,

            lock_mode,
            lock_flags,
            eval_state: None,
        })
    }

    /// Adds an input override to the lock file that will be produced.
    /// The [LockedFlake::lock] operation will not write to the lock file.
    ///
    /// # Arguments
    ///
    ///  * `path` - The input name/path to override (must not be empty)
    ///  * `flake_ref` - The flake reference to use as the override
    pub fn override_input(mut self, path: &str, flake_ref: &FlakeRef) -> Result<Self> {
        assert!(
            !path.is_empty(),
            "The input path for `FlakeBuilder::override_input` cannot be an empty string slice!"
        );

        self.lock_flags.add_input_override(path, &flake_ref.ref_)?;
        Ok(self)
    }

    pub fn build(&mut self) -> Result<Flake> {
        let eval_state = match self.eval_state.take() {
            Some(state) => state,
            None => {
                let store = Store::open(None, HashMap::new())?;
                EvalState::new(store, [])?
            }
        };

        let locked_flake = LockedFlake::lock(
            &FetchersSettings::new()?,
            &FlakeSettings::new()?,
            &eval_state,
            &self.lock_flags,
            &self.flake_ref.as_ref().borrow().ref_,
        )?;

        Ok(Flake {
            flake_ref: Rc::clone(&self.flake_ref),
            locked_flake,

            lock_mode: self.lock_mode.clone(),
            eval_state,
        })
    }
}

impl Flake {
    pub fn new(flake_ref: Rc<RefCell<FlakeRef>>, lock_mode: FlakeLockMode) -> Result<Self> {
        let mut builder = FlakeBuilder::new(flake_ref, lock_mode)?;
        builder.build()
    }

    pub fn outputs(&mut self) -> Result<Value> {
        self.locked_flake.outputs(
            &self.flake_ref.as_ref().borrow().flake_settings,
            &mut self.eval_state,
        )
    }
}
