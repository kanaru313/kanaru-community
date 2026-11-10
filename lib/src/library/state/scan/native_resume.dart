import 'dart:async';

import 'package:logging/logging.dart';

import '../../data/scan/scan_pipeline_types.dart';

final _log = Logger('library.scan');

/// Waits for the native calls that timed out. When one returns, its stuck
/// mark clears and one automatic scan runs, once per folder or kind per
/// session (an automatic scan arms nothing further).
class NativeResume {
  NativeResume({
    required this.session,
    required this.disposed,
    required this.scan,
  });

  final ScanSession session;
  final bool Function() disposed;

  /// Asks for the automatic scan.
  final void Function() scan;
  final Set<String> _resumed = {};

  void watch(ScanOutcome out) {
    for (final p in out.pending) {
      unawaited(
        p.future.then((_) {
          if (disposed()) return;
          session.stuck.remove(p.key);
          if (_resumed.add(p.key)) {
            _log.info('${p.key}: native call returned; scanning again');
            scan();
          }
        }),
      );
    }
  }
}
