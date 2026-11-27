/// [id] as one path part: `/`, `%` and every other reserved character stay
/// inside it.
String encodeItemId(String id) => Uri.encodeComponent(id);

/// The id [encoded] names, or null when it is empty, not decodable, or not
/// exactly what [encodeItemId] writes (one spelling per id).
String? decodeItemId(String encoded) {
  if (encoded.isEmpty) return null;
  final String id;
  try {
    id = Uri.decodeComponent(encoded);
  } on ArgumentError {
    return null;
  } on FormatException {
    return null;
  }
  return encodeItemId(id) == encoded ? id : null;
}

/// [id] looks like a URL (has a scheme separator or is scheme-relative).
bool isUrlShapedId(String id) => id.contains('://') || id.startsWith('//');

/// [text] holds a UTF-16 surrogate without its pair. Such a string does not
/// survive UTF-8 (it turns into U+FFFD), so it cannot round-trip.
bool hasUnpairedSurrogate(String text) {
  final units = text.codeUnits;
  for (var i = 0; i < units.length; i++) {
    final u = units[i];
    if (u >= 0xD800 && u <= 0xDBFF) {
      if (i + 1 < units.length &&
          units[i + 1] >= 0xDC00 &&
          units[i + 1] <= 0xDFFF) {
        i++;
      } else {
        return true;
      }
    } else if (u >= 0xDC00 && u <= 0xDFFF) {
      return true;
    }
  }
  return false;
}
