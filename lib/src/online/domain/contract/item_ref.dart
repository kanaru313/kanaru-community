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
