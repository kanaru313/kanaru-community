//! Bounded fuzz of `Html`: hostile documents and selectors through the real
//! runtime on its normal worker (8 MiB stack), the path a plugin takes.
//!
//! Every case runs `Html.parse` + `select` + `text` + `outerHtml` in one
//! script and must end with a result or a limit / syntax error (`RangeError`,
//! `SyntaxError`, run status `memory` or `timeout`), never `internal`, a stack
//! failure, a `TypeError` or an abort of the test process.
//!
//! Bounded and repeatable: a fixed seed, 64 cases per generator, no shrinking
//! and no persisted failure files (a failing case is printed whole). These
//! tests are ignored in debug builds; `tool/check_rust` runs them in release
//! mode, the profile the app ships.

// Helpers outside `#[test]` functions may unwrap too.
#![allow(clippy::unwrap_used)]

mod common;

use common::{file, request_with, rt};
use kanaru_plugin_runtime::ScriptStatus as S;
use proptest::prelude::*;
use proptest::test_runner::{Config, RngAlgorithm, TestCaseError, TestRng, TestRunner};

const CASES: u32 = 64;
const SEED: [u8; 32] = [0x4b; 32];
/// Wall time of one case, ms. A case that needs more ends `timeout`, which is
/// a limit, not a failure.
const CASE_TIMEOUT_MS: u32 = 20_000;

/// Page the selector generators run against: enough structure for the
/// combinators to find something.
const PAGE: &str = include_str!("fixtures/html/genius_like_page.html");

/// The script of a case: the document and the selector come in as input.
const SCRIPT: &str = "function execute(input) {
  var names = [], seen = 0;
  try {
    var doc = Html.parse(input.html);
    seen += doc.text().length + doc.outerHtml().length;
    try { seen += doc.select(input.css).size(); } catch (e) { names.push(e.name); }
    try { seen += doc.selectFirst(input.css) ? 1 : 0; } catch (e) { names.push(e.name); }
    try { seen += doc.select(input.css).text().length; } catch (e) { names.push(e.name); }
    try { seen += doc.html().length; } catch (e) { names.push(e.name); }
  } catch (e) { names.push('parse:' + e.name); }
  return Response.success(names);
}";

/// A JSON string literal for `text`.
fn json_string(text: &str) -> String {
    let mut out = String::from("\"");
    for ch in text.chars() {
        match ch {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            c if (c as u32) < 0x20 => out.push_str(&format!("\\u{:04x}", c as u32)),
            c => out.push(c),
        }
    }
    out.push('"');
    out
}

/// Runs one case and checks the outcome.
fn run_case(html: &str, css: &str) -> Result<(), TestCaseError> {
    let input = format!(
        "{{\"html\":{},\"css\":{}}}",
        json_string(html),
        json_string(css)
    );
    let job = rt::begin_job();
    let result = common::block_on(rt::run(request_with(
        job,
        vec![file("search.js", SCRIPT)],
        &input,
        CASE_TIMEOUT_MS,
    )));
    match result.status {
        S::Ok => {
            for name in result.output_json.split('"').skip(1).step_by(2) {
                let name = name.strip_prefix("parse:").unwrap_or(name);
                if name != "RangeError" && name != "SyntaxError" {
                    return Err(TestCaseError::fail(format!(
                        "unexpected error {name}: {result:?}"
                    )));
                }
            }
            Ok(())
        }
        S::Memory | S::Timeout => Ok(()),
        _ => Err(TestCaseError::fail(format!("bad run: {result:?}"))),
    }
}

/// Runs `CASES` generated cases with the fixed seed.
fn fuzz<T: Strategy<Value = (String, String)>>(strategy: T) {
    let _t = common::test();
    let config = Config {
        cases: CASES,
        max_shrink_iters: 0,
        failure_persistence: None,
        ..Config::default()
    };
    let rng = TestRng::from_seed(RngAlgorithm::ChaCha, &SEED);
    let mut runner = TestRunner::new_with_rng(config, rng);
    let started = std::time::Instant::now();
    let outcome = runner.run(&strategy, |(html, css)| run_case(&html, &css));
    eprintln!("{CASES} cases in {:?}", started.elapsed());
    if let Err(e) = outcome {
        panic!("{e}");
    }
}

