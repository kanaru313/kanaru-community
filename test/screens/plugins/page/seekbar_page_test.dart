import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';

import '../../settings/support/settings_host.dart' show SettingsHarness;
import '../support/page_fixtures.dart';
import '../support/plugin_fixtures.dart';
import '../support/seekbar_fixtures.dart';

Future<SettingsHarness> _open(
  WidgetTester tester, {
  Size size = const Size(400, 2400),
  Map<String, Object?>? seekbar,
}) => pumpPlugins(
  tester,
  StoreFixture(),
  location: pagePath,
  size: size,
  overrides: pageOverrides(
    AsyncData(
      pageData(
        row: pageRow(kind: 'seekbar', name: 'Neon', hosts: const []),
        manifest: seekbarManifestOf(seekbar: seekbar),
      ),
    ),
  ),
);

void main() {
  for (final (shell, size) in [
    ('narrow', const Size(400, 2400)),
    ('wide', const Size(1400, 2400)),
  ]) {
    testWidgets('$shell: the page has the use row and the seek bar details', (
      tester,
    ) async {
      await _open(tester, size: size);
      expect(find.text('Neon'), findsWidgets);
      expect(find.text('Used in Settings › Seek bar'), findsOneWidget);
      expect(find.text('Not in use'), findsOneWidget);

      // Chi tiết: where it came from, when, what it says, licence, type, package.
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Installed from'), findsOneWidget);
      expect(find.text('Installed'), findsOneWidget);
      expect(find.text('A glowing bar'), findsOneWidget);
      expect(find.text('License'), findsOneWidget);
      expect(find.text('CC0-1.0'), findsOneWidget);
      expect(
        find.text('Seek bar plugin · Flat bar base · plugin API 2'),
        findsOneWidget,
      );
      expect(find.text('Package'), findsOneWidget);
      expect(find.text('plugin.json + 1 PNG image · no code'), findsOneWidget);
    });
  }

  testWidgets('nothing about addresses, code, settings, logs or the AI', (
    tester,
  ) async {
    await _open(tester);
    for (final absent in [
      'Sends data to',
      'No fixed address.',
      'Static facts',
      'Ask AI about this plugin',
      'Source code',
      'Connection',
      'Data',
      'Plugin settings',
      'Own storage',
      'Logs',
    ]) {
      expect(find.text(absent), findsNothing, reason: absent);
    }
    expect(find.text('Coming soon'), findsNothing);
  });

  testWidgets('a lyrics plugin keeps its Connection and Data blocks', (
    tester,
  ) async {
    await pumpPlugins(
      tester,
      StoreFixture(),
      location: pagePath,
      size: const Size(400, 2400),
      overrides: pageOverrides(AsyncData(pageData())),
    );
    expect(find.text('Connection'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Sends data to'), findsOneWidget);
  });

  testWidgets('the use row follows the stored style and ★', (tester) async {
    final h = await _open(tester);
    expect(find.text('Not in use'), findsOneWidget);

    await h.store.write('playback.seek_bar_style', 'plugin:id-demo');
    await tester.pump();
    expect(find.text('In use'), findsOneWidget);

    await h.store.write('playback.seek_bar_fallback', 'plugin:id-demo');
    await tester.pump();
    expect(
      find.text('In use · ★ while a song has no waveform'),
      findsOneWidget,
    );

    await h.store.write('playback.seek_bar_style', 'bars');
    await tester.pump();
    expect(find.text('★ while a song has no waveform'), findsOneWidget);

    // Another plugin's choice does not count for this one.
    await h.store.write('playback.seek_bar_fallback', 'plugin:id-other');
    await tester.pump();
    expect(find.text('Not in use'), findsOneWidget);
  });

  testWidgets('the use row opens Settings › Seek bar', (tester) async {
    final h = await _open(tester);
    await tester.tap(find.text('Used in Settings › Seek bar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.seekBar,
    );
  });

  testWidgets('a wave base is named in the type line', (tester) async {
    await _open(
      tester,
      seekbar: {
        'track': {'kind': 'mirror'},
      },
    );
    expect(
      find.text('Seek bar plugin · Mirror base · plugin API 2'),
      findsOneWidget,
    );
    expect(find.text('plugin.json · no code'), findsOneWidget);
  });
}
