import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../domain/scan_status.dart';

/// Scan progress and outcome. The scanner replaces the body.
final scanStatusProvider = StreamProvider<ScanStatus>(
  (ref) => Stream.value(const ScanIdle()),
);

/// Scan commands. The scanner replaces the body.
final libraryScanCommandsProvider = Provider<LibraryScanCommands>(
  (ref) => const NoLibraryScanner(),
);

/// Stand-in until the scanner exists: there is nothing to scan, so a request
/// is logged and returns.
class NoLibraryScanner implements LibraryScanCommands {
  const NoLibraryScanner();

  @override
  Future<void> rescan({bool full = false}) async {
    Logger('library.scan').info('rescan(full: $full) ignored: no scanner yet');
  }
}
