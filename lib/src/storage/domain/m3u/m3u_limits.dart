// Bounds for reading an untrusted M3U file: a bigger file, a longer line or
// more path lines than these is cut or refused instead of read in full.

/// Largest file read, in bytes (16 MiB).
const m3uMaxBytes = 16 * 1024 * 1024;

/// Longest line a player could have written, in raw bytes. A longer line is
/// reported as unusable without being resolved.
const m3uMaxLineBytes = 4096;

/// Most path lines read from one file; the rest is dropped and reported.
const m3uMaxPathLines = 50000;

/// Longest playlist name made from a file name, in graphemes.
const m3uNameMaxLength = 100;
