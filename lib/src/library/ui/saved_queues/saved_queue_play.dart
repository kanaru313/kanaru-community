import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../playback/state/playback_providers.dart';
import '../../domain/history/history_days.dart';
import '../../state/history/local_day_provider.dart';
import '../../state/saved_queues/saved_queue_providers.dart';
import '../browse/play_actions.dart';
import 'saved_queue_labels.dart';
import 'saved_queue_read.dart';

final _log = Logger('library.saved_queues');

/// Replaces the queue with the songs saved queue [uid] can play now (in played
/// order, shuffled when [shuffle]), under the source it was saved from. The
/// queue it replaces is saved by the player as for any other play.
///
/// Reads the queue at the moment of the call, takes a play request number
/// first (a newer play anywhere in the library wins) and moves the saved queue
/// to the top of the list right before playing, so the queue being replaced
/// can never push it out of the 20. A queue with nothing playable, or one
/// that is gone, says so and plays nothing. Toasts go to the root navigator,
/// which outlives the row, page or menu that asked.
Future<void> playSavedQueue(
  BuildContext context,
  String uid, {
  bool shuffle = false,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final l10n = AppLocalizations.of(context);
  final root = Navigator.of(context, rootNavigator: true).context;
  final requests = container.read(playRequestsProvider.notifier);
  final request = requests.begin();
  final store = container.read(savedQueueStoreProvider);
  final commands = container.read(playbackCommandsProvider);
  final today = localDay(container.read(historyClockProvider)());
  void say(String message) {
    if (root.mounted) showAppSnackBar(root, message);
  }

  try {
    final detail = await readSavedQueue(store, uid);
    if (!requests.isNewest(request)) {
      _log.fine('play request $request dropped: a newer one started');
      return;
    }
    final info = detail?.summary.savedQueue;
    if (detail == null || info == null) {
      say(l10n.savedQueueNotFoundTitle);
      return;
    }
    final ids = savedQueuePlayableIds(detail);
    if (ids.isEmpty) {
      say(l10n.libraryNothingToPlay);
      return;
    }
    // Named as the user saw it, before playing renames it to now.
    final name = savedQueueName(l10n, info.savedAt, today);
    if (!await store.touch(uid)) {
      say(l10n.savedQueueNotFoundTitle);
      return;
    }
    if (!requests.isNewest(request)) return;
    await playIds(commands, ids, savedQueuePlayContext(info), shuffle: shuffle);
    say(l10n.savedQueuePlaying(name, ids.length));
  } on Object catch (e, s) {
    _log.warning('playing saved queue $uid failed', e, s);
    say(l10n.libraryPlayFailed);
  }
}
