import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru/src/extension/state/extension_providers.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/platform/domain/settings_store.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/router/ui/kanaru_app.dart';
import 'package:kanaru/src/shell/ui/mobile_shell.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/memory_settings_store.dart';

class _CountingStore extends MemorySettingsStore {
  int flushes = 0;
  @override
  Future<void> flush() async => flushes++;
}

class _ThrowingStore extends MemorySettingsStore {
  @override
  Future<void> flush() => Future.error(StateError('disk'));
}

class _Scanner implements LibraryScanCommands {
  int rescans = 0;
  @override
  Future<void> rescan({bool full = false}) async => rescans++;
}

class _Ext implements KanaruExtension {
  _Ext(this.onRegister);
  final void Function(ExtensionRegistry r) onRegister;
  @override
  String get id => 'seams-test';
  @override
  void register(ExtensionRegistry r) => onRegister(r);
}

Future<void> _pump(
  WidgetTester tester,
  double width, {
  List<KanaruExtension> extra = const [],
  SettingsStore? store,
  _Scanner? scanner,
  ScanStatus scan = const ScanIdle(),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);
  final registry = ExtensionRegistry()
    ..install([...builtInExtensions, ...extra]);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        extensionRegistryProvider.overrideWithValue(registry),
        nativeVersionsProvider.overrideWithValue('bridge test'),
        settingsStoreProvider.overrideWithValue(store ?? MemorySettingsStore()),
        libraryScanCommandsProvider.overrideWithValue(scanner ?? _Scanner()),
        scanStatusProvider.overrideWith((ref) => Stream.value(scan)),
      ],
      child: const KanaruApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _byTooltip(String message) =>
    find.byWidgetPredicate((w) => w is Tooltip && w.message == message);

