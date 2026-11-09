//! Runs untrusted plugin JavaScript (QuickJS) with the host API plugins see.
//!
//! Plain Rust with no FFI and no knowledge of `kanaru_media`. I/O a plugin
//! asks for (fetch, sleep, stream) goes through a host trait the bridge
//! implements on the Dart side.

/// Version of this crate, so the bridge can report what it links.
pub const CRATE_VERSION: &str = env!("CARGO_PKG_VERSION");
