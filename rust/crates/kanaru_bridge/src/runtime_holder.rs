//! The process's one plugin runtime, started on first use.

use std::sync::{Arc, OnceLock};

use kanaru_plugin_runtime::{install_quiet_panic_hook, PluginRuntime, RuntimeConfig};

use crate::pools::config;

/// Called first on every runtime thread. Plugin JS and stream workers run
/// work the user is waiting for, so they keep normal priority; lowering the
/// thread (`os::lower_current_thread_priority()`) for a `name` would go here.
fn thread_started(_name: &str) {}

static RUNTIME: OnceLock<PluginRuntime> = OnceLock::new();

/// The plugin runtime. Its threads start on the first call and live until the
/// process ends; `reset` frees them of jobs without stopping them.
pub fn runtime() -> &'static PluginRuntime {
    RUNTIME.get_or_init(|| {
        install_quiet_panic_hook();
        PluginRuntime::new(RuntimeConfig {
            workers: config::PLUGIN_WORKERS,
            queue: config::PLUGIN_QUEUE,
            stream_workers: config::PLUGIN_STREAM_WORKERS,
            stack_bytes: config::STACK_BYTES,
            on_thread_start: Some(Arc::new(thread_started)),
            ..RuntimeConfig::default()
        })
    })
}

/// The runtime if something already started it. `reset` and `cancel` use it so
/// that startup does not build the threads just to empty an empty registry.
pub fn existing() -> Option<&'static PluginRuntime> {
    RUNTIME.get()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::plugin_runtime::{cancel_plugin_job, reset_plugin_runtime};

    /// No other unit test of this crate builds the runtime, so this binary
    /// can observe the "never built" state.
    #[test]
    fn reset_and_cancel_do_not_start_the_runtime() {
        assert!(existing().is_none());
        reset_plugin_runtime();
        cancel_plugin_job(1);
        assert!(existing().is_none());
    }
}
