//! Runs every plugin of a plugin repository against a fake host, to check that
//! the JS host API still fits real plugins. Local only: set `KANARU_PLUGIN_REPO`
//! to the URL of a `plugins.json` served over plain HTTP, for example from a
//! clone of the plugins repository:
//!
//! ```text
//! python3 -m http.server 8765 --bind 127.0.0.1
//! KANARU_PLUGIN_REPO=http://127.0.0.1:8765/plugins.json \
//!     cargo test -p kanaru_plugin_runtime --test compat_repo -- --nocapture
//! ```
//!
//! Nothing is copied into this repository and CI never sets the variable.
//! The fake host answers every fetch with HTTP 200 and the body `{}`, so a
//! plugin usually ends early with its own error: that is fine. The test proves
//! runtime compatibility only (the globals exist, no limit trips, no crash,
//! every fetch carries the `install_id`); plugin logic is tested in the
//! plugins repository.

#![allow(clippy::unwrap_used)]

mod common;

use std::io::Read;
use std::sync::Arc;

use common::{file, ok_response, request_with, FakeHost};
use kanaru_plugin_runtime::{PluginHost, ScriptResult, ScriptStatus, SourceFile};

/// Host globals whose absence means the runtime broke the plugin API.
const HOST_GLOBALS: &[&str] = &[
    "fetch",
    "Response",
    "load",
    "localStorage",
    "localConfig",
    "console",
    "Log",
    "sleep",
    "CryptoJS",
];

/// What the test reads from `plugin.json`.
struct Manifest {
    kind: String,
    /// `(script key, file name)`, in manifest order.
    scripts: Vec<(String, String)>,
}

/// Reads a manifest with the runtime itself (no JSON crate): the raw document
/// is valid JSON, so it is embedded as `{"doc": <raw>}` and a tiny script
/// flattens what is needed into `;`-separated text.
fn flatten(code: &str, raw_json: &str) -> String {
    let job = common::rt::begin_job();
    let input = format!("{{\"doc\":{raw_json}}}");
    let request = request_with(job, vec![file("search.js", code)], &input, 10_000);
    let result = common::block_on(common::rt::run(request));
    assert_eq!(
        result.status,
        ScriptStatus::Ok,
        "manifest script failed: {:?}",
        result.js_error
    );
    // The output is one JSON string; the flattened text has no escapes.
    result.output_json.trim_matches('"').to_owned()
}

fn get(url: &str) -> Vec<u8> {
    assert!(
        url.starts_with("http://127.0.0.1") || url.starts_with("http://localhost"),
        "compat test only talks to a local server (http://127.0.0.1 or http://localhost), got {url}"
    );
    let agent: ureq::Agent = ureq::Agent::config_builder()
        .timeout_global(Some(std::time::Duration::from_secs(10)))
        .build()
        .into();
    let mut response = agent
        .get(url)
        .call()
        .unwrap_or_else(|e| panic!("GET {url}: {e}"));
    let mut body = Vec::new();
    response
        .body_mut()
        .as_reader()
        .read_to_end(&mut body)
        .unwrap_or_else(|e| panic!("read {url}: {e}"));
    body
}

fn unzip(bytes: Vec<u8>) -> Vec<(String, Vec<u8>)> {
    let mut archive = zip::ZipArchive::new(std::io::Cursor::new(bytes)).unwrap();
    let mut entries = Vec::new();
    for i in 0..archive.len() {
        let mut entry = archive.by_index(i).unwrap();
        if entry.is_dir() {
            continue;
        }
        let mut data = Vec::new();
        entry.read_to_end(&mut data).unwrap();
        let name = entry.name().expect("zip entry name").into_owned();
        entries.push((name, data));
    }
    entries
}

fn manifest(raw: &str) -> Manifest {
    let flat = flatten(
        "function execute(i){var d=i.doc,s=d.script||{},o=[d.metadata.type];\
         for(var k in s){o.push(k+'='+s[k]);}return Response.success(o.join(';'));}",
        raw,
    );
    let mut parts = flat.split(';');
    let kind = parts.next().unwrap_or_default().to_owned();
    let scripts = parts
        .filter_map(|p| p.split_once('='))
        .map(|(k, f)| (k.to_owned(), f.to_owned()))
        .collect();
    Manifest { kind, scripts }
}

