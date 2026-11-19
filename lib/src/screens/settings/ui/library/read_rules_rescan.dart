import 'dart:async';

import 'package:logging/logging.dart';

import '../../../../library/domain/scan_status.dart';

final _log = Logger('settings.library');

/// Asks for a scan after a read rule changed, without waiting for it (a pass
/// already running queues it). A plain scan is enough: the pipeline reads in
/// full every folder whose applied read rules differ. Takes the commands, not
/// a `WidgetRef`: read them before any await, the page may be gone by then.
void rescanForReadRules(LibraryScanCommands commands) {
  unawaited(
    commands.rescan().catchError((Object e, StackTrace st) {
      _log.warning('re-scan after a read rule change failed', e, st);
    }),
  );
}
