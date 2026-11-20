import 'dart:async';

import 'package:drift/drift.dart';

import '../../../database/database.dart';
import '../../domain/history/history_change.dart';

/// Changes of `play_log` that can alter what the history shows: inserted or
/// removed plays. The listened-time checkpoints the recorder writes every ten
/// seconds are updates and do not match.
const playLogChanges = TableUpdateQuery.allOf([
  TableUpdateQuery.onTableName('play_log', limitUpdateKind: UpdateKind.insert),
  TableUpdateQuery.onTableName('play_log', limitUpdateKind: UpdateKind.delete),
]);

/// Any change of `tracks` (a scan writes metadata there).
const trackChanges = TableUpdateQuery.onTableName('tracks');

/// Plays changes folded over the debounce window. An update without a kind
/// (a bulk recompute, a writer insert) counts as both.
Stream<HistoryChange> watchPlayLog(
  AppDatabase db,
) => debouncedFold<Set<TableUpdate>, HistoryChange>(
  db.tableUpdates(playLogChanges),
  const Duration(milliseconds: 250),
  (updates) => HistoryChange(
    inserted: updates.any((u) => u.kind == null || u.kind == UpdateKind.insert),
    removed: updates.any((u) => u.kind == null || u.kind == UpdateKind.delete),
  ),
  (a, b) => a.merge(b),
);

Stream<void> watchTracksChanged(AppDatabase db) =>
    debounced(db.tableUpdates(trackChanges), const Duration(seconds: 1));

/// Emits once, [wait] after the last event of [source]. Single-subscription.
Stream<void> debounced(Stream<Object?> source, Duration wait) =>
    debouncedFold<Object?, void>(source, wait, (_) {}, (a, _) => a);

/// Like [debounced], but emits the events of the window folded into one value:
/// each event goes through [map], and [merge] combines it with the pending one.
/// Cancelling cancels the pending timer and the subscription, so nothing fires
/// later.
Stream<T> debouncedFold<S, T>(
  Stream<S> source,
  Duration wait,
  T Function(S event) map,
  T Function(T pending, T next) merge,
) {
  Timer? timer;
  StreamSubscription<S>? sub;
  T? pending;
  var has = false;
  late final StreamController<T> out;
  out = StreamController<T>(
    onListen: () {
      sub = source.listen(
        (e) {
          final next = map(e);
          pending = has ? merge(pending as T, next) : next;
          has = true;
          timer?.cancel();
          timer = Timer(wait, () {
            final value = pending as T;
            pending = null;
            has = false;
            out.add(value);
          });
        },
        onError: out.addError,
        onDone: () {
          timer?.cancel();
          out.close();
        },
      );
    },
    onPause: () => sub?.pause(),
    onResume: () => sub?.resume(),
    onCancel: () async {
      timer?.cancel();
      timer = null;
      await sub?.cancel();
    },
  );
  return out.stream;
}
