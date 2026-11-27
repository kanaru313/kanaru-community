import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/router/state/app_flush.dart';

void main() {
  test('hidden and paused flush everything, on both shells', () {
    for (final android in [true, false]) {
      expect(
        lifecycleFlush(AppLifecycleState.hidden, android: android),
        LifecycleFlush.all,
      );
      expect(
        lifecycleFlush(AppLifecycleState.paused, android: android),
        LifecycleFlush.all,
      );
    }
  });

  test('inactive flushes only the live text, and only on Android', () {
    expect(
      lifecycleFlush(AppLifecycleState.inactive, android: true),
      LifecycleFlush.live,
    );
    // Desktop focus loss writes nothing.
    expect(
      lifecycleFlush(AppLifecycleState.inactive, android: false),
      LifecycleFlush.none,
    );
  });

  test('no flush when the app comes back or is running', () {
    for (final android in [true, false]) {
      expect(
        lifecycleFlush(AppLifecycleState.resumed, android: android),
        LifecycleFlush.none,
      );
      expect(
        lifecycleFlush(AppLifecycleState.detached, android: android),
        LifecycleFlush.none,
      );
    }
  });

  test(
    'the live flush runs only the live hooks, a failing one is skipped',
    () async {
      final ran = <String>[];
      final registry = ExtensionRegistry()
        ..addFlushHook((_) async => ran.add('full'))
        ..addLiveFlushHook((_) async => throw StateError('boom'))
        ..addLiveFlushHook((_) async => ran.add('live'));
      final container = ProviderContainer(
        overrides: [extensionRegistryProvider.overrideWithValue(registry)],
      );
      addTearDown(container.dispose);

      await flushLive(container);

      expect(ran, ['live']);
    },
  );
}
