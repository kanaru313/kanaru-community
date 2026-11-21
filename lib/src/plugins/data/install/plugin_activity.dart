import 'dart:async';

import '../../domain/install/install_result.dart';
import 'sweep_and_restore.dart';

/// One plugin's result in an update-all run.
class UpdateOutcome {
  const UpdateOutcome(this.installId, this.name, this.result);

  final String installId;
  final String name;
  final InstallResult result;
}

/// How far the "update all" run is. [total] is known once the run starts.
class UpdateAllState {
  const UpdateAllState({
    this.running = false,
    this.done = 0,
    this.total = 0,
    this.outcomes = const [],
  });

  final bool running;
  final int done;
  final int total;

  /// One outcome per plugin the run looked at, in order.
  final List<UpdateOutcome> outcomes;

  /// The outcomes that are not a write: failures and the ones skipped for
  /// review.
  List<UpdateOutcome> get notUpdated => [
    for (final o in outcomes)
      if (o.result is! Installed) o,
  ];
}

/// An immutable view of what the services are doing and what they know that
/// is not in the database.
class PluginActivitySnapshot {
  const PluginActivitySnapshot({
    this.updating = const {},
    this.needsReview = const {},
    this.missing = const {},
    this.updateAll = const UpdateAllState(),
  });

  /// Plugins being installed, updated or repaired right now.
  final Set<String> updating;

  /// Plugins whose update waits for the user ("Cần xem") because a download
  /// turned out to add hosts. Updates the catalog already shows as adding
  /// hosts are not listed here (they come from the catalog itself).
  final Set<String> needsReview;

  /// Live plugins whose package folder is missing, by what they need.
  final Map<String, RestoreAction> missing;
  final UpdateAllState updateAll;

  PluginActivitySnapshot copyWith({
    Set<String>? updating,
    Set<String>? needsReview,
    Map<String, RestoreAction>? missing,
    UpdateAllState? updateAll,
  }) => PluginActivitySnapshot(
    updating: updating ?? this.updating,
    needsReview: needsReview ?? this.needsReview,
    missing: missing ?? this.missing,
    updateAll: updateAll ?? this.updateAll,
  );
}

/// The in-memory state of the install services, observable. The services
/// write it; the derived providers read [watch].
class PluginActivity {
  PluginActivity();

  var _snapshot = const PluginActivitySnapshot();
  final _changes = StreamController<PluginActivitySnapshot>.broadcast(
    sync: true,
  );
  final _busy = <String, int>{};

  PluginActivitySnapshot get snapshot => _snapshot;

  /// The current snapshot, then every change.
  Stream<PluginActivitySnapshot> watch() {
    late StreamController<PluginActivitySnapshot> out;
    StreamSubscription<PluginActivitySnapshot>? sub;
    out = StreamController<PluginActivitySnapshot>(
      onListen: () {
        out.add(_snapshot);
        sub = _changes.stream.listen(out.add);
      },
      onCancel: () => sub?.cancel(),
    );
    return out.stream;
  }

  /// Runs [body] with [installId] marked as updating (counted, so two runs
  /// for one id keep it marked until both end).
  Future<T> track<T>(String installId, Future<T> Function() body) async {
    _busy[installId] = (_busy[installId] ?? 0) + 1;
    _set(_snapshot.copyWith(updating: {..._busy.keys}));
    try {
      return await body();
    } finally {
      final left = (_busy[installId] ?? 1) - 1;
      left <= 0 ? _busy.remove(installId) : _busy[installId] = left;
      _set(_snapshot.copyWith(updating: {..._busy.keys}));
    }
  }

  void flagReview(String installId) => _set(
    _snapshot.copyWith(needsReview: {..._snapshot.needsReview, installId}),
  );

  /// Forgets everything remembered about [installId] (installed, updated or
  /// removed).
  void clearFor(String installId) {
    if (!_snapshot.needsReview.contains(installId) &&
        !_snapshot.missing.containsKey(installId)) {
      return;
    }
    _set(
      _snapshot.copyWith(
        needsReview: {..._snapshot.needsReview}..remove(installId),
        missing: {..._snapshot.missing}..remove(installId),
      ),
    );
  }

  /// Replaces the plugins known to miss their folder (a fresh scan).
  void setMissing(Iterable<RestoreCandidate> candidates) => _set(
    _snapshot.copyWith(
      missing: {for (final c in candidates) c.installId: c.action},
    ),
  );

  void setUpdateAll(UpdateAllState state) =>
      _set(_snapshot.copyWith(updateAll: state));

  void _set(PluginActivitySnapshot next) {
    _snapshot = next;
    if (!_changes.isClosed) _changes.add(next);
  }

  void dispose() => _changes.close();
}
