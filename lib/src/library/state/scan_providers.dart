import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/scan_status.dart';
import 'scan/scan_controller_provider.dart';

/// Scan progress and outcome.
final scanStatusProvider = StreamProvider<ScanStatus>(
  (ref) => ref.watch(scanControllerProvider).status,
);

/// Scan commands: the scan controller.
final libraryScanCommandsProvider = Provider<LibraryScanCommands>(
  (ref) => ref.watch(scanControllerProvider),
);
