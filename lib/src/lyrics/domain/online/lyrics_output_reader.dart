import 'lyrics_candidate.dart';
import 'online_text.dart';
import 'plugin_output.dart';

/// Reads the output JSON of `lyrics`: `null` (no lyrics), `{instrumental:
/// true}` (wins over text) or `{data, type?}`. `type` `lrc` is synced text,
/// `txt` plain text; anything else is synced when the text parses as timed
/// lyrics. A blank `data` is no lyrics (null). Throws [PluginOutputException]
/// for any other shape or a `data` over 1 MiB.
LyricsBody? readLyricsOutput(String json) {
  final data = decodePluginOutput(json);
  if (data == null) return null;
  if (data is! Map) {
    throw const PluginOutputException(
      'lyrics output must be an object or null',
    );
  }
  final instrumental = data['instrumental'];
  if (instrumental != null && instrumental is! bool) {
    throw const PluginOutputException('"instrumental" must be a boolean');
  }
  if (instrumental == true) return const LyricsBody(instrumental: true);
  final text = data['data'];
  if (text is! String) {
    throw const PluginOutputException('"data" must be a string');
  }
  final type = data['type'];
  if (type != null && type is! String) {
    throw const PluginOutputException('"type" must be a string');
  }
  if (lyricsTextTooLarge(text)) {
    throw const PluginOutputException('"data" is larger than 1 MiB');
  }
  return lyricsBodyOf(text, type as String?);
}

/// The body of [raw]; null when it is blank. See [readLyricsOutput] for the
/// type rules. Control characters other than `\n` and `\t` are removed and
/// `\r\n` becomes `\n`; synced text that does not read as timed lyrics
/// becomes plain.
LyricsBody? lyricsBodyOf(String raw, String? type) {
  final text = raw.replaceAll('\r\n', '\n').replaceAll(unsafeTextChars, '');
  if (text.trim().isEmpty) return null;
  final wantsSynced = switch (type?.toLowerCase()) {
    'lrc' => true,
    'txt' => false,
    _ => null,
  };
  if (wantsSynced == false) return LyricsBody(plain: text);
  final parsed = parseOnlineText(synced: text);
  if (parsed != null && parsed.synced) return LyricsBody(syncedLrc: text);
  return LyricsBody(plain: text);
}
