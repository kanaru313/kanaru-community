//! Plugins cannot compile code at run time: `eval`, `Function` and the four
//! function constructors are gone, while `load()` and the host API still work.

#![allow(clippy::unwrap_used)]

mod common;

use common::run_script;
use kanaru_plugin_runtime::ScriptStatus as S;

/// The exact text of the `TypeError` every `.constructor` route throws.
const CONSTRUCTOR_ERROR: &str =
    "Kanaru plugins cannot compile code at run time (eval / Function are disabled)";

fn run_expr(expr: &str) -> kanaru_plugin_runtime::ScriptResult {
    run_script(
        &format!("function execute() {{ return Response.success({expr}); }}"),
        0,
    )
}

/// `expr` reaches a function constructor: it must throw the documented text.
fn assert_constructor_blocked(expr: &str) {
    let r = run_expr(expr);
    assert_eq!(r.status, S::ScriptError, "{expr}: {r:?}");
    assert_eq!(r.error_message, CONSTRUCTOR_ERROR, "{expr}: {r:?}");
}

/// `expr` uses the deleted global: a `ReferenceError` naming it.
fn assert_global_gone(expr: &str, name: &str) {
    let r = run_expr(expr);
    assert_eq!(r.status, S::ScriptError, "{expr}: {r:?}");
    let js = r.js_error.as_ref().unwrap();
    assert!(js.message.contains(name), "{expr}: {r:?}");
}

#[test]
fn eval_calls_are_blocked() {
    let _t = common::test();
    assert_global_gone("eval('1')", "eval");
    assert_global_gone("(0, eval)('1')", "eval");
}

#[test]
fn eval_looked_up_by_computed_name_is_not_callable() {
    let _t = common::test();
    let r = run_expr("globalThis['ev' + 'al']('1')");
    assert_eq!(r.status, S::ScriptError, "{r:?}");
}

#[test]
fn function_constructors_are_blocked() {
    let _t = common::test();
    assert_global_gone("Function('return 1')()", "Function");
    assert_global_gone("new Function('return 1')()", "Function");
    for expr in [
        "(function () {}).constructor('return 1')",
        "(async function () {}).constructor('return 1')",
        "(function* () {}).constructor('return 1')",
        "(async function* () {}).constructor('return 1')",
        "Reflect.construct(Object.getPrototypeOf(function () {}).constructor, ['return 1'])",
        "(() => 1).constructor('return 1')",
        "(async () => 1).constructor('return 1')",
        "({ *g() {} }).g.constructor('return 1')",
        "(function () {}).bind(null).constructor('return 1')",
        "(async function () {}).bind(null).constructor('return 1')",
        "(class {}).constructor('return 1')",
        "new Proxy(function () {}, {}).constructor('return 1')",
        "(function () {}).__proto__.constructor('return 1')",
        "Object.create(Object.getPrototypeOf(function () {})).constructor('return 1')",
        "Object.getOwnPropertyDescriptor(Object.getPrototypeOf(function () {}), 'constructor').get.constructor('return 1')",
        "(function () { delete Object.getPrototypeOf(function () {}).constructor; return (function () {}).constructor('return 1'); })()",
        "(function () { try { Object.defineProperty(Object.getPrototypeOf(function () {}), 'constructor', { value: 1 }); } catch (e) {} return (function () {}).constructor('return 1'); })()",
    ] {
        assert_constructor_blocked(expr);
    }
}

#[test]
fn eval_and_function_globals_are_gone() {
    let _t = common::test();
    let r = run_script(
        "function execute() {
           return Response.success([typeof eval, typeof Function,
             Object.prototype.hasOwnProperty.call(globalThis, 'eval'),
             Object.prototype.hasOwnProperty.call(globalThis, 'Function')]);
         }",
        0,
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(r.output_json, r#"["undefined","undefined",false,false]"#);
}

#[test]
fn constructor_cannot_be_restored_or_overwritten() {
    let _t = common::test();
    let r = run_script(
        "function execute() {
           var out = [];
           var protos = [Object.getPrototypeOf(function () {}), Object.getPrototypeOf(async function () {}),
             Object.getPrototypeOf(function* () {}), Object.getPrototypeOf(async function* () {})];
           for (var i = 0; i < protos.length; i++) {
             var d = Object.getOwnPropertyDescriptor(protos[i], 'constructor');
             var redefined = true;
             try { Object.defineProperty(protos[i], 'constructor', { value: 1 }); }
             catch (e) { redefined = false; }
             out.push([d.configurable, d.set === undefined, redefined]);
           }
           return Response.success(out);
         }",
        0,
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
    let one = "[false,true,false]";
    assert_eq!(r.output_json, format!("[{one},{one},{one},{one}]"));
}

#[test]
fn error_is_a_type_error_with_the_documented_text() {
    let _t = common::test();
    let r = run_script(
        "function execute() {
           try { (function () {}).constructor('1'); } catch (e) {
             return Response.success([e instanceof TypeError, e.message]);
           }
         }",
        0,
    );
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(
        r.output_json,
        r#"[true,"Kanaru plugins cannot compile code at run time (eval / Function are disabled)"]"#
    );
}

#[test]
fn load_and_host_api_still_work() {
    let _t = common::test();
    let job = common::rt::begin_job();
    let r = common::block_on(common::rt::run(common::request_with(
        job,
        vec![
            common::file(
                "search.js",
                "function execute() {
                   load('crypto.js'); load('helper.js');
                   return Response.success([CryptoJS.MD5('a').toString(), helper(),
                     typeof fetch, typeof Html.parse, typeof Response.success]);
                 }",
            ),
            common::file("helper.js", "function helper() { return 'h'; }"),
        ],
        "{}",
        0,
    )));
    assert_eq!(r.status, S::Ok, "{r:?}");
    assert_eq!(
        r.output_json,
        r#"["0cc175b9c0f1b6a831c399e269772661","h","function","function","function"]"#
    );
}

#[test]
fn overwriting_type_error_does_not_change_what_the_constructor_throws() {
    let _t = common::test();
    for replacement in ["function () { return {}; }", "null"] {
        let r = run_script(
            &format!(
                "TypeError = {replacement};
                 function execute() {{ return Response.success((function () {{}}).constructor('return 1')); }}"
            ),
            0,
        );
        assert_eq!(r.status, S::ScriptError, "{replacement}: {r:?}");
        assert_eq!(r.error_message, CONSTRUCTOR_ERROR, "{replacement}: {r:?}");
    }
}

#[test]
fn plain_read_of_constructor_throws_without_a_call() {
    let _t = common::test();
    let r = run_script(
        "function execute() { var c = (function () {}).constructor; return Response.success(1); }",
        0,
    );
    assert_eq!(r.status, S::ScriptError, "{r:?}");
    assert_eq!(r.error_message, CONSTRUCTOR_ERROR, "{r:?}");
}
