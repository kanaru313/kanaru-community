import 'dart:convert';

import '../text/text_sanitizer.dart';
import '../tools/tool_env.dart';
import '../tools/tool_rows.dart';
import 'variable_catalog.dart';

/// Largest value one variable or chip puts into the request, in UTF-8 bytes.
const int variableValueMaxBytes = 24 * 1024;

/// Queue entries the short version keeps around the loaded one.
const int queueShortEntries = 50;

/// What reading one variable gave.
sealed class VariableRead {
  const VariableRead();
}

class VariableFound extends VariableRead {
  const VariableFound({required this.full, required this.short});

  /// The whole value.
  final String full;

  /// The shorter form sent when [full] is over the budget and the user
  /// accepts it.
  final String short;
}

/// Nothing to fill with; [reason] is a short English phrase.
class VariableMissing extends VariableRead {
  const VariableMissing(this.reason);

  final String reason;
}

int utf8Length(String s) => utf8.encode(s).length;

/// Cuts [text] to at most [maxBytes] UTF-8 bytes on a character boundary and
/// ends it with `\n[…]` when something was cut.
String clipUtf8(String text, int maxBytes) {
  if (utf8Length(text) <= maxBytes) return text;
  const marker = '\n[…]';
  final room = maxBytes - utf8Length(marker);
  if (room <= 0) return '';
  final out = StringBuffer();
  var used = 0;
  for (final r in text.runes) {
    final cost = r < 0x80
        ? 1
        : r < 0x800
        ? 2
        : r < 0x10000
        ? 3
        : 4;
    if (used + cost > room) break;
    out.writeCharCode(r);
    used += cost;
  }
  return '$out$marker';
}

/// The song loaded in the player as a visible row, or why there is none.
Future<({TrackRow? row, String? missing, NowPlayingSnapshot? now})>
currentTrack(ToolEnv env) async {
  final now = await env.playback.nowPlaying();
  final id = now.trackId;
  if (id == null) return (row: null, missing: 'nothing is playing', now: now);
  final found = await env.library.visibleOf([id]);
  if (found.visible.isEmpty) {
    return (row: null, missing: 'the playing song is not available', now: now);
  }
  return (row: found.visible.first, missing: null, now: now);
}

/// Text of the now-playing value (also the now-playing chip's data).
Future<VariableRead> readNowPlaying(ToolEnv env) async {
  final cur = await currentTrack(env);
  final row = cur.row;
  if (row == null) return VariableMissing(cur.missing!);
  final now = cur.now!;
  final text = [
    trackRowText(row),
    'state: ${now.playing ? 'playing' : 'paused'}; '
        'position_ms: ${now.positionMs}'
        '${now.durationMs == null ? '' : '; duration_ms: ${now.durationMs}'}',
  ].join('\n');
  return VariableFound(full: text, short: text);
}

Future<VariableRead> _readQueue(ToolEnv env) async {
  final queue = await env.playback.queue();
  final items = queue.items;
  if (items.isEmpty) return const VariableMissing('the queue is empty');
  final found = await env.library.visibleOf([for (final e in items) e.trackId]);
  final byId = {for (final t in found.visible) t.id: t};
  String row(QueueEntryRef e) {
    final t = byId[e.trackId];
    return t == null
        ? joinRow([e.entryId, e.trackId, '(unavailable)'])
        : joinRow([e.entryId, e.trackId, t.title, t.artist, t.album, t.year]);
  }

  String render(int from, int to) => [
    'rows: entryId|trackId|title|artist|album|year',
    'length: ${items.length}',
    if (queue.current != null) 'current: ${queue.current}',
    if (from > 0 || to < items.length) 'window: $from-${to - 1}',
    for (var i = from; i < to; i++) row(items[i]),
  ].join('\n');

  final current = queue.current ?? 0;
  var from = current - queueShortEntries ~/ 2;
  if (from < 0) from = 0;
  var to = from + queueShortEntries;
  if (to > items.length) {
    to = items.length;
    from = (to - queueShortEntries).clamp(0, to);
  }
  return VariableFound(full: render(0, items.length), short: render(from, to));
}

Future<VariableRead> _readLyrics(ToolEnv env) async {
  final cur = await currentTrack(env);
  final row = cur.row;
  if (row == null) return VariableMissing(cur.missing!);
  return switch (await env.lyrics.read(row.id)) {
    LyricsAbsent(:final reason) => VariableMissing(reason),
    LyricsFound(:final lines) when lines.every((l) => l.trim().isEmpty) =>
      const VariableMissing('the song has no lyrics'),
    LyricsFound(:final lines) => () {
      final text = lines.join('\n');
      return VariableFound(
        full: text,
        short: clipUtf8(text, variableValueMaxBytes),
      );
    }(),
  };
}

/// Reads the value of [variable] from the ports. [AiVariable.input] is never
/// filled by the app.
Future<VariableRead> readVariable(AiVariable variable, ToolEnv env) async {
  switch (variable) {
    case AiVariable.nowPlaying:
      return readNowPlaying(env);
    case AiVariable.title:
    case AiVariable.artist:
    case AiVariable.album:
      final cur = await currentTrack(env);
      final row = cur.row;
      if (row == null) return VariableMissing(cur.missing!);
      final value = switch (variable) {
        AiVariable.title => row.title,
        AiVariable.artist => row.artist,
        _ => row.album,
      };
      if (value == null || sanitizeText(value).trim().isEmpty) {
        return VariableMissing('the song has no ${variable.name}');
      }
      return VariableFound(full: value, short: value);
    case AiVariable.lyrics:
      return _readLyrics(env);
    case AiVariable.queue:
      return _readQueue(env);
    case AiVariable.input:
      return const VariableMissing('input is typed by the user');
  }
}
