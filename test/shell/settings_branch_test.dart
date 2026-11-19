import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/ui/mini_player.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru/src/screens/first_run/state/first_run_gate.dart';
import 'package:kanaru/src/screens/now_playing/now_playing_path.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../support/app_harness.dart';
import '../support/icon_button_finders.dart';

class _Gate extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) => state = value;
}

final _gate = NotifierProvider<_Gate, bool>(_Gate.new);

GoRouter _router(ProviderContainer c) => c.read(routerProvider);

/// Location of the topmost page, pushed pages included.
String _location(ProviderContainer c) =>
    _router(c).routerDelegate.currentConfiguration.last.matchedLocation;

Future<void> _go(WidgetTester tester, ProviderContainer c, String path) async {
  _router(c).go(path);
  await tester.pumpAndSettle();
}

Future<void> _altLeft(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await tester.pumpAndSettle();
}

Future<bool> _back(WidgetTester tester) async {
  final handled = await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  return handled;
}

/// Records what the app tells the platform about handling Back; Android
/// forwards Back to Flutter only while the last value is true.
List<bool> _recordFrameworkHandlesBack(WidgetTester tester) {
  final calls = <bool>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
        calls.add(call.arguments as bool);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  return calls;
}

/// The sidebar row labelled [label], read through semantics.
Finder _sidebarRow(String label) => find.descendant(
  of: find.byKey(const ValueKey('sidebar')),
  matching: find.text(label),
);

