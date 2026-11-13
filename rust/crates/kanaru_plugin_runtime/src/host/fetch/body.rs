//! Response bodies kept in Rust until the script reads them as text or base64.
//! Each body is charged to the job's byte budget and released when read.

use std::cell::RefCell;
use std::rc::Rc;

use rquickjs::{Ctx, Exception, Function, Object};

use super::options::type_error;
use super::FetchState;
use crate::charset;
use crate::host::HostEnv;

/// A response body kept for `text()` / `json()` / `base64()`.
pub struct Body {
    pub bytes: Vec<u8>,
    pub content_type: Option<String>,
}

/// Takes the unread body `id` out of the state (and the budget) after `decode`
/// succeeded on it. A body can be read once; the prelude caches the result.
fn read_body<'js, T>(
    ctx: &Ctx<'js>,
    env: &HostEnv,
    state: &RefCell<FetchState>,
    id: u32,
    decode: impl FnOnce(&Body) -> Result<T, &'static str>,
) -> rquickjs::Result<T> {
    let mut st = state.borrow_mut();
    let Some(body) = st.bodies.get(&id) else {
        return Err(type_error(ctx, "the body was already read"));
    };
    let value = match decode(body) {
        Ok(v) => v,
        Err(message) => return Err(Exception::throw_range(ctx, message)),
    };
    if let Some(body) = st.bodies.remove(&id) {
        env.budget.release(body.bytes.len());
    }
    Ok(value)
}

/// Standard base64 with padding.
fn base64(bytes: &[u8]) -> String {
    const ALPHABET: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    let mut out = String::with_capacity(bytes.len().div_ceil(3) * 4);
    for chunk in bytes.chunks(3) {
        let n = (u32::from(chunk[0]) << 16)
            | (u32::from(*chunk.get(1).unwrap_or(&0)) << 8)
            | u32::from(*chunk.get(2).unwrap_or(&0));
        out.push(ALPHABET[(n >> 18) as usize & 63] as char);
        out.push(ALPHABET[(n >> 12) as usize & 63] as char);
        out.push(if chunk.len() > 1 {
            ALPHABET[(n >> 6) as usize & 63] as char
        } else {
            '='
        });
        out.push(if chunk.len() > 2 {
            ALPHABET[n as usize & 63] as char
        } else {
            '='
        });
    }
    out
}

/// Native `bodyText` and `bodyBase64`.
pub fn register<'js>(
    ctx: &Ctx<'js>,
    natives: &Object<'js>,
    env: &Rc<HostEnv>,
    state: &Rc<RefCell<FetchState>>,
) -> rquickjs::Result<()> {
    let (s, e) = (state.clone(), env.clone());
    natives.set(
        "bodyText",
        Function::new(ctx.clone(), move |ctx: Ctx<'js>, id: u32, label: String| {
            read_body(&ctx, &e, &s, id, |body| {
                let explicit = (!label.is_empty()).then_some(label.as_str());
                charset::decode(&body.bytes, explicit, body.content_type.as_deref())
                    .ok_or("text: unknown charset")
            })
        })?,
    )?;
    let (s, e) = (state.clone(), env.clone());
    natives.set(
        "bodyBase64",
        Function::new(ctx.clone(), move |ctx: Ctx<'js>, id: u32| {
            read_body(&ctx, &e, &s, id, |body| Ok(base64(&body.bytes)))
        })?,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn base64_matches_the_standard_vectors() {
        for (input, want) in [
            ("", ""),
            ("f", "Zg=="),
            ("fo", "Zm8="),
            ("foo", "Zm9v"),
            ("foob", "Zm9vYg=="),
        ] {
            assert_eq!(base64(input.as_bytes()), want);
        }
    }
}
