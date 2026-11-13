//! The host prelude is the script-facing half of the host API (`Response`
//! helpers, `fetch`, `localStorage`, errors). It was ported byte for byte from
//! the previous app; plugins in the wild rely on its exact behaviour, so any
//! change must be deliberate: update the constants below with it.

/// FNV-1a, 64 bit: a stable hash that needs no dependency.
fn fnv1a(bytes: &[u8]) -> u64 {
    bytes.iter().fold(0xcbf2_9ce4_8422_2325, |hash, &byte| {
        (hash ^ u64::from(byte)).wrapping_mul(0x0100_0000_01b3)
    })
}

// Computed from the old app's `rust/src/plugin_runtime/js/host_prelude.js`
// (sha256 25be6c4ba7a61986f5fee7a1bcbe3313a968cd42affa7e2b46ff6e0cad70efa2).
const PRELUDE_LEN: usize = 10_362;
const PRELUDE_FNV1A: u64 = 0x6f41_8b22_e51d_352a;

#[test]
fn host_prelude_is_the_one_ported_from_the_old_app() {
    let prelude = include_bytes!("../src/js/host_prelude.js");
    assert_eq!(prelude.len(), PRELUDE_LEN, "host_prelude.js length changed");
    assert_eq!(
        fnv1a(prelude),
        PRELUDE_FNV1A,
        "host_prelude.js content changed"
    );
}
