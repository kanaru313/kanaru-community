import '../../domain/install/free_rule.dart' as rule;
import '../../domain/package/plugin_kind.dart';
import '../store/plugin_files.dart';
import '../store/plugin_row_types.dart';
import '../store/plugin_rows.dart';

/// The Free one-music-source rule applied to the installed plugins.
/// [unlocked] answers whether the Pro feature `plugins.multi-streaming` is
/// granted; it is called at every check.
class StreamingGate {
  StreamingGate({
    required this._rows,
    required this._files,
    required this._unlocked,
  });

  final PluginRows _rows;
  final PluginFiles _files;
  final bool Function() _unlocked;

  /// The streaming plugins that do not hold the slot (none with Pro).
  Future<Set<String>> lockedIds() async {
    if (_unlocked()) return const {};
    final (live, missing) = await _streamingState();
    return rule.lockedStreamingIds(
      unlocked: false,
      liveStreamingIds: live,
      missingIds: missing,
    );
  }

  /// Whether the streaming plugin [installId] may be written: with Pro, or
  /// when it holds the slot (the oldest live streaming plugin with a working
  /// folder) or no streaming plugin exists. Applied to every write of a
  /// streaming package: install, update, repair, restore. For the screens
  /// too (install button, store row).
  Future<bool> streamingInstallAllowed(String installId) async {
    if (_unlocked()) return true;
    final (live, missing) = await _streamingState();
    return rule.streamingInstallAllowed(
      unlocked: false,
      installId: installId,
      liveStreamingIds: live,
      missingIds: missing,
    );
  }

  /// The live streaming plugins, oldest first, and the ones whose package
  /// folder is missing.
  Future<(List<String>, Set<String>)> _streamingState() async {
    final live = <String>[];
    final missing = <String>{};
    for (final row in await _rows.live()) {
      if (row.pluginKind != PluginKind.streaming) continue;
      live.add(row.installId);
      if (!await _files.exists(row)) missing.add(row.installId);
    }
    return (live, missing);
  }
}
