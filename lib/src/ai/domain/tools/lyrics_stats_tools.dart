import 'dart:convert';

import '../settings/tool_groups.dart';
import '../text/text_sanitizer.dart';
import 'ai_tool.dart';
import 'tool_args.dart';
import 'tool_env.dart';
import 'tool_rows.dart';

/// Most characters of lyrics one result carries.
const int lyricsMaxChars = 12000;

class GetLyricsTool extends AiTool {
  const GetLyricsTool();

  @override
  String get name => 'get_lyrics';
  @override
  String get description =>
      'The lyrics of one song by id, as plain text without timestamps '
      '(at most $lyricsMaxChars characters). Only lyrics the app already '
      'has; it never searches online.';
  @override
  AiToolGroup get group => AiToolGroup.lyrics;
  @override
  Map<String, Object?> get parameters => objectSchema(
    {
      'trackId': {'type': 'integer', 'description': 'Song id.'},
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
        final buffer = StringBuffer();
        var used = 0;
        var truncated = false;
        for (final raw in lines) {
          final line = sanitizeText(raw);
          final cost = line.runes.length + 1;
          if (used + cost > lyricsMaxChars) {
            truncated = true;
            break;
          }
          buffer.writeln(line);
          used += cost;
        }
        return ToolOutcome.ok(
          jsonEncode({
            'trackId': id,
            'synced': synced,
            'truncated': truncated,
            'text': buffer.toString().trimRight(),
          }),
        );
    }
  }
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
