import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/state/library_settings_focus.dart';
import 'package:kanaru/src/library/ui/library_settings_links.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru/src/screens/settings/ui/library/settings_focus_pulse.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'library_host.dart';

/// A page at `/` with one button that links to the music folders.
class _Home extends ConsumerWidget {
  const _Home();

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextButton(
    onPressed: () =>
        openLibrarySettings(context, ref, focus: LibrarySettingsAnchor.folders),
    child: const Text('choose folders'),
  );
}

const _short = Size(400, 500);

/// Lets the settle delay and the scroll pass.
Future<void> _arrive(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(KMotion.focusSettle + const Duration(milliseconds: 50));
  await tester.pump(KMotion.slow + const Duration(milliseconds: 100));
}

double _scrolled(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable).first)
    .position
    .pixels;

bool _pulsing(WidgetTester tester) => tester
    .state<SettingsFocusPulseState>(find.byType(SettingsFocusPulse))
    .isPulsing;

void main() {
  testWidgets('the link opens the page, scrolls to the folders and pulses', (
    tester,
  ) async {
    final h = await openLibrary(
      tester,
      location: '/',
      size: _short,
      home: const _Home(),
    );
    await tester.tap(find.text('choose folders'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      h.settings.router.routerDelegate.currentConfiguration.uri.toString(),
      SettingsPaths.library,
    );
    expect(_scrolled(tester), 0);

    await _arrive(tester);
    expect(_scrolled(tester), greaterThan(0));
    expect(_pulsing(tester), isTrue);
    // The request is spent once the page has shown it.
    expect(h.settings.container.read(librarySettingsFocusProvider), isNull);

    await tester.pumpAndSettle();
    expect(_pulsing(tester), isFalse);
    // The location never carried the request.
    expect(
      h.settings.router.routerDelegate.currentConfiguration.uri.query,
      isEmpty,
    );
  });

  testWidgets('a page that is already open reacts too, every time', (
    tester,
  ) async {
    final h = await openLibrary(tester, size: _short);
    final focus = h.settings.container.read(
      librarySettingsFocusProvider.notifier,
    );
    expect(_pulsing(tester), isFalse);

    focus.request(LibrarySettingsAnchor.folders);
    await _arrive(tester);
    expect(_pulsing(tester), isTrue);
    await tester.pumpAndSettle();
    expect(_pulsing(tester), isFalse);

    // The same anchor again is a new request.
    focus.request(LibrarySettingsAnchor.folders);
    await _arrive(tester);
    expect(_pulsing(tester), isTrue);
    await tester.pumpAndSettle();
  });

  testWidgets('leaving before the reveal drops the request', (tester) async {
    final h = await openLibrary(tester, size: _short);
    h.settings.container
        .read(librarySettingsFocusProvider.notifier)
        .request(LibrarySettingsAnchor.folders);
    await tester.pump();
    // The settle delay has not run: leave the page.
    h.settings.router.go('/');
    await tester.pump();
    await tester.pump(KMotion.focusSettle + KMotion.slow);
    expect(h.settings.container.read(librarySettingsFocusProvider), isNull);
    // A later plain visit neither scrolls nor pulses.
    h.settings.router.go(SettingsPaths.library);
    await tester.pumpAndSettle();
    expect(_scrolled(tester), 0);
    expect(_pulsing(tester), isFalse);
  });

  testWidgets('with reduced motion the page scrolls and does not pulse', (
    tester,
  ) async {
    final h = await openLibrary(tester, size: _short, reduceMotion: true);
    h.settings.container
        .read(librarySettingsFocusProvider.notifier)
        .request(LibrarySettingsAnchor.folders);
    await _arrive(tester);
    expect(_scrolled(tester), greaterThan(0));
    expect(_pulsing(tester), isFalse);
    expect(h.settings.container.read(librarySettingsFocusProvider), isNull);
  });

  test('every request has its own number', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(librarySettingsFocusProvider.notifier)
      ..request(LibrarySettingsAnchor.folders);
    final first = container.read(librarySettingsFocusProvider);
    notifier.request(LibrarySettingsAnchor.folders);
    expect(container.read(librarySettingsFocusProvider), isNot(first));
    notifier.clear();
    expect(container.read(librarySettingsFocusProvider), isNull);
  });
}
