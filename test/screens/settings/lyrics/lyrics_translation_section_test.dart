import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_services_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_values.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/state/plugin_run_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';
import 'package:kanaru/src/plugins/state/store_ops.dart'
    show pluginIconProvider;
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/memory_settings_store.dart';
import '../../plugins/support/page_fixtures.dart';
import '../../plugins/support/plugin_fixtures.dart';
import '../support/settings_host.dart';

const _mobile = Size(400, 3000);

const _google = TranslateService(installId: 'id-g', name: 'Google', ai: false);
const _gemini = TranslateService(installId: 'id-m', name: 'Gemini', ai: true);

/// The installed list is given; the chosen one follows the real setting.
List<Override> _services(List<TranslateService> all, {bool icons = true}) => [
  translateServicesProvider.overrideWith((ref) {
    final chosen = ref.watch(translationServiceProvider);
    final current = all.where((s) => s.installId == chosen).firstOrNull;
    return AsyncData(
      TranslateServices(
        all: all,
        current: current,
        gone: chosen != null && current == null,
      ),
    );
  }),
  // The plugin fixture brings its own icon provider.
  if (icons) pluginIconProvider.overrideWith((ref, id) async => null),
];

Future<SettingsHarness> _open(
  WidgetTester tester, {
  List<TranslateService> all = const [_google, _gemini],
  List<Override> extra = const [],
}) => pumpSettings(
  tester,
  location: SettingsPaths.lyrics,
  size: _mobile,
  overrides: [..._services(all), ...extra],
);

Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SetupValueRow));

String _location(SettingsHarness h) =>
    h.router.routerDelegate.currentConfiguration.last.matchedLocation;

