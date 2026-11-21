import 'json_read.dart';

/// Most chunk and language limits a translate plugin may declare. The floors
/// stop a plugin from splitting one song into hundreds of billed runs.
const translateMaxLinesRange = (min: 10, max: 200);
const translateMaxCharsRange = (min: 1000, max: 20000);

/// The longest a translate run may take, whatever the plugin declares.
const translateTimeoutCapSec = 90;
const translateDefaultMaxLines = 50;
const translateDefaultMaxChars = 4000;
const translateDefaultTimeoutSec = 15;

const _maxLanguageEntries = 200;

/// Target languages a translate plugin may declare: ISO 639-1 codes plus
/// `zh-Hans` and `zh-Hant`. Others are dropped, not refused.
const translationLanguageCodes = {
  'vi', 'en', 'ja', 'ko', 'zh-Hans', 'zh-Hant', 'fr', 'de', 'es', 'it', //
  'ru', 'pt', 'th', 'id', 'hi', 'ar', 'nl', 'sv', 'pl', 'tr', 'uk', 'cs',
  'el', 'fa', 'ro', 'ms', 'he', 'fi', 'da', 'no', 'hu', 'cy', 'sk', 'sq',
  'hy', 'eu', 'my', 'ka', 'is', 'mk', 'mi',
};

/// The `translate` block of a translate plugin's `plugin.json`: the target
/// languages it supports and how much one run may carry.
class TranslateSpec {
  const TranslateSpec({
    required this.languages,
    this.maxLines = translateDefaultMaxLines,
    this.maxChars = translateDefaultMaxChars,
    this.timeoutSec = translateDefaultTimeoutSec,
  });

  /// Codes of [translationLanguageCodes] the plugin translates into.
  final List<String> languages;

  /// Most lines in one run.
  final int maxLines;

  /// Most characters of lyrics in one run.
  final int maxChars;

  /// Wall time of one run, already clamped to [translateTimeoutCapSec].
  final int timeoutSec;
}

/// Parses the `translate` block. Unknown or repeated language codes are
/// dropped (their number is returned in `droppedLanguages`); `timeoutSec`
/// above the host cap is clamped, not refused. Stops with `InvalidManifest`
/// naming `translate.<field>`.
({TranslateSpec spec, int droppedLanguages}) readTranslateSpec(Object? value) {
  final block = asObject(value);
  if (block == null) invalid('translate');
  final raw = block['languages'];
  if (raw is! List || raw.isEmpty || raw.length > _maxLanguageEntries) {
    invalid('translate.languages');
  }
  final languages = <String>[];
  var dropped = 0;
  for (final item in raw) {
    if (item is! String) invalid('translate.languages');
    if (!translationLanguageCodes.contains(item) || languages.contains(item)) {
      dropped++;
    } else {
      languages.add(item);
    }
  }
  if (languages.isEmpty) invalid('translate.languages');
  final timeout = _int(
    block['timeoutSec'],
    'timeoutSec',
    1,
    600,
    translateDefaultTimeoutSec,
  );
  return (
    spec: TranslateSpec(
      languages: List.unmodifiable(languages),
      maxLines: _int(
        block['maxLines'],
        'maxLines',
        translateMaxLinesRange.min,
        translateMaxLinesRange.max,
        translateDefaultMaxLines,
      ),
      maxChars: _int(
        block['maxChars'],
        'maxChars',
        translateMaxCharsRange.min,
        translateMaxCharsRange.max,
        translateDefaultMaxChars,
      ),
      timeoutSec: timeout > translateTimeoutCapSec
          ? translateTimeoutCapSec
          : timeout,
    ),
    droppedLanguages: dropped,
  );
}

int _int(Object? value, String field, int min, int max, int fallback) {
  if (value == null) return fallback;
  if (value is! int || value < min || value > max) invalid('translate.$field');
  return value;
}
