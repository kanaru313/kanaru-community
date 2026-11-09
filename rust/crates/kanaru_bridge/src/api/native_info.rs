//! Which native library the app loaded, for logs and the About page.

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
    flutter_rust_bridge::setup_default_user_utils();
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
