import 'package:logging/logging.dart';

import '../../media/domain/play_context.dart';
import '../../platform/domain/setting.dart';
import '../../platform/domain/settings_store.dart';
import '../data/queue_repository.dart';
import '../domain/playback_settings.dart';
import '../domain/queue_state.dart';

final _log = Logger('SessionRestore');

/// A position this close to the end (or past it) restores as 0: the file
/// would hit its end at once.
const restoreEndSlack = Duration(seconds: 1);

/// The queue, the entry and the position the last run ended with.
class RestoredSession {
  const RestoredSession({
    required this.queue,
    required this.context,
    required this.position,
  });

  final QueueState queue;
  final PlayContext? context;
  final Duration position;
}

/// The stored value of [setting], or its default when missing or unreadable.
T readSetting<T>(SettingsStore store, Setting<T> setting) {
  final raw = store.read(setting.key);
  if (raw == null) return setting.defaultValue;
  try {
    return setting.decode(raw);
  } on Object catch (e) {
    _log.warning('bad value for ${setting.key}, using the default: $e');
    return setting.defaultValue;
  }
}

/// Reads the saved session. Null when the queue is empty. It only reads:
/// `queue_entries` and the settings are never rewritten here.
///
/// - The current entry is the saved one; an id that no longer exists falls
///   back to the first entry (position 0).
/// - The position is clamped: at or past `duration - 1 s` it is 0.
/// - A context that cannot be read becomes the plain queue.
Future<RestoredSession?> loadSession({
  required QueueRepository repo,
  required SettingsStore settings,
}) async {
  final shuffled = readSetting(settings, shuffleSetting);
  final repeat = readSetting(settings, repeatSetting);
  final items = await repo.load(shuffled: shuffled);
  if (items.isEmpty) return null;

  final savedId = readSetting(settings, currentEntrySetting);
  var index = savedId == null
      ? -1
      : items.indexWhere((i) => i.entryId == savedId);
  final found = index >= 0;
  if (!found) index = 0;

  var position = found
      ? Duration(milliseconds: readSetting(settings, positionMsSetting))
      : Duration.zero;
  if (position > Duration.zero) {
    final durationMs = await repo.trackDurationMs(items[index].trackId);
    if (durationMs != null &&
        position >=
            Duration(milliseconds: durationMs) - restoreEndSlack) {
      position = Duration.zero;
    }
  }

  PlayContext? context;
  final rawContext = settings.read(contextSetting.key);
  try {
    context = rawContext == null ? null : contextSetting.decode(rawContext);
  } on Object catch (e) {
    _log.warning('bad playback context, using the queue: $e');
    context = const PlayContext(PlayContextKind.queue);
  }

  return RestoredSession(
    queue: QueueState(
      items: items,
      current: index,
      shuffled: shuffled,
      repeat: repeat,
    ),
    context: context,
    position: position,
  );
}
