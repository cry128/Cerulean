use nix_bindings_expr::eval_state::{gc_register_my_thread, init, EvalState};
use nix_bindings_store::store::Store;
use std::collections::HashMap;

fn main() -> anyhow::Result<()> {
    // Initialize Nix library and register thread with GC
    init()?;
    let guard = gc_register_my_thread()?;

    // Open a store connection and create an evaluation state
    let store = Store::open(None, HashMap::new())?;
    let mut eval_state = EvalState::new(store, [])?;

    // Evaluate a Nix expression
    let value = eval_state.eval_from_string("[1 2 3]", "<example>")?;

    // Extract typed values
    let elements: Vec<_> = eval_state.require_list_strict(&value)?;
    for element in elements {
        let num = eval_state.require_int(&element)?;
        println!("Element: {}", num);
    }

    drop(guard);
    Ok(())
}
