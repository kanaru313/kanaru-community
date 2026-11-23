import 'dart:convert';

import '../../domain/online/candidate_reader.dart' show maxLyricsTextBytes;

/// What a write to the online lyrics tables did.
enum StoreResult {
  /// The row is written.
  stored,

  /// Nothing was written: the track no longer exists, or the data is not
  /// storable (no text and not instrumental, a text over 1 MiB). Never an
  /// exception: the track may be collected while a lookup is running.
  notStored,
}

/// [text] as it is stored: null when blank.
String? storableText(String? text) =>
    text == null || text.trim().isEmpty ? null : text;

/// Whether [text] is over the 1 MiB cap (in UTF-8 bytes).
bool textTooLarge(String? text) {
  if (text == null) return false;
  if (text.length > maxLyricsTextBytes) return true;
  if (text.length * 3 <= maxLyricsTextBytes) return false;
  return utf8.encode(text).length > maxLyricsTextBytes;
}
