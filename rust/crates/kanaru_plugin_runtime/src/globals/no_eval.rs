//! Removes every way for plugin JS to compile code at run time.
//!
//! Invariant: the only code a plugin runs is its own package files (the entry
//! and what it `load()`s). `load()` and the entry run through Rust
//! ([`super::eval_classic`]), which this module does not touch. Without
//! `eval` and the function constructors a plugin cannot fetch JS and run it,
//! which a static review of the package relies on.
//!
//! The four function prototypes (plain, async, generator, async generator)
//! reach the `Function` constructors through `.constructor`. Each gets a
//! non-configurable accessor that throws. The prototype objects stay (the
//! prelude captured `Function.prototype.call`). Then the globals `eval` and
//! `Function` are deleted; a failed deletion fails the setup.

use rquickjs::Ctx;

use super::eval_classic;

/// Message of the `TypeError` a plugin gets from any compile attempt.
pub const ERROR_MESSAGE: &str =
    "Kanaru plugins cannot compile code at run time (eval / Function are disabled)";

const STRIP: &str = r#"
(function () {
  var TE = TypeError;
  var thrower = function () { throw new TE("__MSG__"); };
  var protos = [
    Function.prototype,
    Object.getPrototypeOf(async function () {}),
    Object.getPrototypeOf(function* () {}),
    Object.getPrototypeOf(async function* () {})
  ];
  for (var i = 0; i < protos.length; i++) {
    Object.defineProperty(protos[i], "constructor", {
      get: thrower, set: undefined, enumerable: false, configurable: false
    });
  }
  var names = ["eval", "Function"];
  for (var j = 0; j < names.length; j++) {
    delete globalThis[names[j]];
    if (Object.prototype.hasOwnProperty.call(globalThis, names[j])) {
      throw new Error("could not remove global " + names[j]);
    }
  }
})();
"#;

/// Strips run-time compilation from the context. Call after the other globals
/// are installed and before the entry script runs.
pub fn install(ctx: &Ctx<'_>) -> rquickjs::Result<()> {
    let code = STRIP.replace("__MSG__", ERROR_MESSAGE);
    eval_classic(ctx, &code, "<no-eval>").map(|_| ())
}