void main() {
  const desktopW = 1400.0, desktopH = 900.0;
  const mobileW = 400.0, mobileH = 800.0;

  group('desktop', () {
    testWidgets(
      'Settings pages render inside the shell with Settings selected',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final c = await pumpKanaruApp(
          tester,
          width: desktopW,
          height: desktopH,
        );
        await _go(tester, c, '/settings');
        expect(find.byKey(const ValueKey('sidebar')), findsOneWidget);
        expect(find.text('Appearance'), findsOneWidget);
        // Root of the branch: no back arrow in the page header.
        expect(
          find.descendant(
            of: find.byType(PageHeader),
            matching: byIconButton('Back'),
          ),
          findsNothing,
        );
        // No search action on Settings headers.
        expect(
          find.descendant(
            of: find.byType(PageHeader),
            matching: byIconButton('Search'),
          ),
          findsNothing,
        );
        expect(
          tester.getSemantics(_sidebarRow('Settings')),
          isSemantics(isSelected: true, hasSelectedState: true, isButton: true),
        );
        semantics.dispose();

        await _go(tester, c, '/settings/about');
        expect(_location(c), '/settings/about');
        expect(find.byKey(const ValueKey('sidebar')), findsOneWidget);
        // Selecting Settings again from a sub-page goes to the root.
        await tester.tap(_sidebarRow('Settings'));
        await tester.pumpAndSettle();
        expect(_location(c), '/settings');

        // Other pages keep the search action.
        await _go(tester, c, '/');
        expect(
          find.descendant(
            of: find.byType(PageHeader),
            matching: byIconButton('Search'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('each Settings page is a history entry', (tester) async {
      final c = await pumpKanaruApp(tester, width: desktopW, height: desktopH);
      await _go(tester, c, '/settings');
      await _go(tester, c, '/settings/about');
      // Alt+Left walks the history one step, like the top-bar back.
      await _altLeft(tester);
      expect(_location(c), '/settings');
      await _altLeft(tester);
      expect(_location(c), isNot(startsWith('/settings')));
    });
  });

  group('mobile', () {
    testWidgets('no bottom bar, menu or tab actions under Settings', (
      tester,
    ) async {
      final c = await pumpKanaruApp(tester, width: mobileW, height: mobileH);
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(byIconButton('Settings'));
      await tester.pumpAndSettle();
      expect(_location(c), '/settings');
      expect(find.byType(NavigationBar), findsNothing);
      expect(byIconButton('Menu'), findsNothing);
      expect(byAnyIconButton('AI chat · Coming soon'), findsNothing);
      expect(byIconButton('Settings'), findsNothing);
      expect(byIconButton('Back'), findsOneWidget);

      // A sub-page pushes inside the branch with its own back.
      await _go(tester, c, '/settings/about');
      expect(find.byType(NavigationBar), findsNothing);
      expect(byIconButton('Back'), findsOneWidget);
    });

    testWidgets('no mini player under Settings, one on Home', (tester) async {
      final c = await pumpKanaruApp(
        tester,
        width: mobileW,
        height: mobileH,
        overrides: [hasCurrentTrackProvider.overrideWithValue(true)],
      );
      expect(find.byType(MiniPlayer), findsOneWidget);
      await _go(tester, c, '/settings');
      expect(find.byType(MiniPlayer), findsNothing);
      await _go(tester, c, '/settings/about');
      expect(find.byType(MiniPlayer), findsNothing);
      await _go(tester, c, '/');
      expect(find.byType(MiniPlayer), findsOneWidget);
    });

    testWidgets('Back goes sub-page, Settings root, Home', (tester) async {
      var exits = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') exits++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final c = await pumpKanaruApp(tester, width: mobileW, height: mobileH);
      await tester.tap(byIconButton('Settings'));
      await tester.pumpAndSettle();
      _router(c).push('/settings/about');
      await tester.pumpAndSettle();
      expect(_location(c), '/settings/about');

      expect(await _back(tester), isTrue);
      expect(_location(c), '/settings');
      expect(await _back(tester), isTrue);
      expect(_location(c), '/');
      expect(find.byType(NavigationBar), findsOneWidget);
      // On Home the shell exits the app.
      expect(exits, 0);
      expect(await _back(tester), isTrue);
      expect(exits, 1);
    });

    testWidgets(
      'the platform is told the app handles Back at the Settings root',
      (tester) async {
        final calls = _recordFrameworkHandlesBack(tester);
        await pumpKanaruApp(tester, width: mobileW, height: mobileH);
        // Home: Back is left to the system.
        expect(calls.isEmpty || calls.last == false, isTrue);

        await tester.tap(byIconButton('Settings'));
        await tester.pumpAndSettle();
        expect(calls.last, isTrue);

        await tester.tap(byIconButton('Back'));
        await tester.pumpAndSettle();
        expect(calls.last, isFalse);
      },
    );

    testWidgets('the root back arrow goes Home', (tester) async {
      final c = await pumpKanaruApp(tester, width: mobileW, height: mobileH);
      await tester.tap(byIconButton('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(byIconButton('Back'));
      await tester.pumpAndSettle();
      expect(_location(c), '/');
    });
  });

  testWidgets('resizing across the breakpoint keeps the Settings location', (
    tester,
  ) async {
    final c = await pumpKanaruApp(tester, width: desktopW, height: desktopH);
    await _go(tester, c, '/settings/about');
    tester.view.physicalSize = const Size(800, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(_location(c), '/settings/about');
    tester.view.physicalSize = const Size(desktopW, desktopH);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sidebar')), findsOneWidget);
    expect(_location(c), '/settings/about');
  });

  group('root-level behaviour from Settings', () {
    testWidgets('the first-run redirect still applies', (tester) async {
      final c = await pumpKanaruApp(
        tester,
        width: mobileW,
        height: mobileH,
        overrides: [_gate.overrideWith(_Gate.new)],
        firstRunRequired: firstRunRequiredProvider.overrideWith(
          (ref) => ref.watch(_gate),
        ),
        settle: false,
      );
      await tester.pump();
      await _go(tester, c, '/settings');
      expect(_location(c), '/settings');
      c.read(_gate.notifier).set(true);
      await tester.pump();
      await tester.pump();
      expect(_location(c), firstRunPath);
    });

    testWidgets('Now Playing pushes above the shell and returns to Settings', (
      tester,
    ) async {
      final c = await pumpKanaruApp(tester, width: mobileW, height: mobileH);
      await _go(tester, c, '/settings');
      final seen = <String>[];
      void record() => seen.add(_location(c));
      _router(c).routerDelegate.addListener(record);
      addTearDown(() => _router(c).routerDelegate.removeListener(record));
      _router(c).push(nowPlayingPath);
      await tester.pumpAndSettle();
      // The page sat on the root navigator, above the shell. With nothing
      // playing it leaves again on its own, back to where it came from.
      expect(seen, contains(nowPlayingPath));
      expect(_location(c), '/settings');
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
