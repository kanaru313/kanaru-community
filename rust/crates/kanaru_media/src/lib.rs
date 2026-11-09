//! Media files: tags, embedded and folder covers, waveform levels.
//!
//! Plain Rust with no FFI and no knowledge of `kanaru_plugin_runtime`.
//! Functions take a `Read + Seek` source; the bridge turns a path or an
//! Android file descriptor into one.

pub mod cancel;
pub mod covers;
pub mod error;
pub mod limits;
pub mod tags;
pub mod waveform;

pub use cancel::Cancel;
pub use error::MediaError;

/// Version of this crate, so the bridge can report what it links.
pub const CRATE_VERSION: &str = env!("CARGO_PKG_VERSION");
