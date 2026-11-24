import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError, Notifier, NotifierProvider;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/lyrics/state/online/lyrics_sources_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_services_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_values.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/state/plugin_run_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';
import 'package:kanaru/src/plugins/state/store_ops.dart'
    show pluginIconProvider;
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru/src/screens/settings/ui/lyrics/lyrics_translation_section.dart';
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
    final row = tester.widget<SetupValueRow>(
      _row('Default translation service'),
    );
    expect(row.enabled, isFalse);
    expect(row.onTap, isNull);
  });

  for (final (name, expected, pause, config) in [
    (
      'needs setup',
      'Needs setup: API key',
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

  testWidgets('?focus=translation scrolls the Translation block into view', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      location: '/settings/lyrics?focus=translation',
      size: const Size(400, 600),
      overrides: [
        ..._services(const [_google]),
        lyricsSourcesLoadedProvider.overrideWithValue(true),
      ],
    );
    await tester.pump(KMotion.focusSettle);
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    final title = find.text('Translation');
    expect(title, findsOneWidget);
    final rect = tester.getRect(title);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThan(600));
    // At the top of the page body, not just barely on screen.
    expect(rect.top, lessThan(200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('without the param the Translation block stays below', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      location: SettingsPaths.lyrics,
      size: const Size(400, 600),
      overrides: _services(const [_google]),
    );
    await tester.pump(KMotion.focusSettle);
    expect(find.text('Translation'), findsNothing);
  });

  group('deep link', () {
    Future<void> settle(WidgetTester tester) async {
      await tester.pump(KMotion.focusSettle);
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<SettingsHarness> open(
      WidgetTester tester, {
      Size size = const Size(400, 600),
      List<Override> extra = const [],
    }) => pumpSettings(
      tester,
      location: '/settings/lyrics?focus=translation',
      size: size,
      overrides: [
        ..._services(const [_google]),
        ...extra,
      ],
    );

    bool insideBlock(FocusNode? node) =>
        node?.context
            ?.findAncestorWidgetOfExactType<LyricsTranslationSection>() !=
        null;

    testWidgets('the block pulses once it is in view', (tester) async {
      await open(tester);
      final pulse = find.ancestor(
        of: find.byType(LyricsTranslationSection),
        matching: find.byType(SetupSectionPulse),
      );
      var pulsed = false;
      await tester.pump(KMotion.focusSettle);
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (pulse.evaluate().isNotEmpty &&
            tester.state<SetupSectionPulseState>(pulse).isPulsing) {
          pulsed = true;
        }
      }
      expect(pulsed, isTrue);
    });

    testWidgets('desktop: the focus moves into the block', (tester) async {
      await open(tester, size: const Size(1400, 600));
      await settle(tester);
      expect(insideBlock(FocusManager.instance.primaryFocus), isTrue);
    });

    testWidgets('mobile: the focus does not move', (tester) async {
      await open(tester);
      await settle(tester);
      expect(insideBlock(FocusManager.instance.primaryFocus), isFalse);
    });

    testWidgets('sources that load late do not push the block out of view', (
      tester,
    ) async {
      await open(
        tester,
        extra: [
          lyricsSourcesLoadedProvider.overrideWith(
            (ref) => ref.watch(_slowFlag),
          ),
          lyricsSourcesProvider.overrideWithValue([
            for (var i = 0; i < 6; i++)
              LyricsSource(
                id: 'id-$i',
                name: 'Source $i',
                version: 1,
                origin: LyricsSourceOrigin.repo,
                enabled: true,
              ),
          ]),
        ],
      );
      await settle(tester);
      final rect = tester.getRect(find.text('Translation'));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThan(600));
      expect(rect.top, lessThan(200));
    });
  });
}

/// Turns on after 600 ms: the sources rows appear after the page opened.
class _SlowFlag extends Notifier<bool> {
  @override
  bool build() {
    Timer(const Duration(milliseconds: 600), () => state = true);
    return false;
  }
}

final _slowFlag = NotifierProvider<_SlowFlag, bool>(_SlowFlag.new);