// --- generators ------------------------------------------------------------

fn selector_pool() -> impl Strategy<Value = String> + Clone {
    prop::sample::select(vec![
        "x span",
        ":has(x)",
        "span:has(x span)",
        "span span span",
        "div > span",
        "[a]",
        "[a*=x i]",
        "*",
        "p:not(.a)",
        "span:nth-child(2n+1)",
    ])
    .prop_map(str::to_owned)
}

fn plain(html: impl Strategy<Value = String>) -> impl Strategy<Value = (String, String)> {
    (
        html,
        prop_oneof![1 => selector_pool(), 3 => valid_selector()],
    )
}

/// Elements nested about half under the depth limit of 512 (`<html>` and
/// `<body>` take two levels) and half well over it. Only tags that nest.
fn deep_nesting() -> impl Strategy<Value = String> {
    (
        prop::sample::select(vec![
            ("<div>", "</div>"),
            ("<span>", "</span>"),
            ("<b>", "</b>"),
            ("<i>", "</i>"),
            ("<section>", "</section>"),
            ("<em>", "</em>"),
            ("<ul><li>", "</li></ul>"),
        ]),
        prop_oneof![100usize..250, 520usize..3000],
        "[a-z ]{0,20}",
    )
        .prop_map(|((open, close), depth, text)| open.repeat(depth) + &text + &close.repeat(depth))
}

/// A few elements with thousands of attributes, sometimes repeated tags.
fn many_attributes() -> impl Strategy<Value = String> {
    (
        1usize..12,
        1usize..3000,
        prop::collection::vec("[a-z]{1,6}", 1..4),
        "[a-z0-9]{0,40}",
    )
        .prop_map(|(elements, attrs, names, value)| {
            let mut out = String::from("<html><body>");
            for e in 0..elements {
                out.push_str("<html ");
                for a in 0..attrs {
                    let name = &names[a % names.len()];
                    out.push_str(&format!("{name}{a}=\"{value}\" "));
                }
                out.push_str(&format!("a=x>t{e}"));
            }
            out
        })
}

fn from_tokens(
    tokens: &'static [&'static str],
    len: std::ops::Range<usize>,
) -> impl Strategy<Value = String> {
    prop::collection::vec(prop::sample::select(tokens.to_vec()), len)
        .prop_map(|parts| parts.concat())
}

/// Misnested and misplaced markup the tree builder has to repair.
fn tag_soup() -> impl Strategy<Value = String> {
    from_tokens(
        &[
            "<b>",
            "</b>",
            "<i id=1>",
            "</i>",
            "<p>",
            "</p>",
            "<table>",
            "</table>",
            "<tr>",
            "<td>",
            "</td>",
            "<svg>",
            "</svg>",
            "<math>",
            "<!--",
            "-->",
            "<a href=x>",
            "</a>",
            "<div>",
            "</div>",
            "<template>",
            "</template>",
            "<select>",
            "<option>",
            "<form>",
            "</form>",
            "<li>",
            "<nobr>",
            "<frameset>",
            "<noscript>",
            "<script>",
            "</script>",
            "<style>",
            "<![CDATA[",
            "x",
            "text ",
            "<span a=b>",
            "</span>",
            "<body>",
            "<html>",
        ],
        1..600,
    )
}

/// Character references, valid and broken.
fn entities() -> impl Strategy<Value = String> {
    from_tokens(
        &[
            "&amp;",
            "&#0;",
            "&#x110000;",
            "&#xD800;",
            "&notit;",
            "&lt",
            "&#65;",
            "&Aacute;",
            "&;",
            "&#",
            "&unknown;",
            "&#x;",
            "&#x80;",
            "text",
            "<p title='&amp;'>",
            "</p>",
            "<textarea>",
            "</textarea>",
            "&&&",
            "&#xFFFFFFFFFF;",
        ],
        1..400,
    )
}