String _location(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .routerDelegate
        .currentConfiguration
        .uri
        .path;

Color? _rowColor(WidgetTester tester, String label) {
  final material = find
      .ancestor(of: find.text(label), matching: find.byType(Material))
      .first;
  return tester.widget<Material>(material).color;
}

void main() {
  group('desktop sidebar', () {
    testWidgets(
      'lists every item in order, dividers between bands, no Search',
      (tester) async {
        await _pump(tester, 1280);
        final sidebar = find.byKey(const ValueKey('sidebar'));
        final labels = [
          'Home',
          'Online',
          'Library',
          'Playlists',
          'Favorites',
          'Queue',
          'History',
          'Most played',
          'Settings',
        ];
        double? previous;
        for (final label in labels) {
          final item = find.descendant(of: sidebar, matching: find.text(label));
          expect(item, findsOneWidget, reason: label);
          final y = tester.getTopLeft(item).dy;
          expect(y, greaterThan(previous ?? -1), reason: label);
          previous = y;
        }
        expect(
          find.descendant(of: sidebar, matching: find.text('Search')),
          findsNothing,
        );
        expect(
          find.descendant(of: sidebar, matching: find.byType(Divider)),
          findsNWidgets(2),
        );
      },
    );

    testWidgets('out-of-scope items are dimmed with a tooltip and do nothing', (
      tester,
    ) async {
      await _pump(tester, 1280);
      expect(
        _byTooltip('Coming soon'),
        findsNWidgets(4),
      ); // Favorites, Queue, History, Most played
      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();
      expect(_location(tester), '/');
    });

    testWidgets('the item of the open page is tinted', (tester) async {
      await _pump(tester, 1280);
      final scheme = Theme.of(tester.element(find.byType(Scaffold).first))
          .colorScheme;
      expect(_rowColor(tester, 'Home'), scheme.secondaryContainer);
      expect(_rowColor(tester, 'Library'), Colors.transparent);
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(_rowColor(tester, 'Library'), scheme.secondaryContainer);
      expect(_rowColor(tester, 'Home'), Colors.transparent);
    });

    testWidgets('a child item is selected under its path and navigates', (
      tester,
    ) async {
      final ext = _Ext((r) {
        r
          ..addNavItem(
            NavItem(
              id: 'kids',
              path: '/kids',
              icon: KIcons.placeholder,
              selectedIcon: KIcons.placeholder,
              label: (_) => 'KidsTab',
              order: 106,
              sidebar: false,
            ),
          )
          ..addNavItem(
            NavItem(
              id: 'kid_songs',
              path: '/kids/songs',
              icon: KIcons.placeholder,
              selectedIcon: KIcons.placeholder,
              label: (_) => 'KidSongs',
              order: 110,
              mobileTab: false,
              parentId: 'kids',
            ),
          )
          ..addRoute(
            GoRoute(
              path: '/kids',
              builder: (_, _) => const Text('kids page'),
              routes: [
                GoRoute(
                  path: 'songs',
                  builder: (_, _) => const Text('kid songs page'),
                ),
              ],
            ),
          );
      });
      await _pump(tester, 1280, extra: [ext]);
      expect(find.text('KidsTab'), findsNothing);
      await tester.tap(find.text('KidSongs'));
      await tester.pumpAndSettle();
      expect(find.text('kid songs page'), findsOneWidget);
      final scheme = Theme.of(tester.element(find.byType(Scaffold).first))
          .colorScheme;
      expect(_rowColor(tester, 'KidSongs'), scheme.secondaryContainer);
    });

    testWidgets('an item with onSelect runs it instead of navigating', (
      tester,
    ) async {
      var called = 0;
      final ext = _Ext((r) {
        r.addNavItem(
          NavItem(
            id: 'act',
            path: '/act',
            icon: KIcons.placeholder,
            selectedIcon: KIcons.placeholder,
            label: (_) => 'Act',
            order: 300,
            mobileTab: false,
            onSelect: (_) => called++,
          ),
        );
      });
      await _pump(tester, 1280, extra: [ext]);
      await tester.tap(find.text('Act'));
      await tester.pumpAndSettle();
      expect(called, 1);
      expect(_location(tester), '/');
    });
  });

  group('search', () {
    testWidgets('page header search icon opens Search on desktop', (
      tester,
    ) async {
      await _pump(tester, 1280);
      await tester.tap(_byTooltip('Search'));
      await tester.pumpAndSettle();
      expect(find.text('Search your music.'), findsOneWidget);
    });

    testWidgets('Ctrl+F and Ctrl+K open Search', (tester) async {
      for (final key in [LogicalKeyboardKey.keyF, LogicalKeyboardKey.keyK]) {
        await _pump(tester, 1280);
        expect(find.text('Search your music.'), findsNothing);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(key);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await tester.pumpAndSettle();
        expect(find.text('Search your music.'), findsOneWidget, reason: '$key');
        GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/');
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Ctrl+F still opens Search after a dialog opened and closed', (
      tester,
    ) async {
      await _pump(tester, 1280);
      final context = tester.element(find.byType(Scaffold).first);
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(content: Text('a dialog')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('a dialog'), findsOneWidget);
      Navigator.of(tester.element(find.text('a dialog'))).pop();
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.text('Search your music.'), findsOneWidget);
    });

    testWidgets('mobile has no header search icon, only the tab', (
      tester,
    ) async {
      await _pump(tester, 360);
      expect(_byTooltip('Search'), findsOneWidget); // the bottom bar tab
    });
  });

  testWidgets('mobile bar order: Home, Library, Playlists, Search, Online', (
    tester,
  ) async {
    await _pump(tester, 360);
    final labels = [
      for (final d in tester.widgetList<NavigationDestination>(
        find.byType(NavigationDestination),
      ))
        d.label,
    ];
    expect(labels, ['Home', 'Library', 'Playlists', 'Search', 'Online']);
  });

  group('top bar', () {
    testWidgets('Rescan calls the scanner', (tester) async {
      final scanner = _Scanner();
      await _pump(tester, 1280, scanner: scanner);
      await tester.tap(_byTooltip('Rescan library'));
      await tester.pump();
      expect(scanner.rescans, 1);
    });

    testWidgets('Rescan is disabled while a scan runs', (tester) async {
      final scanner = _Scanner();
      await _pump(
        tester,
        1280,
        scanner: scanner,
        scan: const ScanRunning(phase: ScanPhase.tags, done: 1, total: 10),
      );
      await tester.tap(_byTooltip('Rescan library'), warnIfMissed: false);
      await tester.pump();
      expect(scanner.rescans, 0);
    });

    testWidgets('Keymap and AI buttons are dimmed placeholders', (
      tester,
    ) async {
      await _pump(tester, 1280);
      for (final tip in [
        'Keyboard shortcuts · Coming soon',
        'AI chat · Coming soon',
      ]) {
        final button = find.ancestor(
          of: _byTooltip(tip),
          matching: find.byType(IconButton),
        );
        final widget = button.evaluate().isEmpty
            ? tester.widget<IconButton>(
                find.descendant(
                  of: _byTooltip(tip),
                  matching: find.byType(IconButton),
                ),
              )
            : tester.widget<IconButton>(button.first);
        expect(widget.onPressed, isNull, reason: tip);
      }
    });
  });

  group('flush seam', () {
    testWidgets(
      'pause flushes settings then runs hooks, a throwing hook does not stop the rest',
      (tester) async {
        final store = _CountingStore();
        final order = <String>[];
        final ext = _Ext((r) {
          r
            ..addFlushHook((_) async {
              order.add('first');
              throw StateError('boom');
            })
            ..addFlushHook((_) async => order.add('second'));
        });
        await _pump(tester, 360, extra: [ext], store: store);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pumpAndSettle();
        expect(store.flushes, 1);
        expect(order, ['first', 'second']);
      },
    );

    testWidgets('resuming does not flush', (tester) async {
      final store = _CountingStore();
      await _pump(tester, 360, store: store);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(store.flushes, 0);
    });

    testWidgets('exit request flushes and allows exit', (tester) async {
      final ran = <String>[];
      final store = _CountingStore();
      final ext = _Ext((r) => r.addFlushHook((_) async => ran.add('hook')));
      await _pump(tester, 360, extra: [ext], store: store);
      final response = await _requestExit(tester);
      expect(response, 'exit');
      expect(store.flushes, 1);
      expect(ran, ['hook']);
    });

    testWidgets('exit request is capped at 2 s when a hook never completes', (
      tester,
    ) async {
      final never = Completer<void>();
      final ext = _Ext((r) => r.addFlushHook((_) => never.future));
      await _pump(tester, 360, extra: [ext]);
      String? response;
      unawaited(_requestExit(tester).then((v) => response = v));
      await tester.pump(const Duration(milliseconds: 1900));
      expect(response, isNull);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(response, 'exit');
    });
  });

  group('flush hang and late exit', () {
    testWidgets('a throwing settings flush still lets the app exit', (
      tester,
    ) async {
      final ext = _Ext((r) => r.addFlushHook((_) async => throw 'boom'));
      await _pump(tester, 360, extra: [ext], store: _ThrowingStore());
      expect(await _requestExit(tester), 'exit');
    });

    testWidgets('exit joining a young running flush flushes once', (
      tester,
    ) async {
      final gate = Completer<void>();
      final store = _CountingStore();
      final ext = _Ext((r) => r.addFlushHook((_) => gate.future));
      await _pump(tester, 360, extra: [ext], store: store);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 50));
      unawaited(_requestExit(tester));
      await tester.pump();
      gate.complete();
      await tester.pump();
      await tester.pump();
      expect(store.flushes, 1);
    });

    testWidgets('a hung hook does not block later flushes', (tester) async {
      final never = Completer<void>();
      final store = _CountingStore();
      var second = 0;
      final ext = _Ext((r) {
        r
          ..addFlushHook((_) => never.future)
          ..addFlushHook((_) async => second++);
      });
      await _pump(tester, 360, extra: [ext], store: store);
      String? response;
      unawaited(_requestExit(tester).then((v) => response = v));
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
      expect(response, 'exit');
      expect(store.flushes, 1);
      expect(second, 0);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(store.flushes, 2); // fresh run started; the dead one is ignored
    });

    testWidgets('exit joining an old running flush runs one more', (
      tester,
    ) async {
      final gate = Completer<void>();
      final store = _CountingStore();
      var hooks = 0;
      final ext = _Ext((r) {
        r.addFlushHook((_) async {
          hooks++;
          if (hooks == 1) await gate.future;
        });
      });
      await _pump(tester, 360, extra: [ext], store: store);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 400));
      String? response;
      unawaited(_requestExit(tester).then((v) => response = v));
      await tester.pump();
      expect(response, isNull);
      gate.complete();
      await tester.pump();
      await tester.pump();
      expect(response, 'exit');
      expect(store.flushes, 2);
      expect(hooks, 2);
    });
  });

  testWidgets(
    'a listener in the selection slot receives Back before the branch pops',
    (tester) async {
      var backs = 0;
      var consume = true;
      final router = GoRouter(
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => MobileShell(
              navigationShell: shell,
              items: [
                NavItem(
                  id: 'root',
                  path: '/',
                  icon: KIcons.placeholder,
                  selectedIcon: KIcons.placeholder,
                  label: (_) => 'Root',
                  order: 1,
                ),
                NavItem(
                  id: 'other',
                  path: '/other',
                  icon: KIcons.placeholder,
                  selectedIcon: KIcons.placeholder,
                  label: (_) => 'Other',
                  order: 2,
                ),
              ],
              selectionBar: BackButtonListener(
                onBackButtonPressed: () async {
                  backs++;
                  return consume;
                },
                child: const SizedBox.shrink(),
              ),
            ),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (_, _) => const Text('root page'),
                    routes: [
                      GoRoute(
                        path: 'detail',
                        builder: (_, _) => const Text('detail page'),
                      ),
                    ],
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: '/other',
                    builder: (_, _) => const Text('other page'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go('/detail');
      await tester.pumpAndSettle();
      expect(find.text('detail page'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(backs, 1);
      expect(
        find.text('detail page'),
        findsOneWidget,
      ); // listener consumed Back

      consume = false;
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(backs, 2);
      expect(find.text('detail page'), findsNothing);
    },
  );
}

/// Sends the platform's "app wants to exit" request; returns the app's answer.
Future<String?> _requestExit(WidgetTester tester) {
  final reply = Completer<String?>();
  final message = const JSONMethodCodec().encodeMethodCall(
    const MethodCall('System.requestAppExit', {'type': 'cancelable'}),
  );
  tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/platform',
    message,
    (data) {
      final decoded = const JSONMessageCodec().decodeMessage(data);
      reply.complete(
        decoded is List ? (decoded.first as Map)['response'] as String? : null,
      );
    },
  );
  return reply.future;
}
