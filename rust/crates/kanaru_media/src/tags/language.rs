//! Title language detection (whatlang), only when the file has no language tag.

use whatlang::Lang;

/// whatlang codes that are individual languages inside a macrolanguage which
/// the Dart `languageKey` table maps its ISO 639-1 tag to (`zh` to `zho`,
/// `fa` to `fas`, `ar` to `ara`; `arb` is a guard that whatlang 0.18 does not
/// emit, it says `ara`). Every other whatlang code is already the
/// code `languageKey` produces for its 639-1 tag.
const MACROLANGUAGES: [(&str, &str); 3] = [("cmn", "zho"), ("pes", "fas"), ("arb", "ara")];

/// ISO 639-3 code for a detected language, macrolanguage-mapped.
pub fn language_code(lang: Lang) -> &'static str {
    let code = lang.code();
    MACROLANGUAGES
        .iter()
        .find(|(from, _)| *from == code)
        .map_or(code, |(_, to)| to)
}

/// The language of `title` as an ISO 639-3 code, only when whatlang calls the
/// detection reliable. Short or mixed titles often are not: `None` then.
pub fn detect_title_language(title: &str) -> Option<String> {
    let info = whatlang::detect(title)?;
    info.is_reliable()
        .then(|| language_code(info.lang()).to_owned())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_common_languages() {
        assert_eq!(
            detect_title_language("Những ngày tháng cũ còn mãi trong tim tôi").as_deref(),
            Some("vie")
        );
        assert_eq!(
            detect_title_language(
                "I will always love you, no matter what the world is going to say about it"
            )
            .as_deref(),
            Some("eng")
        );
        assert_eq!(
            detect_title_language("夜に駆ける 君と見た景色を忘れない").as_deref(),
            Some("jpn")
        );
    }

    #[test]
    fn short_or_empty_titles_are_unknown() {
        assert_eq!(detect_title_language("Hi"), None);
        assert_eq!(detect_title_language(""), None);
        assert_eq!(detect_title_language("123 456"), None);
    }

    #[test]
    fn every_code_is_three_lowercase_letters() {
        for lang in Lang::all() {
            let code = language_code(*lang);
            assert_eq!(code.len(), 3, "{lang:?}");
            assert!(code.bytes().all(|b| b.is_ascii_lowercase()), "{code}");
        }
    }

    #[test]
    fn macrolanguages_are_mapped() {
        assert_eq!(language_code(Lang::Cmn), "zho");
        assert_eq!(language_code(Lang::Pes), "fas");
        assert_eq!(language_code(Lang::Vie), "vie");
    }

    /// Checks `tests/tags_fixtures/whatlang_codes.json` (code, mapped code),
    /// which the Dart test compares with `languageCodeTable`. A stale file
    /// fails with the expected content; `UPDATE_FIXTURES=1 cargo test` rewrites
    /// it.
    #[test]
    fn code_table_fixture_is_current() {
        let mut pairs: Vec<(&str, &str)> = Lang::all()
            .iter()
            .map(|l| (l.code(), language_code(*l)))
            .collect();
        pairs.sort_unstable();
        let body: Vec<String> = pairs
            .iter()
            .map(|(from, to)| format!("  \"{from}\": \"{to}\""))
            .collect();
        let expected = format!("{{\n{}\n}}\n", body.join(",\n"));
        let path = std::path::Path::new(env!("CARGO_MANIFEST_DIR"))
            .join("tests/tags_fixtures/whatlang_codes.json");
        if std::env::var_os("UPDATE_FIXTURES").is_some() {
            std::fs::write(&path, &expected).expect("write whatlang_codes.json");
            return;
        }
        let current = std::fs::read_to_string(&path).unwrap_or_default();
        assert_eq!(
            current, expected,
            "whatlang_codes.json is stale: run UPDATE_FIXTURES=1 cargo test and commit it"
        );
    }
}
