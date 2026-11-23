import 'dart:convert';

import 'lyrics_candidate.dart';

/// Most results one `search` answer may carry; the rest is dropped.
const maxProviderResults = 20;

/// Longest result id, in characters.
const maxRemoteIdLength = 256;

/// Longest title, artist or album, in code points.
const maxLabelLength = 512;

/// Largest lyrics text, in UTF-8 bytes. A larger text is refused.
const maxLyricsTextBytes = 1024 * 1024;

/// A duration of this much or more is not believed: the result has none.
const maxCandidateDuration = Duration(hours: 24);

/// The data a plugin script returned does not have the documented shape.
/// [reason] is runtime-made text naming the field, never a script value, so
/// it is safe to log (pass it to `PluginRunner.reportRejectedOutput`).
class PluginOutputException implements Exception {
  const PluginOutputException(this.reason, {this.dropped = const []});

  final String reason;

  /// The per-item reasons collected before the output was refused.
  final List<String> dropped;

  @override
  String toString() => 'PluginOutputException($reason)';
}

/// What `search` returned: the usable [candidates] and one numbered reason per
/// item that was left out.
class SearchRead {
  const SearchRead(this.candidates, this.dropped);

  final List<LyricsCandidate> candidates;

  /// Like `result #4: "artist" must be a non-empty string` (numbered from 1).
  final List<String> dropped;

  /// One line for the run log: how many were dropped and the first reasons;
  /// null when nothing was dropped.
  String? get rejectionSummary => dropped.isEmpty
      ? null
      : '${dropped.length} dropped: ${dropped.take(3).join('; ')}';
}

// C0 controls except \n and \t, DEL, and the bidirectional overrides and
// isolates that can reorder text on screen.
final unsafeTextChars = RegExp(
  r'[\u0000-\u0008\u000B-\u001F\u007F\u202A-\u202E\u2066-\u2069]',
);

/// Decodes the JSON [json] of a plugin output; a text that is not JSON throws
/// [PluginOutputException].
Object? decodePluginOutput(String json) {
  try {
    return jsonDecode(json);
  } on FormatException {
    throw const PluginOutputException('the output is not valid JSON');
  }
}

/// Whether [text] is over [maxLyricsTextBytes] in UTF-8 bytes.
bool lyricsTextTooLarge(String text) {
  // A UTF-16 unit is at least one byte, and at most three.
  if (text.length > maxLyricsTextBytes) return true;
  if (text.length * 3 <= maxLyricsTextBytes) return false;
  return utf8.encode(text).length > maxLyricsTextBytes;
}
