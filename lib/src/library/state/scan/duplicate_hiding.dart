import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../database/database.dart';
import '../../../database/state/database_providers.dart';
import '../../../database/track_duplicates.dart';
import '../../domain/scan/format_groups.dart';
import 'scan_settings.dart';

final _log = Logger('library.scan');

/// Duplicate-hiding rules of the library: quality comes from the codec or,
/// when unknown, the extension (the key itself is written by the row builder).
final DuplicateRules libraryDuplicateRules = DuplicateRules(
  losslessCodecs: losslessCodecs,
  losslessExtensions: losslessExtensions,
);

/// Runs `applyDuplicateHiding` one at a time. Each run reads the setting when
/// it starts (not when it was asked for), so whichever run is last always
/// applies the newest value, also when the user toggles during a scan pass.
class DuplicateHiding {
  DuplicateHiding({required this.db, required this.enabled});

  final AppDatabase db;

  /// Reads the setting now.
  final bool Function() enabled;
  Future<void> _tail = Future.value();

  /// Recomputes from the current setting. Completes after this run; errors
  /// reach the caller (the listener and the pipeline log them).
  Future<void> apply() {
    final run = _tail.then(
      (_) => applyDuplicateHiding(
        db,
        enabled: enabled(),
        rules: libraryDuplicateRules,
      ),
    );
    // A failed run must not block the next one.
    _tail = run.catchError((Object _) {});
    return run;
  }
}

/// The one serialiser shared by the scan pipeline, the setting listener and
/// the folder editor.
final duplicateHidingProvider = Provider<DuplicateHiding>(
  (ref) => DuplicateHiding(
    db: ref.watch(appDatabaseProvider),
    enabled: () => ref.read(dedupByFileNameProvider),
  ),
);

/// Registers the listener that recomputes when the setting changes. Called by
/// the scan controller provider, which lives for the app process.
void listenDuplicateHiding(Ref ref, DuplicateHiding hiding) {
  ref.listen<bool>(dedupByFileNameProvider, (previous, next) {
    if (previous == next) return;
    hiding.apply().catchError((Object e, StackTrace st) {
      _log.warning('duplicate hiding failed', e, st);
    });
  });
}
