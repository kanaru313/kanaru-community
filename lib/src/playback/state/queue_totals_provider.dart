import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/state/database_providers.dart';
import '../data/queue_totals_rows.dart';
import 'playback_providers.dart';

/// Time left after the current entry, in play order: one `SUM(duration_ms)`
/// query, run again when the queue changes at once and when `tracks` changes
/// after a one second pause (a scan rewrites many rows).
final queueRemainingProvider = StreamProvider<Duration>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final controller = ref.watch(playerControllerProvider);
  final out = StreamController<Duration>();
  var running = false;
  var again = false;
  Timer? debounce;

  Future<void> run() async {
    if (running) {
      again = true;
      return;
    }
    running = true;
    try {
      do {
        again = false;
        final q = controller.queueState;
        final cur = q.currentItem;
        final ms = cur == null
            ? 0
            : await remainingDurationMs(db, current: cur, shuffled: q.shuffled);
        if (!out.isClosed) out.add(Duration(milliseconds: ms));
      } while (again);
    } on Object catch (e, st) {
      if (!out.isClosed) out.addError(e, st);
    } finally {
      running = false;
    }
  }

  final subs = [
    controller.queueView.listen((_) => run()),
    db.tableUpdates(TableUpdateQuery.onTableName('tracks')).listen((_) {
      debounce?.cancel();
      debounce = Timer(const Duration(seconds: 1), run);
    }),
  ];
  ref.onDispose(() {
    debounce?.cancel();
    for (final s in subs) {
      s.cancel();
    }
    out.close();
  });
  return out.stream;
});
