import 'package:logging/logging.dart';

import '../../media/domain/play_context.dart';
import '../../platform/domain/settings_store.dart';
import '../domain/playback_settings.dart';

final _log = Logger('PositionSaver');

/// What the saver would write for a flush.
class SavedPosition {
  const SavedPosition({
    required this.entryId,
    required this.position,
    required this.context,
  });

  final int entryId;
  final Duration position;
  final PlayContext? context;
}

/// Keeps the session in `playback.*` settings: the position right away on
/// pause, seek, track change and stop (the controller calls [save]), and a
/// snapshot for the exit flush.
///
/// While [frozen] (a restored session whose file has not loaded yet) nothing
/// is written, so a missing drive cannot overwrite the good session with
/// position 0 of another entry.
///
/// The saver holds its own copy of position, entry and context, set by the
/// controller; a stray tick of a file that is about to be replaced cannot
/// reach it.
class PositionSaver {
  PositionSaver(this._settings);

  final SettingsStore _settings;

  /// Starts frozen; the restore (or the first user command) lifts it.
  bool frozen = true;

  /// While playing, the position is written again after this much progress.
  static const checkpoint = Duration(seconds: 15);

  Duration _lastWritten = Duration.zero;
  int? _entryId;
  PlayContext? _context;
  Duration _position = Duration.zero;

  /// The controller's view right now.
  void observe({
    required int? entryId,
    required PlayContext? context,
    required Duration position,
    bool playing = false,
  }) {
    _entryId = entryId;
    _context = context;
    _position = position;
    // Tick-driven, no timer: a crash or an OEM kill loses at most 15 s.
    if (playing && (position - _lastWritten).abs() >= checkpoint) {
      save(position);
    }
  }

  /// Writes the position now (coalesced by the store).
  void save(Duration position) {
    _position = position;
    if (frozen || _entryId == null) return;
    _lastWritten = position;
    _settings
        .write(positionMsSetting.key, position.inMilliseconds)
        .catchError((Object e) => _log.warning('could not save position: $e'));
  }

  /// What a flush writes; null when frozen or nothing is loaded.
  SavedPosition? snapshot() {
    final id = _entryId;
    if (frozen || id == null) return null;
    return SavedPosition(entryId: id, position: _position, context: _context);
  }
}
