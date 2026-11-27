import 'dart:convert';

import '../settings/tool_groups.dart';
import '../text/text_sanitizer.dart';
import 'ai_tool.dart';
import 'ai_tool_registry.dart';
import 'library_overview_tool.dart';
import 'lyrics_stats_tools.dart';
import 'playlist_read_tools.dart';
import 'tool_args.dart';
import 'tool_env.dart';
import 'tool_rows.dart';

export 'library_overview_tool.dart';
export 'lyrics_stats_tools.dart';
export 'playlist_read_tools.dart';

/// The nine read tools.
final AiToolProvider readToolProvider = BuiltinToolProvider(const [
  GetNowPlayingTool(),
  GetQueueTool(),
  SearchLibraryTool(),
  GetLibraryOverviewTool(),
  GetLyricsTool(),
  GetTrackInfoTool(),
  GetListeningStatsTool(),
  ListPlaylistsTool(),
  GetPlaylistTracksTool(),
]);

/// Most rows a list tool returns in one call.
const int toolPageMax = 50;

String _json(Object? v) => jsonEncode(v);

class GetNowPlayingTool extends AiTool {
  const GetNowPlayingTool();

  @override
  String get name => 'get_now_playing';
  @override
  String get description =>
      'The song that is loaded in the player: its title, artist, album, year, '
      'whether it is playing, the position and its place in the queue.';
  @override
  AiToolGroup get group => AiToolGroup.nowPlaying;
  @override
  Map<String, Object?> get parameters => objectSchema(const {});

  @override
  Future<ToolOutcome> call(Map<String, Object?> args, ToolEnv env) async {
    final now = await env.playback.nowPlaying();
    final id = now.trackId;
    if (id == null) return ToolOutcome.ok(_json({'loaded': false}));
    final found = await env.library.visibleOf([id]);
    final track = found.visible.isEmpty ? null : found.visible.single;
    return ToolOutcome.ok(
      _json({
        'loaded': true,
        'playing': now.playing,
        'track': track == null ? 'unavailable' : trackRowText(track),
        'trackId': ?(track == null ? null : id),
        'positionSec': now.positionMs ~/ 1000,
        'durationSec': ?(now.durationMs == null
            ? null
            : now.durationMs! ~/ 1000),
        'queueIndex': ?now.index,
        'queueLength': now.length,
        'format': 'id|title|artist|album|year',
      }),
    );
  }
}

class GetQueueTool extends AiTool {
  const GetQueueTool();

  /// Rows around the loaded entry when no offset is given.
  static const _before = 10;

  @override
  String get name => 'get_queue';
  @override
  String get description =>
      'The play queue in play order. Without offset it returns a window of '
      'up to 50 entries around the current one. Each item is '
      '"entryId|trackId|title|artist|album|year"; entryId is what '
      'remove_from_queue takes. A song that is not available shows an empty '
      'trackId.';
  @override
  AiToolGroup get group => AiToolGroup.queue;
  @override
  Map<String, Object?> get parameters => objectSchema({
    'offset': offsetProperty,
    'limit': limitProperty(toolPageMax),
  });

  @override
  Future<ToolOutcome> call(Map<String, Object?> args, ToolEnv env) async {
    final queue = await env.playback.queue();
    final total = queue.items.length;
    final limit = args.intOr('limit', toolPageMax);
    final current = queue.current;
    var offset = args['offset'] as int?;
    offset ??= current == null ? 0 : (current - _before).clamp(0, total);
    if (offset > total) offset = total;
    final end = (offset + limit) > total ? total : offset + limit;
    final window = queue.items.sublist(offset, end);
    final found = await env.library.visibleOf([
      for (final e in window) e.trackId,
    ]);
    final byId = {for (final t in found.visible) t.id: t};
    final rows = [
      for (final e in window)
        byId[e.trackId] == null
            ? joinRow([e.entryId, null, '(unavailable)'])
            : joinRow([
                e.entryId,
                e.trackId,
                byId[e.trackId]!.title,
                byId[e.trackId]!.artist,
                byId[e.trackId]!.album,
                byId[e.trackId]!.year,
              ]),
    ];
    return ToolOutcome.ok(
      listResult(
        rows: rows,
        total: total,
        offset: offset,
        head: {'current': ?current},
      ),
    );
  }
}

