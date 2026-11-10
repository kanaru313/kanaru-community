import 'dart:developer' as developer;

import 'package:logging/logging.dart';

/// Where a printed log line goes; `print` reaches logcat on Android (tag
/// `flutter`) and stdout on Linux. Replaced in tests.
typedef LogPrinter = void Function(String line);

/// Routes every `package:logging` record to the Dart developer log (shown by
/// `flutter run` and DevTools) and also prints it, so engine and scan failures
/// reach `adb logcat` and a terminal without a debugger attached. Release
/// builds print only [printLevel] and above, and never the error message
/// itself (it may carry file paths), only its type. Safe to call once at
/// startup.
void setupLogging({
  Level level = Level.INFO,
  bool release = const bool.fromEnvironment('dart.vm.product'),
  Level printLevel = Level.WARNING,
  LogPrinter printer = print,
}) {
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
    if (release && r.level < printLevel) return;
    printer(formatLogLine(r, release: release));
  });
}

/// One printed line: `LEVEL logger: message`, then the error (its type only in
/// release) and, outside release, the first stack frames.
String formatLogLine(LogRecord r, {required bool release}) {
  final b = StringBuffer('${r.level.name} ${r.loggerName}: ${r.message}');
  final error = r.error;
  if (error != null) {
    b.write(release ? ' (${error.runtimeType})' : ' ($error)');
  }
  final stack = r.stackTrace;
  if (!release && stack != null) {
    final frames = stack.toString().split('\n').take(8).join('\n  ');
    b.write('\n  $frames');
  }
  return b.toString();
}
