use std::path::{Path, PathBuf};

use anyhow::{Context, Result};
use indoc::indoc;
use nix_bindings_fetchers::FetchersSettings;
use nix_bindings_flake::{FlakeReference, FlakeReferenceParseFlags, FlakeSettings};

pub struct FlakeRef {
    pub(super) ref_: FlakeReference,
    pub path: PathBuf,

    pub flake_settings: FlakeSettings,
    pub fetch_settings: FetchersSettings,
}

impl FlakeRef {
    /// Parse a flake reference from a string.
    /// The string must be a valid flake reference, such as `github:owner/repo`.
    /// It may also be suffixed with a `#` and a fragment, such as `github:owner/repo#something`,
    /// in which case, the returned `flake_ref.path` will contain the fragment.
    pub fn new<P: AsRef<Path>>(reference: &str, base_directory: Option<P>) -> Result<FlakeRef> {
        let flake_settings = FlakeSettings::new()?;
        let fetch_settings = FetchersSettings::new()?;

        let mut flags = FlakeReferenceParseFlags::new(&flake_settings)?;

        if let Some(base_directory) = base_directory {
            flags.set_base_directory(
                base_directory
                    .as_ref()
                    .to_str()
                    .context("The given flake reference path is not provided as valid unicode")?,
            )?;
        } else {
            // TODO: try see if libnix uses the cwd as a fallback (aka is this assert pointless?)
            assert!(
                reference.starts_with("."),
                indoc! {"
                    Attempted to construct FlakeRef from relative path without declaring `base_directory`!
                    Call to `FlakeRef::absolute(&str)` should actually be `FlakeRef::relative(&str, dyn AsRef<Path>)`.
                "}
            );
        }

        FlakeReference::parse_with_fragment(&fetch_settings, &flake_settings, &flags, reference)
            .map(|(reference, path)| FlakeRef {
                ref_: reference,
                path: PathBuf::from(path),
                flake_settings,
                fetch_settings,
            })
    }

    /// >[!WARNING]
    /// > Do not use [FlakeRef::absolute(&str)](FlakeRef::absolute) to construct a [FlakeRef] from a relative path!
    /// > Use [FlakeRef::relative(&str, dyn AsRef<Path>)](FlakeRef::relative) instead to declare the `base_directory`.
    ///
    /// Parse a flake reference from a string.
    /// The string must be a valid flake reference, such as `github:owner/repo`.
    /// It may also be suffixed with a `#` and a fragment, such as `github:owner/repo#something`,
    /// in which case, the returned `flake_ref.path` will contain the fragment.
    pub fn absolute(reference: &str) -> Result<FlakeRef> {
        FlakeRef::new(reference, None::<&Path>)
    }

    /// Parse a flake reference from a string.
    /// The string must be a valid flake reference, such as `github:owner/repo`.
    /// It may also be suffixed with a `#` and a fragment, such as `github:owner/repo#something`,
    /// in which case, the returned `flake_ref.path` will contain the fragment.
    pub fn relative<P: AsRef<Path>>(reference: &str, base_directory: P) -> Result<FlakeRef> {
        FlakeRef::new(reference, Some(base_directory))
    }
}

impl Into<FlakeReference> for FlakeRef {
    fn into(self) -> FlakeReference {
        self.ref_
    }
}
