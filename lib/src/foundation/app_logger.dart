import 'dart:developer' as developer;

import 'package:logging/logging.dart';

/// Routes every `package:logging` record to the Dart developer log (shown by
/// `flutter run` and DevTools). Safe to call once at startup.
void setupLogging({Level level = Level.INFO}) {
  Logger.root.level = level;
  Logger.root.onRecord.listen((r) {
    developer.log(
      r.message,
      time: r.time,
      level: r.level.value,
      name: r.loggerName,
      error: r.error,
      stackTrace: r.stackTrace,
    );
  });
}
