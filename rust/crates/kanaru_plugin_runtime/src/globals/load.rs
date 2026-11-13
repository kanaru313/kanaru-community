//! `load(name)`: evaluates another file of the package (or the bundled
//! CryptoJS) in the same global scope, once.

use std::cell::RefCell;
use std::collections::HashSet;
use std::rc::Rc;

use rquickjs::{Ctx, Exception, Function};

use super::{eval_classic, Sources};

/// True for `name.js` made of letters, digits, `_`, `.` and `-` only (no folders).
pub fn is_loadable_name(name: &str) -> bool {
    name.len() > ".js".len()
        && name.ends_with(".js")
        && name
            .bytes()
            .all(|b| b.is_ascii_alphanumeric() || matches!(b, b'_' | b'.' | b'-'))
}

/// The bundled CryptoJS 4.2.0 build (MIT; notice and checksum in its header).
/// `load('crypto.js')` evaluates it; it defines the global `CryptoJS`.
const CRYPTO_JS: &str = include_str!("../js/crypto-js.min.js");

/// Defines the global `load`. `entry` counts as already loaded.
pub(super) fn install<'js>(ctx: &Ctx<'js>, sources: Sources, entry: &str) -> rquickjs::Result<()> {
    let loaded: Rc<RefCell<HashSet<String>>> =
        Rc::new(RefCell::new(HashSet::from([entry.to_owned()])));
    let load = Function::new(
        ctx.clone(),
        move |ctx: Ctx<'_>, name: String| -> rquickjs::Result<()> {
            if !is_loadable_name(&name) {
                return Err(Exception::throw_message(
                    &ctx,
                    "load: the name must be a file name like util.js (letters, digits, _ . - only)",
                ));
            }
            // The bundled file wins over a package file of the same name.
            let code = if name == "crypto.js" {
                CRYPTO_JS
            } else {
                match sources.get(&name) {
                    Some(code) => code.as_str(),
                    None => {
                        return Err(Exception::throw_message(
                            &ctx,
                            &format!("load: no file named {name} in src/"),
                        ))
                    }
                }
            };
            if !loaded.borrow_mut().insert(name.clone()) {
                return Ok(());
            }
            eval_classic(&ctx, code, &name).map(|_| ())
        },
    )?;
    ctx.globals().set("load", load)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn loadable_names() {
        for ok in ["a.js", "util-2.js", "A_b.c.js", "..js"] {
            assert!(is_loadable_name(ok), "{ok}");
        }
        for bad in [
            "", ".js", "a", "a.json", "../x.js", "a/b.js", "a b.js", "a\\b.js", "é.js", "a.js\0",
        ] {
            assert!(!is_loadable_name(bad), "{bad:?}");
        }
    }
}
