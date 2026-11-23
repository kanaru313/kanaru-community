//! JS features the lyrics plugins rely on: `String.prototype.normalize`,
//! template literals and the CryptoJS calls of the ZingMP3 / Spotify plugins.

// Helpers outside `#[test]` functions may unwrap too.
#![allow(clippy::unwrap_used)]

mod common;

use std::sync::Arc;

use common::{block_on, file, ok_response, request_with, rt, run_script, runtime, FakeHost};
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

/// The shape of the two-step lyrics plugins: `execute(id)` wants the bare id.
const TWO_STEP: &str = "var HOST = 'https://lyrics.test';
function execute(id) {
  if (typeof id !== 'string' || !id.trim()) return Response.success(null);
  var res = fetch(HOST + '/posts/' + encodeURIComponent(id.trim()));
  if (!res.ok) return Response.error('http ' + res.status);
  return Response.success({ data: res.json().content, type: 'txt' });
}";

fn run_two_step(input_json: &str, host: Arc<FakeHost>) -> kanaru_plugin_runtime::ScriptResult {
    let job = rt::begin_job();
    let request = request_with(job, vec![file("search.js", TWO_STEP)], input_json, 0);
    block_on(runtime().run(request, host))
}

#[test]
fn two_step_lyrics_script_gets_the_bare_id_string() {
    let _t = common::test();
    let host = FakeHost::answering(|_| ok_response(200, br#"{"content":"la la"}"#));
    let r = run_two_step("\"123\"", host.clone());
    assert_eq!(r.status, S::Ok, "{r:?}");
    let requests = host.requests();
    assert_eq!(requests.len(), 1);
    assert!(
        requests[0].url.ends_with("/posts/123"),
        "{}",
        requests[0].url
    );
    assert_ne!(r.output_json, "null");
    assert!(r.output_json.contains("la la"), "{}", r.output_json);
}

#[test]
fn two_step_lyrics_script_ignores_an_object_input() {
    let _t = common::test();
    let host = FakeHost::answering(|_| ok_response(200, br#"{"content":"la la"}"#));
    let r = run_two_step(r#"{"id":"123"}"#, host.clone());
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(r.output_json, "null");
    assert!(host.requests().is_empty());
}
