import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../library/domain/scan/artist_split.dart';
import '../../../media/domain/library_keys.dart';
import 'lyrics_candidate.dart';

// Letters, digits and combining marks (Thai or Devanagari vowels are marks)
// are kept; everything else separates words.
final _separators = RegExp(r'[^\p{L}\p{N}\p{M}]+', unicode: true);
final _apostrophes = RegExp('[\'’‘ʼ`´]');

// A bracketed part: () [] {} and the CJK pairs 【】 「」 『』.
final _groups = RegExp(
  r'\([^()]*\)|\[[^\[\]]*\]|\{[^{}]*\}|【[^【】]*】'
  r'|「[^「」]*」|『[^『』]*』',
);

// Content of a bracket or ` - ` suffix that is noise, after folding.
// Never here: live, remix, acoustic, instrumental, version, cover, demo,
// karaoke; those name another recording.
const _videoWords =
    'official|music|lyrics?|audio|video|visuali[sz]er|mv|hd|hq|4k';
final _noise = RegExp(
  '^(?:(?:feat|ft|featuring|with)\\b.*'
  '|(?:$_videoWords)(?:\\s+(?:$_videoWords))*'
  r'|(?:\d{4}\s+)?remaster(?:ed)?(?:\s+\d{4})?'
  r'|mono|stereo|radio edit)$',
);

const _dash = ' - ';

bool _isNoise(String content) => _noise.hasMatch(content.trim());

String _plain(String text) => text.replaceAll(_separators, ' ').trim();

/// Fullwidth ASCII (U+FF01-FF5E) as ASCII and the ideographic space as a
/// space, so `ＡＢＣ` equals `ABC`.
String _halfwidth(String text) {
  final out = StringBuffer();
  for (final r in text.runes) {
    if (r >= 0xFF01 && r <= 0xFF5E) {
      out.writeCharCode(r - 0xFEE0);
    } else if (r == 0x3000) {
      out.write(' ');
    } else {
      out.writeCharCode(r);
    }
  }
  return out.toString();
}

String _fold(String text) => sortForm(_halfwidth(text));

/// The title as compared: folded, `&` as `and`, apostrophes dropped, bracketed
/// or ` - ` suffix noise (featuring, official or lyric video, remaster, mono
/// or stereo, radio edit) removed unless nothing would be left, punctuation as
/// single spaces. A title of punctuation only keeps it.
String normalizeTitle(String title) {
  final folded = _fold(title)
      .replaceAll('&', ' and ')
      .replaceAll(_apostrophes, '');
  var stripped = folded.replaceAllMapped(
    _groups,
    (m) => _isNoise(m[0]!.substring(1, m[0]!.length - 1)) ? ' ' : m[0]!,
  );
  var cut = stripped.lastIndexOf(_dash);
  while (cut > 0 && _isNoise(stripped.substring(cut + _dash.length))) {
    final head = stripped.substring(0, cut);
    if (_plain(head).isEmpty) break;
    stripped = head;
    cut = stripped.lastIndexOf(_dash);
  }
  final result = _plain(stripped);
  if (result.isNotEmpty) return result;
  final fallback = _plain(folded);
  return fallback.isEmpty ? folded.trim() : fallback;
}

/// [normalizeTitle] with the spaces removed, so `Night Call` equals
/// `Nightcall`.
String joinedTitle(String normalizedTitle) =>
    normalizedTitle.replaceAll(' ', '');

/// One artist name as compared: folded, `&` as `and`, apostrophes dropped,
/// punctuation as spaces, no leading `the `.
String foldArtist(String name) {
  final folded = _plain(
    _fold(name).replaceAll('&', ' and ').replaceAll(_apostrophes, ''),
  );
  return folded.startsWith('the ') ? folded.substring(4) : folded;
}

/// The first artist of a library tag (`"A; B"` gives `A`), or null.
String? primaryArtist(String? tag) {
  if (tag == null) return null;
  final names = splitArtists([tag]);
  return names.isEmpty ? null : names.first;
}

final _remoteSeparators = RegExp(r'\s*,\s*|\s+&\s+');
final _times = RegExp(r'\s+x\s+', caseSensitive: false);

/// The names inside a remote artist string: split like a library tag, then on
/// `,` and ` & `, and only then each part on ` x `, so `Lil Nas X & Billy Ray
/// Cyrus` keeps `Lil Nas X` whole while `Skrillex x Diplo` gives both. A band
/// like `Earth, Wind & Fire` is also compared as a whole by the caller.
List<String> remoteArtistNames(String artist) => [
  for (final part in splitArtists([artist]))
    for (final piece in part.split(_remoteSeparators))
      for (final name in piece.split(_times))
        if (name.trim().isNotEmpty) name.trim(),
];

/// Key of the online lyrics cache: sha256 hex of
/// `v1|artist|title|album|seconds` over the folded primary artist, the
/// normalised title, the folded album and the rounded duration. Not
/// `tracks.song_key`: that has no album and no duration, so a live take would
/// reuse the studio lyrics. A missing field is empty.
String onlineLyricsCacheKey(LyricsQuery query) {
  final artist = primaryArtist(query.artist);
  final millis = query.duration?.inMilliseconds;
  final fields = [
    artist == null ? '' : foldArtist(artist),
    query.title == null ? '' : normalizeTitle(query.title!),
    query.album == null ? '' : _plain(_fold(query.album!)),
    millis == null ? '' : '${(millis / 1000).round()}',
  ];
  return sha256.convert(utf8.encode('v1|${fields.join('|')}')).toString();
}