/// Valid selector leaves.
fn valid_leaf() -> impl Strategy<Value = String> {
    prop::sample::select(vec![
        "div",
        "span",
        "b",
        "i",
        "em",
        "section",
        "li",
        "x",
        "*",
        ".a",
        "#b",
        "[x]",
        "[a]",
        "[x^='a' i]",
        "p",
        "a[href]",
        ":root",
        ":empty",
        ":first-child",
    ])
    .prop_map(str::to_owned)
}

/// Selectors the parser accepts: combinators, `:not`, `:has`, `:is`, `:nth-*`.
fn valid_selector() -> impl Strategy<Value = String> {
    valid_leaf().prop_recursive(5, 60, 3, |inner| {
        prop_oneof![
            (inner.clone(), inner.clone()).prop_map(|(a, b)| format!("{a} {b}")),
            (inner.clone(), inner.clone()).prop_map(|(a, b)| format!("{a} > {b}")),
            (inner.clone(), inner.clone()).prop_map(|(a, b)| format!("{a} + {b}")),
            (inner.clone(), inner.clone()).prop_map(|(a, b)| format!("{a} ~ {b}")),
            (inner.clone(), inner.clone()).prop_map(|(a, b)| format!("{a}, {b}")),
            inner.clone().prop_map(|a| format!(":not({a})")),
            inner.clone().prop_map(|a| format!(":has({a})")),
            inner.clone().prop_map(|a| format!(":has(> {a})")),
            inner.clone().prop_map(|a| format!(":is({a}, p)")),
            inner.clone().prop_map(|a| format!("{a}:nth-child(2n+1)")),
            inner
                .clone()
                .prop_map(|a| format!("{a}:nth-last-of-type(odd)")),
            inner.prop_map(|a| format!("{a}:nth-child(3)")),
        ]
    })
}

/// Mostly valid selectors, some broken ones, some long enough to pass the
/// 1024 byte limit.
fn selectors() -> impl Strategy<Value = String> {
    let broken = prop::sample::select(vec![
        "(",
        "[[",
        "::before",
        ":hover",
        ":checked",
        "",
        ":has(:has(x))",
    ])
    .prop_map(str::to_owned);
    let one = prop_oneof![
        18 => valid_selector(),
        1 => (valid_selector(), broken).prop_map(|(a, b)| format!("{a} {b}")),
    ];
    (one, 0usize..40).prop_map(|(s, repeat)| {
        if repeat > 36 {
            vec![s; repeat * 8].join(",")
        } else {
            s
        }
    })
}

// --- tests -----------------------------------------------------------------

#[test]
#[cfg_attr(debug_assertions, ignore = "release only, see tool/check_rust")]
fn deep_nesting_beyond_the_depth_limit() {
    fuzz(plain(deep_nesting()));
}

#[test]
#[cfg_attr(debug_assertions, ignore = "release only, see tool/check_rust")]
fn many_attributes_on_repeated_tags() {
    fuzz(plain(many_attributes()));
}

#[test]
#[cfg_attr(debug_assertions, ignore = "release only, see tool/check_rust")]
fn tag_soup_documents() {
    fuzz(plain(tag_soup()));
}

#[test]
#[cfg_attr(debug_assertions, ignore = "release only, see tool/check_rust")]
fn entities_valid_and_broken() {
    fuzz(plain(entities()));
}

#[test]
#[cfg_attr(debug_assertions, ignore = "release only, see tool/check_rust")]
fn long_and_nested_selectors() {
    fuzz((Just(PAGE.to_owned()), selectors()));
}

#[test]
#[cfg_attr(debug_assertions, ignore = "release only, see tool/check_rust")]
fn mixed_documents_and_selectors() {
    let doc = prop_oneof![deep_nesting(), many_attributes(), tag_soup(), entities()];
    fuzz((doc, selectors()));
}
