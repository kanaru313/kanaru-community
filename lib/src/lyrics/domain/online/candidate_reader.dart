import 'lyrics_candidate.dart';
import 'lyrics_output_reader.dart';
import 'plugin_output.dart';

export 'lyrics_output_reader.dart' show readLyricsOutput;
export 'plugin_output.dart';

final _anyControl = RegExp(r'[\u0000-\u001F\u007F]');
final _spaces = RegExp(r'\s+');

/// Reads the output JSON of `search`: an array of `{id, title, artist,
/// album?, durationMs?, lyrics?}`. An item that breaks the shape is dropped
/// with a numbered reason; labels lose control characters and extra spaces;
/// repeated ids (the first wins) and items past [maxProviderResults] are
/// dropped. A `durationMs` of 24 h or more is ignored, not the item.
///
/// Throws [PluginOutputException] for a non-array, and for a non-empty array
/// without a single valid item (a broken plugin, not "no lyrics").
SearchRead readSearchOutput(String json, {required String providerId}) {
  final data = decodePluginOutput(json);
  if (data is! List) {
    throw const PluginOutputException('search output must be an array');
  }
  final candidates = <LyricsCandidate>[];
  final dropped = <String>[];
  final seen = <String>{};
  for (var i = 0; i < data.length; i++) {
    if (candidates.length >= maxProviderResults) {
      dropped.add('results past the $maxProviderResults-th were ignored');
      break;
    }
    final out = _readItem(data[i], providerId);
    if (out.problem != null) {
      dropped.add('result #${i + 1}: ${out.problem}');
    } else if (!seen.add(out.candidate!.remoteId)) {
      dropped.add('result #${i + 1}: "id" repeats an earlier result');
    } else {
      candidates.add(out.candidate!);
    }
  }
  if (data.isNotEmpty && candidates.isEmpty) {
    throw PluginOutputException(
      'search output has no valid result',
      dropped: dropped,
    );
  }
  return SearchRead(candidates, dropped);
}

({LyricsCandidate? candidate, String? problem}) _readItem(
  Object? item,
  String providerId,
) {
  ({LyricsCandidate? candidate, String? problem}) bad(String problem) =>
      (candidate: null, problem: problem);
  if (item is! Map) return bad('must be an object');
  final id = item['id'];
  if (id is! String ||
      id.trim().isEmpty ||
      id.runes.length > maxRemoteIdLength ||
      _anyControl.hasMatch(id)) {
    return bad(
      '"id" must be a non-empty string of at most $maxRemoteIdLength '
      'characters without control characters',
    );
  }
  final title = _label(item['title']);
  if (title == null || title.isEmpty) {
    return bad('"title" must be a non-empty string');
  }
  final artist = _label(item['artist']);
  if (artist == null || artist.isEmpty) {
    return bad('"artist" must be a non-empty string');
  }
  if (title.runes.length > maxLabelLength ||
      artist.runes.length > maxLabelLength) {
    return bad('"title" or "artist" is longer than $maxLabelLength characters');
  }
  final rawAlbum = item['album'];
  if (rawAlbum != null && rawAlbum is! String) {
    return bad('"album" must be a string');
  }
  final album = rawAlbum is String ? _label(rawAlbum) : null;
  Duration? duration;
  final durationMs = item['durationMs'];
  if (durationMs != null) {
    final ms = _positiveInt(durationMs);
    if (ms == null) return bad('"durationMs" must be an integer above 0');
    // Never turned into a Duration when too large (a huge number overflows).
    if (ms < maxCandidateDuration.inMilliseconds) {
      duration = Duration(milliseconds: ms);
    }
  }
  final lyrics = item['lyrics'];
  if (lyrics != null && lyrics is! String) {
    return bad('"lyrics" must be a string');
  }
  if (lyrics is String && lyricsTextTooLarge(lyrics)) {
    return bad('"lyrics" is larger than 1 MiB');
  }
  return (
    candidate: LyricsCandidate(
      providerId: providerId,
      remoteId: id,
      title: title,
      artist: artist,
      album:
          album == null || album.isEmpty || album.runes.length > maxLabelLength
          ? null
          : album,
      duration: duration,
      // Inline lyrics make the result complete: no second fetch.
      body: lyrics is String ? lyricsBodyOf(lyrics, null) : null,
    ),
    problem: null,
  );
}

String? _label(Object? raw) => raw is String
    ? raw.replaceAll(unsafeTextChars, '').replaceAll(_spaces, ' ').trim()
    : null;

int? _positiveInt(Object value) {
  final int ms;
  if (value is int) {
    ms = value;
  } else if (value is double && value.isFinite && value == value.truncate()) {
    // JSON written by JavaScript may spell a whole number as 180000.0.
    ms = value.toInt();
  } else {
    return null;
  }
  return ms > 0 ? ms : null;
}
