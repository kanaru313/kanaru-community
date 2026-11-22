import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, AsyncLoading;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/state/alerts_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_actions_provider.dart';
import 'package:kanaru/src/plugins/state/updates_provider.dart';
import 'package:kanaru/src/extension/state/extension_registry.dart';
import 'package:kanaru/src/extension/state/registry_entries.dart';
import 'package:kanaru/src/platform/domain/media_permissions.dart';
import 'package:kanaru/src/platform/state/settings_save_status_provider.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru/src/screens/settings/state/app_edition.dart';
import 'package:material_ui/material_ui.dart' show Theme;

import '../../support/icon_button_finders.dart';
import '../plugins/support/plugin_fixtures.dart';
import 'support/settings_host.dart';

void main() {
  const missing = MediaPermissionState(
    audio: MediaPermissionStatus.denied,
    images: MediaPermissionStatus.granted,
  );
  const granted = MediaPermissionState(
    audio: MediaPermissionStatus.granted,
    images: MediaPermissionStatus.granted,
  );

  testWidgets('shows the rows of every block and the page title', (
    tester,
  ) async {
    await pumpSettings(tester, size: const Size(400, 1600));
    expect(find.text('Settings'), findsOneWidget);
    for (final name in [
      'Appearance',
      'Library',
      'Playback',
      'Lyrics',
      'Plugins',
      'AI chat',
      'Integrations',
      'Data and storage',
      'Advanced',
      'Kanaru Pro',
      'About',
    ]) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    // Appearance, Library, Playback, Lyrics, Plugins and About are built here;
    // the rest wait.
    expect(find.text('Coming soon'), findsNWidgets(5));
  });

  testWidgets('the Playback row opens its page', (tester) async {
    final h = await pumpSettings(tester, size: const Size(400, 1600));
    await tester.tap(find.text('Playback'));
    await tester.pumpAndSettle();
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.playback,
    );
  });

  testWidgets('the Lyrics row opens its page', (tester) async {
    final h = await pumpSettings(tester, size: const Size(400, 1600));
    await tester.tap(find.text('Lyrics'));
    await tester.pumpAndSettle();
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.lyrics,
    );
  });

  testWidgets('integrations summary follows the shell', (tester) async {
    await pumpSettings(tester, size: const Size(400, 1600));
    expect(find.text('Web server on the local network'), findsOneWidget);
    await pumpSettings(tester, size: const Size(1400, 1600));
    expect(
      find.text('MCP server, web server on the local network'),
      findsOneWidget,
    );
  });

  group('library row permission suffix', () {
    testWidgets('missing music permission on Android', (tester) async {
      await pumpSettings(
        tester,
        size: const Size(400, 1600),
        permission: missing,
      );
      expect(find.textContaining('music permission missing'), findsOneWidget);
      // The suffix alone is painted as an error.
      final errorColor = Theme.of(tester.element(find.text('Library')))
          .colorScheme
          .error;
      final colors = <String, Color?>{};
      final rich = tester.widget<RichText>(
        find
            .descendant(
              of: find.textContaining('music permission missing'),
              matching: find.byType(RichText),
            )
            .first,
      );
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) {
          colors[span.text!] = span.style?.color;
        }
        return true;
      });
      expect(colors[' · music permission missing'], errorColor);
    });

    testWidgets('granted', (tester) async {
      await pumpSettings(
        tester,
        size: const Size(400, 1600),
        permission: granted,
      );
      expect(find.textContaining('music permission missing'), findsNothing);
    });

    testWidgets('no permission on Linux', (tester) async {
      await pumpSettings(tester, size: const Size(400, 1600));
      expect(find.textContaining('music permission missing'), findsNothing);
    });
  });

  group('Plugins row', () {
    Finder dotLabel() => find.bySemanticsLabel(
      RegExp('A plugin has a problem or an update needs review'),
    );

    testWidgets('opens the plugin store', (tester) async {
      final h = await pumpPlugins(
        tester,
        StoreFixture(),
        location: SettingsPaths.root,
        size: const Size(400, 1600),
      );
      await tester.tap(find.text('Plugins'));
      await tester.pumpAndSettle();
      expect(
        h.router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/settings/plugins',
      );
    });

    testWidgets('no dot when nothing needs attention', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSettings(tester, size: const Size(400, 1600));
      expect(dotLabel(), findsNothing);
      handle.dispose();
    });

    testWidgets('a plugin with a problem lights the dot', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSettings(
        tester,
        size: const Size(400, 1600),
        quietPlugins: false,
        overrides: [
          ...quietPluginOverrides().skip(1),
          pluginAlertsProvider.overrideWithValue(
            const AsyncData(
              PluginAlerts({
                'a': {PluginAlert.broken},
              }),
            ),
          ),
        ],
      );
      expect(dotLabel(), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an update that needs review lights the dot', (tester) async {
      final handle = tester.ensureSemantics();
      final fixture = StoreFixture(reviewIds: ['a']);
      addTearDown(fixture.close);
      await pumpSettings(
        tester,
        size: const Size(400, 1600),
        quietPlugins: false,
        overrides: fixture.overrides,
      );
      expect(dotLabel(), findsOneWidget);
      handle.dispose();
    });

    testWidgets('loading or a database error shows no dot', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSettings(
        tester,
        size: const Size(400, 1600),
        quietPlugins: false,
        overrides: [
          ...quietPluginOverrides().skip(2),
          pluginAlertsProvider.overrideWithValue(
            AsyncError<PluginAlerts>('db', StackTrace.empty),
          ),
          updatesProvider.overrideWithValue(const AsyncLoading()),
        ],
      );
      expect(dotLabel(), findsNothing);
      expect(find.text('Plugins'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('reading the row starts the restore once', (tester) async {
      var starts = 0;
      await pumpSettings(
        tester,
        size: const Size(400, 1600),
        quietPlugins: false,
        overrides: [
          ...quietPluginOverrides().take(2),
          pluginRestoreProvider.overrideWith((ref) async {
            starts++;
            return const [];
          }),
        ],
      );
      expect(starts, 1);
    });
  });

  group('Pro row', () {
    testWidgets('free: badge and coming soon', (tester) async {
      await pumpSettings(tester, size: const Size(400, 1600));
      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('Activated · thank you'), findsNothing);
    });

    testWidgets('pro override: activated', (tester) async {
      await pumpSettings(
        tester,
        size: const Size(400, 1600),
        overrides: [appEditionProvider.overrideWithValue(AppEdition.pro)],
      );
      expect(find.text('Activated · thank you'), findsOneWidget);
      expect(find.text('PRO'), findsNothing);
      // The Pro row is no longer one of the coming-soon rows.
      expect(find.text('Coming soon'), findsNWidgets(5));
    });
  });

  testWidgets('a registered section renders after the four blocks', (
    tester,
  ) async {
    final registry = ExtensionRegistry()
      ..addSettingsSection(
        SettingsSection(
          id: 'probe',
          order: 1,
          builder: (_) => const Text('probe section'),
        ),
      );
    await pumpSettings(tester, size: const Size(400, 1600), registry: registry);
    expect(find.text('probe section'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('probe section')).dy,
      greaterThan(tester.getTopLeft(find.text('About')).dy),
    );
  });

  testWidgets('root has no back arrow; Appearance and About open', (
    tester,
  ) async {
    final h = await pumpSettings(tester, size: const Size(1400, 900));
    expect(byIconButton('Back'), findsNothing);
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.about,
    );
    expect(byIconButton('Back'), findsOneWidget);
    await tester.tap(byIconButton('Back'));
    await tester.pumpAndSettle();
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.root,
    );
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      SettingsPaths.appearance,
    );
  });

  group('save failure banner', () {
    testWidgets('shown while the store cannot write', (tester) async {
      await pumpSettings(
        tester,
        overrides: [
          settingsSaveFailingProvider.overrideWith((ref) => Stream.value(true)),
        ],
      );
      expect(find.textContaining("Couldn't save settings"), findsOneWidget);
    });

    testWidgets('absent when saving works', (tester) async {
      await pumpSettings(tester);
      expect(find.textContaining("Couldn't save settings"), findsNothing);
    });
  });

  testWidgets('rows hold at 200 % text without overflow', (tester) async {
    await pumpSettings(tester, size: const Size(400, 3000), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
