//! Which native library the app loaded, for logs and the About page.

use std::sync::Once;

/// Versions of the bridge and the crates it links, e.g.
/// `bridge 0.1.0, media 0.1.0, plugin_runtime 0.1.0`.
#[flutter_rust_bridge::frb(sync)]
pub fn native_versions() -> String {
    format!(
        "bridge {}, media {}, plugin_runtime {}",
        env!("CARGO_PKG_VERSION"),
        kanaru_media::CRATE_VERSION,
        kanaru_plugin_runtime::CRATE_VERSION,
    )
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    // Once per process: Dart calls this again after a hot restart while the
    // library stays loaded, and a second run would stack another frb hook above
    // the bridge hook (a backtrace capture per guarded panic again).
    static INIT: Once = Once::new();
    INIT.call_once(|| {
        // Warn, not frb's default Trace: keeps frb's and lofty's warnings but
        // drops lofty's per-frame trace/debug lines from logcat.
        flutter_rust_bridge::setup_log_to_console(log::LevelFilter::Warn);
        flutter_rust_bridge::setup_backtrace();
        // Above frb's hook: a guarded panic is expected and gets one line, so
        // it never reaches the backtrace capture and std's full print.
        crate::guard::install_hook();
        // Above the bridge hook: plugin host-callback panics stay silent.
        kanaru_plugin_runtime::install_quiet_panic_hook();
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn native_versions_names_every_crate() {
        let text = native_versions();
        assert!(text.starts_with("bridge "));
        assert!(text.contains("media "));
        assert!(text.contains("plugin_runtime "));
    }
}
