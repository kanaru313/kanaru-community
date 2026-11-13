//! The options object of `fetch(url, options)`: method, headers, queries,
//! body and timeout, checked on the way in. Anything wrong is a named
//! `TypeError` that echoes nothing the script passed.

use rquickjs::{Coerced, Ctx, Exception, FromJs, Object, Value};

/// What a script passed in the options object.
pub struct Parsed {
    pub method: &'static str,
    pub headers: Vec<(String, String)>,
    pub body: Vec<u8>,
    pub queries: Vec<(String, String)>,
    pub timeout_ms: Option<f64>,
    /// `stream: true`; honoured in streaming runs only.
    pub stream: bool,
}

pub fn type_error<'js>(ctx: &Ctx<'js>, message: &str) -> rquickjs::Error {
    Exception::throw_type(ctx, message)
}

/// Text of a string-ish value; `None` for `undefined` and `null`.
fn coerce<'js>(ctx: &Ctx<'js>, v: Value<'js>) -> rquickjs::Result<Option<String>> {
    if v.is_undefined() || v.is_null() {
        return Ok(None);
    }
    match Coerced::<String>::from_js(ctx, v) {
        Ok(c) => Ok(Some(c.0)),
        Err(e) => Err(string_error(ctx, e)),
    }
}

/// A script's own exception passes through; a failed string conversion (a
/// lone surrogate) becomes a named `TypeError` that echoes nothing.
fn string_error<'js>(ctx: &Ctx<'js>, e: rquickjs::Error) -> rquickjs::Error {
    match e {
        rquickjs::Error::Exception => e,
        _ => type_error(
            ctx,
            "fetch: strings must be well-formed Unicode (no lone surrogates)",
        ),
    }
}

fn string_pairs<'js>(ctx: &Ctx<'js>, v: Value<'js>) -> rquickjs::Result<Vec<(String, String)>> {
    if v.is_undefined() || v.is_null() {
        return Ok(Vec::new());
    }
    let Some(object) = v.into_object() else {
        return Err(type_error(
            ctx,
            "fetch: headers and queries must be objects",
        ));
    };
    let mut out = Vec::new();
    for prop in object.props::<String, Value>() {
        let (key, value) = prop.map_err(|e| string_error(ctx, e))?;
        if let Some(text) = coerce(ctx, value)? {
            out.push((key, text));
        }
    }
    Ok(out)
}

pub fn parse_options<'js>(
    ctx: &Ctx<'js>,
    options: Option<Object<'js>>,
) -> rquickjs::Result<Parsed> {
    let mut parsed = Parsed {
        method: "GET",
        headers: Vec::new(),
        body: Vec::new(),
        queries: Vec::new(),
        timeout_ms: None,
        stream: false,
    };
    let Some(options) = options else {
        return Ok(parsed);
    };
    if let Some(method) = coerce(ctx, options.get("method")?)? {
        parsed.method = match method.to_ascii_uppercase().as_str() {
            "GET" => "GET",
            "POST" => "POST",
            _ => return Err(type_error(ctx, "fetch: method must be GET or POST")),
        };
    }
    parsed.headers = string_pairs(ctx, options.get("headers")?)?;
    parsed.queries = string_pairs(ctx, options.get("queries")?)?;
    let timeout: Value = options.get("timeout")?;
    parsed.timeout_ms = timeout.as_number();
    parsed.stream = options.get::<_, Value>("stream")?.as_bool() == Some(true);

    let body: Value = options.get("body")?;
    if body.is_undefined() || body.is_null() {
        // no body
    } else if let Some(text) = body.as_string() {
        parsed.body = text
            .to_string()
            .map_err(|e| string_error(ctx, e))?
            .into_bytes();
    } else if body.is_object() {
        if let Some(json) = ctx.json_stringify(body)? {
            parsed.body = json
                .to_string()
                .map_err(|e| string_error(ctx, e))?
                .into_bytes();
        }
        let has_type = parsed
            .headers
            .iter()
            .any(|(k, _)| k.eq_ignore_ascii_case("content-type"));
        if !has_type {
            parsed
                .headers
                .push(("content-type".to_owned(), "application/json".to_owned()));
        }
    } else {
        return Err(type_error(ctx, "fetch: body must be a string or an object"));
    }
    Ok(parsed)
}

/// Percent-encodes everything but unreserved characters.
fn percent_encode(s: &str, out: &mut String) {
    for b in s.bytes() {
        if b.is_ascii_alphanumeric() || matches!(b, b'-' | b'.' | b'_' | b'~') {
            out.push(b as char);
        } else {
            out.push_str(&format!("%{b:02X}"));
        }
    }
}

/// `url` with `queries` appended (before a `#fragment`, after existing queries).
pub fn with_queries(url: &str, queries: &[(String, String)]) -> String {
    if queries.is_empty() {
        return url.to_owned();
    }
    let (base, fragment) = match url.split_once('#') {
        Some((b, f)) => (b, Some(f)),
        None => (url, None),
    };
    let mut out = base.to_owned();
    let mut separator = if base.contains('?') {
        if base.ends_with('?') || base.ends_with('&') {
            ""
        } else {
            "&"
        }
    } else {
        "?"
    };
    for (k, v) in queries {
        out.push_str(separator);
        percent_encode(k, &mut out);
        out.push('=');
        percent_encode(v, &mut out);
        separator = "&";
    }
    if let Some(f) = fragment {
        out.push('#');
        out.push_str(f);
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    fn q(pairs: &[(&str, &str)]) -> Vec<(String, String)> {
        pairs
            .iter()
            .map(|(k, v)| (k.to_string(), v.to_string()))
            .collect()
    }

    #[test]
    fn queries_are_percent_encoded_and_appended_correctly() {
        assert_eq!(with_queries("https://a.test/x", &[]), "https://a.test/x");
        assert_eq!(
            with_queries("https://a.test/x", &q(&[("q", "a b&c=d/é"), ("n", "1")])),
            "https://a.test/x?q=a%20b%26c%3Dd%2F%C3%A9&n=1"
        );
        assert_eq!(
            with_queries("https://a.test/x?k=v#frag", &q(&[("q", "~-._")])),
            "https://a.test/x?k=v&q=~-._#frag"
        );
        assert_eq!(
            with_queries("https://a.test/x?", &q(&[("a", "b")])),
            "https://a.test/x?a=b"
        );
    }
}