void main() {
  testWidgets('no service chosen reads "Not chosen"', (tester) async {
    await _open(tester);
    expect(
      find.descendant(
        of: _row('Default translation service'),
        matching: find.text('Not chosen'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the service picker shows the caption, AI subtitle, and writes', (
    tester,
  ) async {
    final h = await _open(tester);
    await tester.tap(find.text('Default translation service'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Lyrics, song title and artist are sent to the plugin when translating.',
      ),
      findsOneWidget,
    );
    expect(find.text('AI'), findsOneWidget);
    await tester.tap(find.text('Gemini'));
    await tester.pumpAndSettle();
    expect(h.store.read('lyrics.translation.service'), 'id-m');
    expect(
      find.descendant(
        of: _row('Default translation service'),
        matching: find.text('Gemini'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a service that was removed reads "Not chosen"', (tester) async {
    final h = await _open(tester);
    await h.container.read(translationServiceProvider.notifier).set('id-gone');
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: _row('Default translation service'),
        matching: find.text('Not chosen'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('with nothing installed the service row does not open', (
    tester,
  ) async {
    await _open(tester, all: const []);
    expect(
      tester.widget<SetupValueRow>(_row('Default translation service')).onTap,
      isNull,
    );
  });

  for (final (name, expected, pause, config) in [
    (
      'needs setup',
      'The plugin can’t run until it has: API key.',
      null,
      AsyncData<PluginConfigStatus?>(
        PluginConfigStatus(
          row: pageRow(),
          manifest: pageManifest(),
          data: const PluginConfigData(),
          missingRequired: const [
            InputField(key: 'k', title: 'API key', required: true),
          ],
        ),
      ),
    ),
    (
      'paused',
      'Paused for 4 minutes: the server says too many requests (429)',
      DateTime.now().add(const Duration(minutes: 3, seconds: 30)),
      AsyncData<PluginConfigStatus?>(
        PluginConfigStatus(
          row: pageRow(),
          manifest: pageManifest(),
          data: const PluginConfigData(),
          missingRequired: const [],
        ),
      ),
    ),
    (
      'broken package',
      'Couldn’t read the plugin’s package',
      null,
      const AsyncError<PluginConfigStatus?>('bad', StackTrace.empty),
    ),
  ]) {
    testWidgets('the chosen service with a $name shows its sentence', (
      tester,
    ) async {
      final h = await _open(
        tester,
        extra: [
          pluginPauseProvider('id-g').overrideWithValue(pause),
          pluginConfigStatusProvider('id-g').overrideWithValue(config),
        ],
      );
      expect(find.text(expected), findsNothing);
      await h.container.read(translationServiceProvider.notifier).set('id-g');
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
    });
  }

  testWidgets('a read error shows no value and does not open', (tester) async {
    await pumpSettings(
      tester,
      location: SettingsPaths.lyrics,
      size: _mobile,
      overrides: [
        translateServicesProvider.overrideWithValue(
          AsyncError<TranslateServices>('db', StackTrace.empty),
        ),
      ],
    );
    final row = _row('Default translation service');
    expect(
      find.descendant(of: row, matching: find.text('Not chosen')),
      findsNothing,
    );
    expect(tester.widget<SetupValueRow>(row).onTap, isNull);
  });

  testWidgets('the language picker writes a code, and back to the app one', (
    tester,
  ) async {
    final h = await _open(tester);
    expect(
      find.descendant(
        of: _row('Default translation language'),
        matching: find.text('English'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Default translation language'));
    await tester.pumpAndSettle();
    expect(
      find.text('Used for songs that have no language of their own.'),
      findsOneWidget,
    );
    expect(find.text('Follows the app language (English)'), findsOneWidget);
    await tester.tap(find.text('Japanese'));
    await tester.pumpAndSettle();
    expect(h.store.read('lyrics.translation.target'), 'ja');
    await tester.tap(find.text('Default translation language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Follows the app language (English)'));
    await tester.pumpAndSettle();
    expect(h.store.read('lyrics.translation.target'), isNull);
  });

  testWidgets('Translate ahead is the inert coming-soon row with Pro', (
    tester,
  ) async {
    await _open(tester);
    final row = tester.widget<SetupValueRow>(_row('Translate ahead'));
    expect(row.comingSoon, isTrue);
    expect(row.onTap, isNull);
    expect(
      find.descendant(
        of: _row('Translate ahead'),
        matching: find.byType(ProBadge),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the add row opens the store on translate plugins', (
    tester,
  ) async {
    final h = await pumpPlugins(
      tester,
      StoreFixture(),
      location: SettingsPaths.lyrics,
      size: _mobile,
      overrides: _services(const [_google], icons: false),
    );
    await tester.tap(find.text('Add a translation service'));
    await tester.pumpAndSettle();
    expect(_location(h), '/settings/plugins');
    expect(h.router.state.uri.toString(), '/settings/plugins?kind=translate');
  });

  testWidgets('the size row reads Medium, its picker writes the pref', (
    tester,
  ) async {
    final h = await _open(tester);
    expect(
      find.descendant(
        of: _row('Translation text size'),
        matching: find.text('Medium'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Translation text size'));
    await tester.pumpAndSettle();
    expect(find.text('Default'), findsOneWidget);
    await tester.tap(find.text('Large'));
    await tester.pumpAndSettle();
    expect(h.store.read('lyrics.translation.size'), 'large');
    expect(
      find.descendant(
        of: _row('Translation text size'),
        matching: find.text('Large'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the size row sits between the language and Translate ahead', (
    tester,
  ) async {
    await _open(tester);
    double top(String t) => tester.getTopLeft(find.text(t)).dy;
    expect(
      top('Default translation language'),
      lessThan(top('Translation text size')),
    );
    expect(top('Translation text size'), lessThan(top('Translate ahead')));
  });

  testWidgets('an unknown stored size reads Medium', (tester) async {
    await pumpSettings(
      tester,
      location: SettingsPaths.lyrics,
      size: _mobile,
      store: MemorySettingsStore()..write('lyrics.translation.size', 'huge'),
      overrides: _services(const []),
    );
    expect(
      find.descendant(
        of: _row('Translation text size'),
        matching: find.text('Medium'),
      ),
      findsOneWidget,
    );
  });
}
