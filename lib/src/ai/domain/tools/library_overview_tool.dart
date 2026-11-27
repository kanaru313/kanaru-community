import 'dart:convert';

import '../settings/tool_groups.dart';
import 'ai_tool.dart';
import 'tool_args.dart';
import 'tool_env.dart';

/// Totals of the library, so the model never counts with `search_library`.
class GetLibraryOverviewTool extends AiTool {
  const GetLibraryOverviewTool();

  @override
  String get name => 'get_library_overview';
  @override
  String get description =>
      "Totals of the user's local library: number of songs, albums, artists "
      'and playlists, and the total length of all songs in seconds. Use it '
      'for questions like how many songs there are or how long the library '
      'is; do not count with search_library.';
  @override
  AiToolGroup get group => AiToolGroup.librarySearch;
  @override
  Map<String, Object?> get parameters => objectSchema(const {});

  @override
  Future<ToolOutcome> call(Map<String, Object?> args, ToolEnv env) async {
    final o = await env.library.overview();
    return ToolOutcome.ok(
      jsonEncode({
        'songs': o.songs,
        'albums': o.albums,
        'artists': o.artists,
        'playlists': o.playlists,
        'totalDurationSec': o.totalDurationMs ~/ 1000,
      }),
    );
  }
}
