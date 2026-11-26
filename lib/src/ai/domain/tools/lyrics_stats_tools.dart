import 'dart:convert';

import '../settings/tool_groups.dart';
import '../text/text_sanitizer.dart';
import 'ai_tool.dart';
import 'tool_args.dart';
import 'tool_env.dart';
import 'tool_rows.dart';

/// Room kept for the fixed fields of a lyrics result (id, flags, offsets).
const int _lyricsOverheadBytes = 256;

class GetLyricsTool extends AiTool {
  const GetLyricsTool();

  @override
  String get name => 'get_lyrics';
  @override
  String get description =>
      'The lyrics of one song by id, as plain text without timestamps '
      'in pages of whole lines. A cut result gives nextOffset: call again '
      'with that offset for the rest. Only lyrics the app already has; it '
      'never searches online.';
  @override
  AiToolGroup get group => AiToolGroup.lyrics;
  @override
  Map<String, Object?> get parameters => objectSchema(
    {
      'trackId': {'type': 'integer', 'description': 'Song id.'},
      'offset': {
        'type': 'integer',
        'minimum': 0,
        'description': 'Index of the first line to return (paging).',
      },
    },
    required: const ['trackId'],
  );

  @override
  Future<ToolOutcome> call(Map<String, Object?> args, ToolEnv env) async {
    final id = args['trackId'] as int;
    final visible = await env.library.visibleOf([id]);
    if (visible.visible.isEmpty) {
      return ToolOutcome.error('track $id not found');
    }
    switch (await env.lyrics.read(id)) {
      case LyricsAbsent(:final reason):
        return ToolOutcome.ok(jsonEncode({'trackId': id, 'lyrics': reason}));
      case LyricsFound(:final lines, :final synced):
        final start = args.offset > lines.length ? lines.length : args.offset;
        // The budget is the UTF-8 size of the encoded JSON, so CJK and
        // accented text cannot pass the result cap. `\n` costs 2 bytes.
        final budget = toolResultMaxBytes - _lyricsOverheadBytes;
        final taken = <String>[];
        var used = 0;
        var next = start;
        for (; next < lines.length; next++) {
          var line = sanitizeText(lines[next]);
          var cost = _jsonBytes(line) + 2;
          if (cost > budget && taken.isEmpty) {
            // One huge line: cut it so a page always moves forward. A rune
            // costs at most 6 bytes once escaped.
            line = clipRunes(line, budget ~/ 6 - 1);
            cost = _jsonBytes(line) + 2;
          }
          if (used + cost > budget) break;
          taken.add(line);
          used += cost;
        }
        final truncated = next < lines.length;
        return ToolOutcome.ok(
          jsonEncode({
            'trackId': id,
            'synced': synced,
            'truncated': truncated,
            'offset': start,
            if (truncated) 'nextOffset': next,
            'text': taken.join('\n').trimRight(),
          }),
        );
    }
  }

  /// Bytes of [text] as a JSON string body (quotes left out).
  static int _jsonBytes(String text) =>
      utf8.encode(jsonEncode(text)).length - 2;
}

class GetListeningStatsTool extends AiTool {
  const GetListeningStatsTool();

  static const _defaultLimit = 20;

  @override
  String get name => 'get_listening_stats';
  @override
  String get description =>
      'The most played songs in a time range, with play counts. Items are '
      '"rank|id|title|artist|album|year|plays". Unavailable when the user '
      'does not record listening history.';
  @override
  AiToolGroup get group => AiToolGroup.listeningStats;
  @override
  Map<String, Object?> get parameters => objectSchema({
    'range': {
      'type': 'string',
      'enum': [for (final r in StatsRange.values) r.wire],
      'description': 'today, 7d, 30d (default), 6m, 1y or all.',
    },
    'offset': offsetProperty,
    'limit': limitProperty(50),
  });

  @override
  Future<ToolOutcome> call(Map<String, Object?> args, ToolEnv env) async {
    if (!await env.history.isRecording()) {
      return const ToolOutcome.error(
        'listening history is turned off, there are no stats',
      );
    }
    final range = StatsRange.fromWire(args.string('range') ?? '30d')!;
    final offset = args.offset;
    final r = await env.history.mostPlayed(
      range,
      offset: offset,
      limit: args.intOr('limit', _defaultLimit),
    );
    return ToolOutcome.ok(
      listResult(
        rows: [
          for (final s in r.rows)
            joinRow([
              s.rank,
              s.track.id,
              s.track.title,
              s.track.artist,
              s.track.album,
              s.track.year,
              s.plays,
            ]),
        ],
        total: r.songs,
        offset: offset,
        head: {'range': range.wire, 'totalPlays': r.plays},
      ),
    );
  }
}
