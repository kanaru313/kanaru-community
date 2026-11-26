import '../settings/tool_groups.dart';
import '../text/text_sanitizer.dart';
import 'ai_tool.dart';
import 'tool_args.dart';
import 'tool_env.dart';
import 'tool_rows.dart';

const int _pageMax = 50;

class ListPlaylistsTool extends AiTool {
  const ListPlaylistsTool();

  @override
  String get name => 'list_playlists';
  @override
  String get description =>
      'The playlists the assistant can use: Favorites (id 0) and the '
      'playlists the user made. Items are "id|name|trackCount".';
  @override
  AiToolGroup get group => AiToolGroup.playlists;
  @override
  Map<String, Object?> get parameters =>
      objectSchema({'offset': offsetProperty});

  @override
  Future<ToolOutcome> call(Map<String, Object?> args, ToolEnv env) async {
    final all = await env.playlists.list();
    final offset = args.offset;
    final page = all.skip(offset).take(_pageMax);
    return ToolOutcome.ok(
      listResult(
        rows: [
          for (final p in page) joinRow([p.id, p.name, p.trackCount]),
        ],
        total: all.length,
        offset: offset,
      ),
    );
  }
}

class GetPlaylistTracksTool extends AiTool {
  const GetPlaylistTracksTool();

  @override
  String get name => 'get_playlist_tracks';
  @override
  String get description =>
      'The songs of one playlist, 50 per call. Items are '
      '"entryId|trackId|title|artist|album|year"; entryId is what '
      'remove_from_playlist takes.';
  @override
  AiToolGroup get group => AiToolGroup.playlists;
  @override
  Map<String, Object?> get parameters => objectSchema(
    {
      'playlistId': {
        'type': 'integer',
        'description': 'Playlist id from list_playlists (0 is Favorites).',
      },
      'offset': offsetProperty,
    },
    required: const ['playlistId'],
  );

  @override
  Future<ToolOutcome> call(Map<String, Object?> args, ToolEnv env) async {
    final id = args['playlistId'] as int;
    final result = await env.playlists.entries(id);
    if (result == null) return ToolOutcome.error('playlist $id not found');
    final offset = args.offset;
    final page = result.entries.skip(offset).take(_pageMax);
    return ToolOutcome.ok(
      listResult(
        rows: [
          for (final e in page)
            joinRow([
              e.entryId,
              e.track.id,
              e.track.title,
              e.track.artist,
              e.track.album,
              e.track.year,
            ]),
        ],
        total: result.entries.length,
        offset: offset,
        head: {'name': sanitizeText(result.name)},
      ),
    );
  }
}