/// Inputs in the shape the app sends, per kind and script key. `None`: not
/// run (only compile-checked and listed).
fn input_for(kind: &str, key: &str) -> Option<&'static str> {
    match (kind, key) {
        ("lyrics", "search") => Some(
            r#"{"title":"Test Song","artist":"Test Artist","artists":["Test Artist"],"album":null,"durationMs":200000}"#,
        ),
        ("lyrics", "lyrics") => Some(r#""123""#),
        ("translate" | "ai-translate", "translate") => Some(
            r#"{"lines":["Hello","World"],"to":"vi","song":{"title":"Test Song","artist":"Test Artist","lyrics":"Hello\nWorld"}}"#,
        ),
        ("source", "search") => Some(r#"{"query":"test"}"#),
        ("source", "stream") => Some(r#"{"id":"1","formats":["progressive","hls"]}"#),
        _ => None,
    }
}

/// The host global a failed run says is missing, if any. QuickJS reports a
/// missing function as a bare `not a function` without a name, so any such
/// error counts: a plugin that calls a non-function on the fake `{}` body would
/// show up here and has to be judged by hand (runtime bug or plugin logic).
fn missing_global(result: &ScriptResult) -> Option<String> {
    let error = result.js_error.as_ref()?;
    let text = format!("{} {}", error.message, result.error_message);
    if let Some(g) = HOST_GLOBALS
        .iter()
        .find(|g| text.contains(&format!("{g} is not defined")))
    {
        return Some((*g).to_owned());
    }
    text.contains("not a function")
        .then(|| "(unnamed: not a function)".to_owned())
}

#[test]
fn plugins_of_a_repository_run_against_a_fake_host() {
    let Ok(repo) = std::env::var("KANARU_PLUGIN_REPO") else {
        println!("skipped: KANARU_PLUGIN_REPO not set");
        return;
    };
    assert!(
        repo.starts_with("http://"),
        "KANARU_PLUGIN_REPO must be a plain http URL on localhost, got {repo}"
    );
    let base = &repo[..repo.rfind('/').unwrap() + 1];
    let _t = common::test();

    let catalog = flatten(
        "function execute(i){return Response.success(i.doc.data.map(function(e){\
         return e.slug+'|'+e.path;}).join(';'));}",
        &String::from_utf8(get(&repo)).expect("plugins.json is not UTF-8"),
    );
    let entries: Vec<(&str, &str)> = catalog
        .split(';')
        .filter_map(|e| e.split_once('|'))
        .collect();
    assert!(!entries.is_empty(), "plugins.json lists no plugin");

    let mut failures: Vec<String> = Vec::new();
    let mut table = vec![format!(
        "{:<22} {:<13} {:<15} {:<12} {:<8} {}",
        "slug", "kind", "script", "status", "requests", "plugin message"
    )];

    for (slug, path) in entries {
        let files = unzip(get(&format!("{base}{path}")));
        let text_of = |name: &str| {
            files
                .iter()
                .find(|(n, _)| n == name)
                .map(|(_, d)| String::from_utf8(d.clone()).expect("not UTF-8"))
        };
        let manifest_text = text_of("plugin.json")
            .unwrap_or_else(|| panic!("{slug}: plugin.json missing in the zip"));
        let manifest = manifest(&manifest_text);
        let sources: Vec<SourceFile> = files
            .iter()
            .filter_map(|(name, data)| {
                let short = name.strip_prefix("src/")?;
                (short.ends_with(".js") && !short.contains('/')).then(|| SourceFile {
                    name: short.to_owned(),
                    code: String::from_utf8(data.clone()).expect("script is not UTF-8"),
                })
            })
            .collect();
        let install_id = format!("compat-{slug}");

        for source in &sources {
            if let Some(problem) = common::runtime().check_script(&source.name, &source.code) {
                failures.push(format!(
                    "{slug}/{}: check_script: {} (line {})",
                    source.name, problem.message, problem.line
                ));
            }
        }

        for (key, entry) in &manifest.scripts {
            let Some(input) = input_for(&manifest.kind, key) else {
                table.push(format!(
                    "{slug:<22} {:<13} {entry:<15} {:<12} -",
                    manifest.kind, "check only"
                ));
                continue;
            };
            if !sources.iter().any(|s| &s.name == entry) {
                failures.push(format!(
                    "{slug}/{entry}: listed in plugin.json, not in src/"
                ));
                continue;
            }
            let host = FakeHost::answering(|_| ok_response(200, b"{}"));
            let job = common::rt::begin_job();
            let mut request = request_with(job, sources.clone(), input, 15_000);
            request.entry = entry.clone();
            request.install_id = install_id.clone();
            let dyn_host: Arc<dyn PluginHost> = host.clone();
            let result = common::block_on(common::runtime().run(request, dyn_host));

            let requests = host.requests();
            table.push(format!(
                "{slug:<22} {:<13} {entry:<15} {:<12} {:<8} {}",
                manifest.kind,
                format!("{:?}", result.status),
                requests.len(),
                result.error_message.chars().take(70).collect::<String>()
            ));
            let at = format!("{slug}/{entry}");
            if matches!(
                result.status,
                ScriptStatus::Internal
                    | ScriptStatus::Stack
                    | ScriptStatus::Memory
                    | ScriptStatus::Timeout
            ) {
                failures.push(format!(
                    "{at}: status {:?}: {} {:?}",
                    result.status, result.error_message, result.js_error
                ));
            }
            if let Some(global) = missing_global(&result) {
                failures.push(format!(
                    "{at}: host global `{global}` missing: {:?}",
                    result.js_error
                ));
            }
            if requests.iter().any(|r| r.install_id != install_id) {
                failures.push(format!("{at}: a request has the wrong install_id"));
            }
            // No stream-call assertion: these runs are plain (not streaming), so
            // the host never receives a stream call and a check could not fail.
        }
    }

    println!("{}", table.join("\n"));
    assert!(
        failures.is_empty(),
        "compat failures:\n{}",
        failures.join("\n")
    );
}
