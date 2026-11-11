import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/extension/state/registry_entries.dart';
import 'package:kanaru/src/playback/state/playback_flush.dart';
import 'package:kanaru/src/screens/now_playing/now_playing_registration.dart';

void main() {
  late StartupContext context;
  setUp(() {
    context = StartupContext(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
  });

  test('registers one flush hook, one exit hook and one startup hook', () {
    final r = ExtensionRegistry();
    registerNowPlaying(r);
    expect(r.flushHooks, [playbackFlushHook]);
    expect(r.beforeExitHooks, [pausePlaybackOnExitHook]);
    expect(r.startupHooks, hasLength(1));
  });

  test('the Queue nav item is a dimmed "coming soon" item', () {
    final r = ExtensionRegistry();
    registerNowPlaying(r);
    final queue = r.navItems.singleWhere((n) => n.id == 'queue');
    expect(queue.comingSoon, isTrue);
    expect(queue.onSelect, isNull);
    expect(queue.isBranch, isFalse);
  });

  test('the Now Playing page is a registered route', () {
    final r = ExtensionRegistry();
    registerNowPlaying(r);
    expect(
      r.routes.whereType<GoRoute>().map((g) => g.path),
      contains('/now-playing'),
    );
  });

  test('the startup hook returns at once where there is no session', () async {
    final r = ExtensionRegistry();
    registerNowPlaying(r);
    await r.startupHooks.single(context).timeout(const Duration(seconds: 1));
  });

  test('a throwing start is swallowed', () async {
    final hook = mediaSessionStartHook(
      start: () => Future.error(StateError('no service')),
    );
    await hook(context);
  });

  test('a hanging start is cut by the timeout', () async {
    final hook = mediaSessionStartHook(
      start: () => Completer<void>().future,
      timeout: const Duration(milliseconds: 50),
    );
    await hook(context).timeout(const Duration(seconds: 2));
  });

  test('a normal start runs once', () async {
    var calls = 0;
    final hook = mediaSessionStartHook(start: () async => calls++);
    await hook(context);
    expect(calls, 1);
  });
}
