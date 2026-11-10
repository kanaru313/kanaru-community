import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../scan_providers.dart';
import 'scan_capabilities.dart';

final _log = Logger('library.scan');

/// Asks the scanner for its startup work (incremental scan, garbage
/// collection). Home calls it once after its first frame.
///
/// It goes through [libraryScanCommandsProvider]: only a scanner that
/// implements [ScanStartupWork] has startup work, so a different
/// implementation of the commands (a test's scripted one) makes this a no-op
/// and starts no timer.
final scanStartupWorkProvider = Provider<void Function()>((ref) {
  return () {
    // As an Object, so the capability check is a plain runtime type test.
    final Object commands = ref.read(libraryScanCommandsProvider);
    if (commands is ScanStartupWork) {
      commands.ensureStartupWork();
    } else {
      _log.fine(
        'no startup work: ${commands.runtimeType} is not a ScanStartupWork',
      );
    }
  };
});
