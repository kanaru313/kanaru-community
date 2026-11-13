//! The global `Response` object (`success`, `error`) and the brand check the
//! host uses to tell a real `Response` from a forged object.

use rquickjs::{Ctx, Exception, Function, Object};

use super::eval_classic;

/// Defines the global `Response` (frozen, not writable) and returns the brand
/// check (`isResponse`: true only for objects `Response.success` /
/// `Response.error` made) and `lengthOf` (UTF-16 length of a string).
/// The helpers capture the built-ins they use when the prelude runs, and call
/// them through bound functions (`call.bind(fn)`), so a script that replaces
/// `Object.freeze`, `WeakSet.prototype`, `Function.prototype.call`/`bind` or
/// `Reflect.apply` afterwards cannot forge or break a response.
const PRELUDE: &str = r#"
(function () {
  'use strict';
  var freeze = Object.freeze;
  var made = new WeakSet();
  var call = Function.prototype.call;
  var add = call.bind(WeakSet.prototype.add);
  var has = call.bind(WeakSet.prototype.has);
  var isFinite_ = isFinite, floor = Math.floor, min = Math.min, Str = String;
  function brand(o) { freeze(o); add(made, o); return o; }
  var Response = freeze({
    success: function success(data) { return brand({ ok: true, data: data }); },
    error: function error(message, options) {
      var kind = 'server', retry = null;
      if (options !== null && typeof options === 'object') {
        var k = options.kind;
        if (k === 'rateLimited' || k === 'invalidResponse' || k === 'server' ||
            k === 'auth' || k === 'quota') kind = k;
        var r = options.retryAfterSec;
        if (typeof r === 'number' && isFinite_(r) && r >= 0) retry = min(floor(r), 4294967295);
      }
      return brand({ ok: false, message: Str(message), kind: kind, retryAfterSec: retry });
    }
  });
  Object.defineProperty(globalThis, 'Response',
    { value: Response, writable: false, configurable: false, enumerable: false });
  return {
    isResponse: function isResponse(v) { return has(made, v); },
    lengthOf: function lengthOf(s) { return s.length; }
  };
})()
"#;

/// Helper functions the prelude hands to the host.
pub struct Helpers<'js> {
    pub(super) is_response: Function<'js>,
    pub(super) length_of: Function<'js>,
}

/// Runs the prelude and returns its helpers.
pub(super) fn install<'js>(ctx: &Ctx<'js>) -> rquickjs::Result<Helpers<'js>> {
    let helpers: Object = eval_classic(ctx, PRELUDE, "<runtime>")?
        .into_object()
        .ok_or_else(|| Exception::throw_message(ctx, "prelude did not return an object"))?;
    Ok(Helpers {
        is_response: helpers.get("isResponse")?,
        length_of: helpers.get("lengthOf")?,
    })
}
