import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/extension/kanaru_extension.dart';
import 'package:kanaru/src/platform/domain/window_close.dart';
import 'package:kanaru/src/router/state/app_flush.dart';

import '../support/app_harness.dart';
import '../support/memory_settings_store.dart';
import '../support/nav_fixture.dart';

class _RecordingGuard implements WindowCloseGuard {
  final hooks = <Future<void> Function()>[];

  @override
  Future<void> install(Future<void> Function() beforeClose) async =>
      hooks.add(beforeClose);
}

class _CountingStore extends MemorySettingsStore {
  _CountingStore(this.log);
  final List<String> log;

  @override
  Future<void> flush() async => log.add('settings');
}

class _Ext implements KanaruExtension {
  _Ext(this.onRegister);
  final void Function(ExtensionRegistry) onRegister;

  @override
  String get id => 'test.exit';

  @override
  void register(ExtensionRegistry registry) => onRegister(registry);
}

void main() {
  testWidgets('guard is installed once; its hook runs before-exit then flush', (
    tester,
  ) async {
    final log = <String>[];
    final guard = _RecordingGuard();
    await pumpKanaruApp(
      tester,
      settings: _CountingStore(log),
      windowCloseGuard: guard,
      extensions: [
        const NavFixture(),
        _Ext(
          (r) => r
            ..addFlushHook((_) async => log.add('flush-hook'))
            ..addBeforeExitHook((_) async => log.add('before-exit')),
        ),
      ],
    );
    expect(guard.hooks, hasLength(1));
    expect(log, isEmpty);
    await guard.hooks.single();
    expect(log, ['before-exit', 'settings', 'flush-hook']);
  });

  group('FlushCoordinator.flushForExit', () {
    Future<void> run(
      WidgetTester tester,
      void Function(ExtensionRegistry) register,
      FlushCoordinator coordinator,
    ) async {
      final container = await pumpKanaruApp(
        tester,
        extensions: [const NavFixture(), _Ext(register)],
      );
      await tester.runAsync(() => coordinator.flushForExit(container));
    }

    testWidgets('a failing before-exit hook does not stop the flush', (
      tester,
    ) async {
      final log = <String>[];
      await run(
        tester,
        (r) => r
          ..addBeforeExitHook((_) async => throw StateError('x'))
          ..addBeforeExitHook((_) async => log.add('second')),
        FlushCoordinator(flush: (_) async => log.add('flush')),
      );
      expect(log, ['second', 'flush']);
    });

    testWidgets('a hung before-exit hook is cut and the flush still runs', (
      tester,
    ) async {
      final log = <String>[];
      await run(
        tester,
        (r) => r.addBeforeExitHook((_) => Completer<void>().future),
        FlushCoordinator(
          cap: const Duration(milliseconds: 200),
          flush: (_) async => log.add('flush'),
        ),
      );
      expect(log, ['flush']);
    });

    testWidgets('the total cap holds when the flush hangs', (tester) async {
      final watch = Stopwatch()..start();
      await run(
        tester,
        (r) => r.addBeforeExitHook((_) async {}),
        FlushCoordinator(
          cap: const Duration(milliseconds: 300),
          flush: (_) => Completer<void>().future,
        ),
      );
      expect(watch.elapsedMilliseconds, lessThan(1500));
    });
  });
}
