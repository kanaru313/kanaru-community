import 'dart:io';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/data/font_storage.dart';
import 'package:kanaru/src/fonts/state/font_providers.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';

import '../../support/icon_button_finders.dart';
import 'support/settings_host.dart';

class _Paths implements AppPaths {
  _Paths(this.dataDir);
  @override
  final Directory dataDir;
  @override
  Directory get cacheDir => dataDir;
  @override
  Directory get configDir => dataDir;
}

void main() {
  const tall = Size(400, 1600);

  testWidgets('shows the four blocks', (tester) async {
    await pumpSettings(tester, location: SettingsPaths.appearance, size: tall);
    for (final text in [
      'Appearance',
      'Theme',
      'Language',
      'Color and motion',
      'Pure black',
      'Animations',
      'Text',
      'Font',
      'Text size',
      'Display',
      'Seek bar',
    ]) {
      expect(find.text(text), findsAtLeastNWidgets(1), reason: text);
    }
    // The system window frame row is desktop only.
    expect(find.text('System window frame'), findsNothing);
  });

  testWidgets('desktop adds the window frame row, coming soon', (tester) async {
    await pumpSettings(
      tester,
      location: SettingsPaths.appearance,
      size: const Size(1400, 1600),
    );
    expect(find.text('System window frame'), findsOneWidget);
    // Only the window frame is not built yet.
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('Font row shows the active font and opens the font page', (
    tester,
  ) async {
    final h = await pumpSettings(
      tester,
      location: SettingsPaths.appearance,
      size: tall,
      overrides: [
        fontStorageProvider.overrideWithValue(
          FontStorage(_Paths(Directory.systemTemp)),
        ),
      ],
    );
    expect(find.text('Nunito'), findsOneWidget);
    await h.store.write('app.font', 'system');
    await tester.pumpAndSettle();
    expect(find.text('System font'), findsOneWidget);
    await tester.tap(find.text('Font'));
    await tester.pumpAndSettle();
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.fonts,
    );
    expect(find.text('Built in'), findsOneWidget);
  });

  testWidgets('Animations switch writes app.motion', (tester) async {
    final h = await pumpSettings(
      tester,
      location: SettingsPaths.appearance,
      size: tall,
    );
    await tester.tap(find.text('Animations'));
    await tester.pumpAndSettle();
    expect(h.store.read('app.motion'), false);
    await tester.tap(find.text('Animations'));
    await tester.pumpAndSettle();
    expect(h.store.read('app.motion'), true);
  });

  group('Pure black', () {
    testWidgets('locked with a reason on the light theme', (tester) async {
      final h = await pumpSettings(
        tester,
        location: SettingsPaths.appearance,
        size: tall,
      );
      await h.store.write('app.theme', 'light');
      await tester.pumpAndSettle();
      expect(find.text('Dark theme only'), findsOneWidget);
      // The reason replaces the desc.
      expect(
        find.text(
          'A fully black background in the Dark theme, good for OLED screens.',
        ),
        findsNothing,
      );
      await tester.tap(find.text('Pure black'));
      await tester.pumpAndSettle();
      expect(h.store.read('app.pure_black'), isNull);
    });

    testWidgets('writes app.pure_black on the dark theme', (tester) async {
      final h = await pumpSettings(
        tester,
        location: SettingsPaths.appearance,
        size: tall,
      );
      await h.store.write('app.theme', 'dark');
      await tester.pumpAndSettle();
      expect(find.text('Dark theme only'), findsNothing);
      expect(
        find.text(
          'A fully black background in the Dark theme, good for OLED screens.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Pure black'));
      await tester.pumpAndSettle();
      expect(h.store.read('app.pure_black'), true);
    });
  });

  testWidgets('text size picker writes app.text_scale', (tester) async {
    final h = await pumpSettings(
      tester,
      location: SettingsPaths.appearance,
      size: tall,
    );
    expect(find.text('100 %'), findsOneWidget);
    expect(find.text('Nunito'), findsOneWidget);
    expect(
      find.text('Off: pages and sheets appear at once, without sliding.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Text size'));
    await tester.pumpAndSettle();
    // The picker has no caption; the default step carries its own subtitle.
    expect(
      find.text(
        'Text size of the whole app, multiplied by the system text size.',
      ),
      findsNothing,
    );
    expect(find.text('Default'), findsOneWidget);
    await tester.tap(find.text('125 %'));
    await tester.pumpAndSettle();
    expect(h.store.read('app.text_scale'), 125);
    expect(find.text('125 %'), findsOneWidget);
  });

  testWidgets('theme picker writes app.theme', (tester) async {
    final h = await pumpSettings(
      tester,
      location: SettingsPaths.appearance,
      size: tall,
    );
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(h.store.read('app.theme'), 'dark');
  });

  testWidgets('Seek bar row shows the style and opens its page', (
    tester,
  ) async {
    // The seek bar page plays a pretend clock on open; reduced motion keeps
    // it from scheduling frames forever.
    final h = await pumpSettings(
      tester,
      location: SettingsPaths.appearance,
      size: tall,
      reduceMotion: true,
    );
    expect(find.text('Bars'), findsOneWidget);
    await h.store.write('playback.seek_bar_style', 'squiggle');
    await tester.pumpAndSettle();
    expect(find.text('Squiggle'), findsOneWidget);
    await h.store.write('playback.seek_bar_style', 'flat');
    await tester.pumpAndSettle();
    expect(find.text('Flat bar'), findsOneWidget);
    await tester.tap(find.text('Seek bar'));
    await tester.pumpAndSettle();
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.seekBar,
    );
    // Back leads to Appearance.
    await tester.tap(byIconButton('Back'));
    await tester.pumpAndSettle();
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.appearance,
    );
  });

  testWidgets('rows hold at 200 % text without overflow', (tester) async {
    await pumpSettings(
      tester,
      location: SettingsPaths.appearance,
      size: const Size(400, 3000),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
