/// Languages written right to left; the translated line is laid out RTL.
const rtlLanguages = {'ar', 'he', 'fa'};

/// [code] lower-cased and cut at the first `-` or `_`: `zh_TW` is `zh`.
/// Legacy `iw` is `he`; `nb` and `nn` are `no`.
String baseLanguage(String code) {
  final lower = code.toLowerCase();
  final cut = lower.indexOf(RegExp('[-_]'));
  final base = cut < 0 ? lower : lower.substring(0, cut);
  return switch (base) {
    'iw' => 'he',
    'nb' || 'nn' => 'no',
    _ => base,
  };
}

/// Whether [a] and [b] are the same language for translation: case and
/// region are ignored, and `zh-Hans` equals `zh-Hant`.
bool sameLanguage(String a, String b) => baseLanguage(a) == baseLanguage(b);

/// The base code covering most characters of the source texts, where
/// [detected] maps a source line to the language the plugin saw (`null` when
/// unknown). `null` when nothing was detected. A tie goes to the language
/// seen first.
String? dominantSource(Map<String, String?> detected) {
  final weights = <String, int>{};
  detected.forEach((source, code) {
    if (code == null || code.isEmpty) return;
    final base = baseLanguage(code);
    weights[base] = (weights[base] ?? 0) + source.length;
  });
  String? best;
  var bestWeight = -1;
  weights.forEach((code, weight) {
    if (weight > bestWeight) {
      best = code;
      bestWeight = weight;
    }
  });
  return best;
}

/// The default translation target for an app locale: `vi` and `en` map to
/// themselves, any other app language to `en`.
String appTarget(String localeCode) {
  final base = baseLanguage(localeCode);
  return base == 'vi' ? 'vi' : 'en';
}

/// The language a track is translated into: the song's own choice
/// ([trackPref]), else the global one ([global]), else the default for the
/// app language. The one place that order lives.
String pickTranslationTarget({
  String? trackPref,
  String? global,
  required String appLanguage,
}) => trackPref ?? global ?? appTarget(appLanguage);
