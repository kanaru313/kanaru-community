import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../lrc_parser.dart';
import '../lyrics.dart';
import 'lyrics_candidate.dart';

/// The lines of one stored or fetched online lyrics text.
class OnlineText {
  const OnlineText(this.lines, {required this.synced});

  final List<LyricLine> lines;
  final bool synced;
}

/// The first of [synced] and [plain] that parses (through the one LRC
/// parser; the origin it is given is dropped), null when neither does.
OnlineText? parseOnlineText({String? synced, String? plain}) {
  for (final text in [synced, plain]) {
    if (text == null || text.trim().isEmpty) continue;
    final lyrics = parseLyricsText(text, LyricsOrigin.lrc);
    if (lyrics != null) return OnlineText(lyrics.lines, synced: lyrics.synced);
  }
  return null;
}

/// Identifies the words of a text: hex sha256 of the non-blank line texts
/// joined with `\n`. Timestamps are ignored, so a re-timed copy of a rejected
/// text is recognised.
String lyricsContentHash(List<LyricLine> lines) {
  final texts = [
    for (final line in lines)
      if (line.text.trim().isNotEmpty) line.text,
  ];
  return sha256.convert(utf8.encode(texts.join('\n'))).toString();
}

/// The content hash of [candidate]'s text; null for an instrumental result
/// or one without usable text (a result that came without a body has no hash
/// until its body is fetched).
String? candidateContentHash(LyricsCandidate candidate) {
  final body = candidate.body;
  if (body == null || body.instrumental) return null;
  final text = parseOnlineText(synced: body.syncedLrc, plain: body.plain);
  return text == null ? null : lyricsContentHash(text.lines);
}
