//! JS features the lyrics plugins rely on: `String.prototype.normalize`,
//! template literals and the CryptoJS calls of the ZingMP3 / Spotify plugins.

// Helpers outside `#[test]` functions may unwrap too.
#![allow(clippy::unwrap_used)]

mod common;

use common::run_script;
use kanaru_plugin_runtime::ScriptStatus as S;

#[test]
fn normalize_composes_and_decomposes() {
    let _t = common::test();
    // "e" + combining acute, and the Vietnamese "ệ" in decomposed form.
    let r = run_script(
        "function execute() {
           var nfd = 'e\\u0301', viet = 'e\\u0323\\u0302';
           return Response.success([
             nfd.normalize('NFC') === '\\u00e9',
             nfd.normalize('NFC').length,
             '\\u00e9'.normalize('NFD').length,
             viet.normalize('NFC') === '\\u1ec7',
             '\\ufb01'.normalize('NFKC') === 'fi',
             '  caf\\u00e9 '.trim().normalize('NFC')
           ]);
         }",
        0,
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(r.output_json, r#"[true,1,2,true,true,"café"]"#);
}

#[test]
fn template_literals_interpolate() {
    let _t = common::test();
    let r = run_script(
        "function execute(input) {
           var a = 'x', n = 3;
           return Response.success([`${a}-${n + 1}`, `line1
line2`.length]);
         }",
        0,
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(r.output_json, r#"["x-4",11]"#);
}

#[test]
fn hmac_sha512_and_sha1_match_published_values() {
    let _t = common::test();
    let r = run_script(
        "function execute() {
           load('crypto.js');
           var msg = 'The quick brown fox jumps over the lazy dog';
           return Response.success([
             CryptoJS.HmacSHA512(msg, 'key').toString(),
             CryptoJS.HmacSHA1(msg, 'key').toString(CryptoJS.enc.Hex)
           ]);
         }",
        0,
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(
        r.output_json,
        concat!(
            r#"["b42af09057bac1e2d41708e48a902e09b5ff7f12ab428a4fe86653c73dd248fb"#,
            r#"82f948a549f7b791a5b41915ee4d1ec3935357e4e2317250d0372afa2ebeeb3a","#,
            r#""de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9"]"#
        )
    );
}

#[test]
fn word_array_message_hmac_equals_the_hex_message_hmac() {
    let _t = common::test();
    // The Spotify plugin builds an 8-byte message from two words.
    let r = run_script(
        "function execute() {
           load('crypto.js');
           var words = CryptoJS.lib.WordArray.create([0x00010203, 0x04050607], 8);
           var key = CryptoJS.enc.Utf8.parse('secret');
           var viaWords = CryptoJS.HmacSHA1(words, key).toString(CryptoJS.enc.Hex);
           var viaHex = CryptoJS.HmacSHA1(CryptoJS.enc.Hex.parse('0001020304050607'), key)
             .toString(CryptoJS.enc.Hex);
           return Response.success([viaWords === viaHex, viaWords.length, words.sigBytes]);
         }",
        0,
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(r.output_json, "[true,40,8]");
}
