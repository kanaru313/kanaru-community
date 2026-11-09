//! Size limits that keep one bad file from exhausting memory or time.

/// Largest file read fully into memory when the source cannot seek
/// (a pipe-like source): 256 MiB, above any real track.
pub const MAX_FILE_BYTES_UNSEEKABLE: u64 = 256 * 1024 * 1024;

/// Largest embedded or sidecar cover read: 32 MiB. Real covers are well under
/// 10 MiB; a larger one is damaged or hostile.
pub const MAX_COVER_BYTES: u64 = 32 * 1024 * 1024;

/// Largest cover decoded, in pixels: 40 MP (about 160 MB as RGBA). A bigger
/// image is rejected from its header, before any pixel buffer is allocated.
pub const MAX_COVER_PIXELS: u64 = 40_000_000;

/// Time budget for reading the tags of one file, in seconds. The deadline
/// bounds slow work between `Cancel::check` calls and ends as `Timeout`
/// (transient). A syscall blocked inside the kernel (a stalled network mount)
/// is not interrupted by it: the scanner must isolate such roots itself.
pub const MAX_TAG_FILE_SECONDS: u64 = 30;