class SearchLibraryTool extends AiTool {
  const SearchLibraryTool();

  @override
  String get name => 'search_library';
  @override
  String get description =>
      "Searches the user's library by title, artist or album. Items are "
      '"id|title|artist|album|year"; use the id with other tools.';
  @override
  AiToolGroup get group => AiToolGroup.librarySearch;
  @override
  Map<String, Object?> get parameters => objectSchema(
    {
      'query': {'type': 'string', 'description': 'Words to search for.'},
      'offset': offsetProperty,
      'limit': limitProperty(toolPageMax),
    },
    required: const ['query'],
  );

  @override
  Future<ToolOutcome> call(Map<String, Object?> args, ToolEnv env) async {
    final query = sanitizeText(args.string('query')!);
    final offset = args.offset;
    final result = await env.library.search(
      query,
      offset: offset,
      limit: args.intOr('limit', toolPageMax),
    );
    return ToolOutcome.ok(
      listResult(
        rows: [for (final t in result.rows) trackRowText(t)],
        total: result.total,
        offset: offset,
      ),
    );
  }
}

class GetTrackInfoTool extends AiTool {
  const GetTrackInfoTool();

  @override
  String get name => 'get_track_info';
  @override
  String get description =>
      'Details of up to 50 songs by id: title, artist, album, year, genre, '
      'language and length. Items are '
      '"id|title|artist|album|year|genre|language|durationSec". Ids that '
      'are not in the library are listed in notFound. A cut result gives '
      'nextOffset: send the same ids again with that offset.';
  @override
  AiToolGroup get group => AiToolGroup.trackInfo;
  @override
  Map<String, Object?> get parameters => objectSchema(
    {
      'trackIds': {
        'type': 'array',
        'items': {'type': 'integer'},
        'maxItems': toolPageMax,
        'description': 'Song ids.',
      },
      'offset': offsetProperty,
    },
    required: const ['trackIds'],
  );

  @override
  Future<ToolOutcome> call(Map<String, Object?> args, ToolEnv env) async {
    final all = args.intList('trackIds');
    if (all.isEmpty) return const ToolOutcome.error('trackIds is empty');
    // Paging over the ids: `nextOffset` of a cut result is the offset to
    // send back with the same ids.
    final offset = args.offset > all.length ? all.length : args.offset;
    final ids = all.sublist(offset);
    if (ids.isEmpty) {
      return ToolOutcome.ok(
        listResult(rows: const [], total: all.length, offset: offset),
      );
    }
    final r = await env.library.details(ids);
    // One row per found id, in the order the ids were asked. A row's span is
    // the ids from the previous row up to itself, so a cut result's
    // `nextOffset` counts ids, not rows (ids with no row come before it).
    final byId = {for (final d in r.found) d.row.id: d};
    final rows = <String>[];
    final spans = <int>[];
    var span = 0;
    for (final id in ids) {
      span++;
      final d = byId.remove(id);
      if (d == null) continue;
      rows.add(
        joinRow([
          d.row.id,
          d.row.title,
          d.row.artist,
          d.row.album,
          d.row.year,
          d.genre,
          d.language,
          d.durationMs == null ? null : d.durationMs! ~/ 1000,
        ]),
      );
      spans.add(span);
      span = 0;
    }
    return ToolOutcome.ok(
      listResult(
        rows: rows,
        spans: spans,
        total: all.length,
        offset: offset,
        head: {if (r.absent.isNotEmpty) 'notFound': r.absent},
      ),
    );
  }
}
