import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/linux_window_close_guard.dart';

class _FakeWindow implements WindowManagerAdapter {
  _FakeWindow(this.log);
  final List<String> log;
  void Function()? close;
  Completer<void>? destroyGate;
  bool failPrepare = false;

  @override
  Future<void> prepare() async {
    log.add('prepare');
    if (failPrepare) throw StateError('no plugin');
  }

  @override
  Future<void> setPreventClose() async => log.add('prevent');
  @override
  void onClose(void Function() handler) {
    log.add('listen');
    close = handler;
  }

  @override
  Future<void> hide() async => log.add('hide');
  @override
  Future<void> destroy() {
    log.add('destroy');
    // The real plugin emits a close event for the destroy itself.
    close?.call();
    return destroyGate?.future ?? Future<void>.value();
  }
}

void main() {
  late List<String> log;
  late _FakeWindow window;
  late LinuxWindowCloseGuard guard;

  setUp(() {
    log = [];
    window = _FakeWindow(log);
    guard = LinuxWindowCloseGuard(
      window: window,
      exit: (code) => log.add('exit$code'),
      destroyTimeout: const Duration(milliseconds: 50),
    );
  });

  test('installs listener before preventing close', () async {
    await guard.install(() async {});
    expect(log, ['prepare', 'listen', 'prevent']);
    expect(window.close, isNotNull);
  });

  test(
    'close runs hide, flush, destroy, exit; destroy echo is ignored',
    () async {
      await guard.install(() async => log.add('flush'));
      window.close!();
      await pumpEventQueue();
      expect(log, [
        'prepare',
        'listen',
        'prevent',
        'hide',
        'flush',
        'destroy',
        'exit0',
      ]);
    },
  );

  test('failing prepare does not throw and prevents nothing', () async {
    window.failPrepare = true;
    await guard.install(() async {});
    expect(log, ['prepare']);
    expect(window.close, isNull);
  });

  test('destroy timeout still exits', () async {
    window.destroyGate = Completer<void>();
    await guard.install(() async {});
    window.close!();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(log.last, 'exit0');
    expect(log.where((e) => e == 'exit0'), hasLength(1));
  });

  test('second close during the flush exits at once', () async {
    final gate = Completer<void>();
    await guard.install(() => gate.future);
    window.close!();
    await pumpEventQueue();
    expect(log, isNot(contains('exit0')));
    window.close!();
    await pumpEventQueue();
    expect(log, contains('exit0'));
    gate.complete();
    await pumpEventQueue();
  });

  test('a failing flush still destroys and exits', () async {
    await guard.install(() async => throw StateError('boom'));
    window.close!();
    await pumpEventQueue();
    expect(log.sublist(log.length - 2), ['destroy', 'exit0']);
  });
}
