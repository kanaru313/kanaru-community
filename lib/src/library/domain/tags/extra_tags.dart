import 'dart:convert';

/// Version written into every `track_details.extra_tags` blob.
const extraTagsVersion = 1;

/// Largest encoded blob, in UTF-8 bytes. The description is cut to fit.
const _maxBytes = 4096;

/// Raw release date strings are short; anything longer is dropped.
const _maxReleaseDateBytes = 64;

/// Tag fields without a column of their own, kept in one JSON blob.
class ExtraTags {
  const ExtraTags({this.releaseDate, this.description});

  /// Raw tag text (`YYYY`, `YYYY-MM-DD`, ...); see `parseReleaseDate`.
  final String? releaseDate;
  final String? description;

  bool get isEmpty => releaseDate == null && description == null;

  @override
  bool operator ==(Object other) =>
      other is ExtraTags &&
      other.releaseDate == releaseDate &&
      other.description == description;

  @override
  int get hashCode => Object.hash(releaseDate, description);
}

String? _clean(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}

String _json(String? releaseDate, String? description) => jsonEncode({
  'v': extraTagsVersion,
  'releaseDate': ?releaseDate,
  'description': ?description,
});

/// Encodes [releaseDate] and [description] for `extra_tags`. Null when both
/// are empty. The blob always carries `"v"`, skips null keys and never
/// exceeds 4 KB: a longer description is cut on a character boundary.
String? encodeExtraTags({String? releaseDate, String? description}) {
  var date = _clean(releaseDate);
  // A date that long is garbage: drop it rather than keep a prefix.
  if (date != null && utf8.encode(date).length > _maxReleaseDateBytes) {
    date = null;
  }
  final text = _clean(description);
  if (date == null && text == null) return null;
  var out = _json(date, text);
  var size = utf8.encode(out).length;
  if (size <= _maxBytes || text == null) return out;
  final runes = text.runes.toList();
  // Every rune takes at least one byte, so more than the cap never fits.
  if (runes.length > _maxBytes) runes.removeRange(_maxBytes, runes.length);
  while (size > _maxBytes && runes.isNotEmpty) {
    // JSON escapes can take several bytes per rune; stepping by a quarter
    // of the excess converges in a few rounds.
    final cut = ((size - _maxBytes) ~/ 4).clamp(1, runes.length);
    runes.removeRange(runes.length - cut, runes.length);
    out = _json(date, _clean(String.fromCharCodes(runes)));
    size = utf8.encode(out).length;
  }
  return out;
}

/// Reads an `extra_tags` blob. Null, broken JSON, a non-object, unknown keys
/// and values of the wrong type all give empty fields, never an error.
ExtraTags decodeExtraTags(String? raw) {
  if (raw == null || raw.isEmpty) return const ExtraTags();
  final Object? json;
  try {
    json = jsonDecode(raw);
  } on FormatException {
    return const ExtraTags();
  }
  if (json is! Map<String, Object?>) return const ExtraTags();
  final date = json['releaseDate'];
  final text = json['description'];
  return ExtraTags(
    releaseDate: date is String ? _clean(date) : null,
    description: text is String ? _clean(text) : null,
  );
}
