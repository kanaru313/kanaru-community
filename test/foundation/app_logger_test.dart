import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/app_logger.dart';
import 'package:logging/logging.dart';

void main() {
  LogRecord rec(Level level, {Object? error, StackTrace? stack}) => LogRecord(
    level,
    'could not open /music/a.flac',
    'playback.engine',
    error,
    stack,
  );

  test('debug lines carry the error and stack frames', () {
    final line = formatLogLine(
      rec(
        Level.WARNING,
        error: StateError('bad /music/a.flac'),
        stack: StackTrace.current,
      ),
      release: false,
    );
    expect(line, startsWith('WARNING playback.engine: could not open'));
    expect(line, contains('Bad state: bad /music/a.flac'));
    expect(line, contains('\n  '));
  });

  test('release lines keep only the error type', () {
    final line = formatLogLine(
      rec(
        Level.SEVERE,
        error: StateError('bad /music/a.flac'),
        stack: StackTrace.current,
      ),
      release: true,
    );
    expect(line, contains('(StateError)'));
    expect(line, isNot(contains('Bad state')));
    expect(line, isNot(contains('\n')));
  });

  test('release prints warnings and above only; debug prints all', () {
    final printed = <String>[];
    Logger.root.clearListeners();
    setupLogging(release: true, printer: printed.add);
    Logger('t').info('quiet');
    Logger('t').warning('loud');
    expect(printed, hasLength(1));
    expect(printed.single, contains('loud'));

    printed.clear();
    Logger.root.clearListeners();
    setupLogging(release: false, printer: printed.add);
    Logger('t').info('now shown');
    expect(printed.single, contains('now shown'));
    Logger.root.clearListeners();
  });
}
