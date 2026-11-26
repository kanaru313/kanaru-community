import 'ai_tool_registry.dart';
import 'playlist_write_tools.dart';
import 'queue_write_tools.dart';

export 'item_caps.dart';
export 'model_text.dart';
export 'playlist_write_tools.dart';
export 'queue_write_tools.dart';
export 'write_tool_base.dart';

/// The six write tools.
final AiToolProvider writeToolProvider = BuiltinToolProvider(const [
  PlayTracksTool(),
  QueueTracksTool(),
  RemoveFromQueueTool(),
  CreatePlaylistTool(),
  AddToPlaylistTool(),
  RemoveFromPlaylistTool(),
]);
