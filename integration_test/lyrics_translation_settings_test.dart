import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show AsyncData, AsyncError;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_display_prefs.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_size.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_services_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/lyrics/ui/lyrics_card.dart';
import 'package:kanaru/src/lyrics/ui/synced_lyrics_view.dart';
import 'package:kanaru/src/lyrics/ui/translation/modal/translate_service_row.dart'
    show TranslateServiceIcon;
import 'package:kanaru/src/plugins/data/store/plugin_config_values.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/state/install_ops.dart';
import 'package:kanaru/src/plugins/state/plugin_run_provider.dart';
import 'package:kanaru/src/plugins/state/plugin_store_providers.dart';
import 'package:kanaru/src/plugins/state/store_ops.dart'
    show pluginIconProvider;
import 'package:kanaru/src/screens/plugins/remove/remove_flow.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../test/lyrics/ui/lyrics_ui_host.dart';
import '../test/lyrics/ui/translation/translation_ui_host.dart';
import '../test/screens/plugins/support/install_fixtures.dart';
import '../test/screens/plugins/support/page_fixtures.dart';
import '../test/screens/plugins/support/plugin_fixtures.dart';
import '../test/screens/settings/support/settings_host.dart';

/// Lyrics translation settings (Cài đặt › Lời bài › Dịch lời), the plugin
/// page row, the remove dialog and the translation size on the lyrics views.
/// The real Settings and plugin routes and the real lyrics widgets, with the
/// plugin services faked (no network, no keys, no native library), so the
/// same file runs as a plain widget test and on the Linux device.
///
/// It asserts state (finders, semantics, sizes), never pixels. The screenshots
/// go to `/tmp/kanaru-it/shots-prc` (override with `KANARU_IT_SHOTS`) for
/// comparing with the mockups by eye; the window is 1400 px wide (desktop
/// shell width, but the page is pumped without the shell chrome).
///
/// Run on Linux (through the main checkout's `main-build.sh`):
/// `tool/integration_test.sh linux integration_test/lyrics_translation_settings_test.dart`
///
/// Screenshots: `prc-settings-no-service`, `prc-settings-service`,
/// `prc-settings-service-needs-config`, `prc-settings-service-paused`,
/// `prc-settings-ahead-pro`, `prc-picker-service`, `prc-picker-language`,
/// `prc-picker-size`, `prc-lines-<size>-<display>`, `prc-card-<size>`,
/// `prc-plugin-page-set`, `prc-plugin-page-default`, `prc-remove-dialog`.

const _desktop = Size(1400, 1000);
const _mobile = Size(400, 900);

const _google = TranslateService(installId: 'id-g', name: 'Google', ai: false);
const _gemini = TranslateService(installId: 'id-m', name: 'Gemini', ai: true);

/// The installed translate plugins are given; the chosen one follows the real
/// setting.
List<Override> _services(List<TranslateService> all) => [
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
  pluginIconProvider.overrideWith((ref, id) async => null),
];

/// Writes a screenshot of the whole window (overlays included) to the shots
/// folder. For the eye only: a failure is logged, never fails the test.
Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.runAsync(() async {
    try {
      final view = tester.binding.renderViews.first;
      final layer = view.debugLayer! as OffsetLayer;
      final image = await layer.toImage(Offset.zero & view.size);
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final dir = Directory(
        Platform.environment['KANARU_IT_SHOTS'] ?? '/tmp/kanaru-it/shots-prc',
      )..createSync(recursive: true);
      File('${dir.path}/$name.png')
          .writeAsBytesSync(bytes.buffer.asUint8List());
    } on Object catch (e) {
      debugPrint('screenshot $name failed: $e');
    }
  });
}

Future<SettingsHarness> _openSettings(
  WidgetTester tester, {
  List<TranslateService> all = const [_google, _gemini],
  List<Override> extra = const [],
  Size size = _desktop,
}) async {
  final h = await pumpSettings(
    tester,
    location: SettingsPaths.lyrics,
    size: size,
    overrides: [..._services(all), ...extra],
  );
  // Scrolled to the translation block.
  final add = find.text('Add a translation service');
  // A narrow window builds the list lazily: scroll until the row exists.
  if (add.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      add,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(add);
  await tester.pumpAndSettle();
  return h;
}

Finder _row(String title) =>
    find.ancestor(of: find.text(title), matching: find.byType(SetupValueRow));

Finder _inRow(String title, String text) =>
    find.descendant(of: _row(title), matching: find.text(text));

// The synced lines of the lyrics views and their translations.
const _lines = [
  'Sylt first line',
  'Sylt second line',
  'Sylt third line',
  'Sylt fourth line',
  'Sylt fifth line',
];
const _vi = [
  'Dòng thứ nhất',
  'Dòng thứ hai',
  'Dòng thứ ba',
  'Dòng thứ tư',
  'Dòng thứ năm',
];
final _map = {for (var i = 0; i < _lines.length; i++) _lines[i]: _vi[i]};

const _lineSize = 25.0;

TextStyle _styleOf(WidgetTester tester, String text) =>
    DefaultTextStyle.of(tester.element(find.text(text))).style;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings › Lyrics › Translation', () {
    testWidgets('no translate plugin: Not chosen, row disabled, add row', (
      tester,
    ) async {
      await _openSettings(tester, all: const []);
      expect(_inRow('Default translation service', 'Not chosen'), findsOne);
      expect(
        tester.widget<SetupValueRow>(_row('Default translation service')).onTap,
        isNull,
      );
      expect(find.text('Add a translation service'), findsOneWidget);
      await _shot(tester, 'prc-settings-no-service');
    });

    testWidgets('a chosen service shows its icon and name; Translate ahead '
        'is Soon with Pro', (tester) async {
      final h = await _openSettings(tester);
      await h.container.read(translationServiceProvider.notifier).set('id-g');
      await tester.pumpAndSettle();
      expect(_inRow('Default translation service', 'Google'), findsOne);
      expect(_inRow('Default translation service', 'Not chosen'), findsNothing);
      expect(
        find.descendant(
          of: _row('Default translation service'),
          matching: find.byType(TranslateServiceIcon),
        ),
        findsWidgets,
      );
      await _shot(tester, 'prc-settings-service');

      final ahead = tester.widget<SetupValueRow>(_row('Translate ahead'));
      expect(ahead.comingSoon, isTrue);
      expect(ahead.onTap, isNull);
      expect(
        find.descendant(
          of: _row('Translate ahead'),
          matching: find.byType(ProBadge),
        ),
        findsOneWidget,
      );
      await _shot(tester, 'prc-settings-ahead-pro');
    });

    for (final (name, shot, sentence, pause, config) in [
      (
        'needs configuration',
        'needs-config',
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
        'unreadable package',
        'broken',
        'Couldn’t read the plugin’s package',
        null,
        const AsyncError<PluginConfigStatus?>('bad', StackTrace.empty),
      ),
    ]) {
      testWidgets('a chosen service that is $name says so on its row', (
        tester,
      ) async {
        final h = await _openSettings(
          tester,
          extra: [
            pluginPauseProvider('id-g').overrideWithValue(pause),
            pluginConfigStatusProvider('id-g').overrideWithValue(config),
          ],
        );
        expect(find.text(sentence), findsNothing);
        await h.container.read(translationServiceProvider.notifier).set('id-g');
        await tester.pumpAndSettle();
        expect(_inRow('Default translation service', sentence), findsOne);
        await _shot(tester, 'prc-settings-service-$shot');
      });
    }

    testWidgets('the service picker: caption and AI subtitle', (tester) async {
      await _openSettings(tester);
      await tester.tap(find.text('Default translation service'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Lyrics, song title and artist are sent to the plugin when '
          'translating.',
        ),
        findsOneWidget,
      );
      expect(find.text('Google'), findsOneWidget);
      expect(find.text('Gemini'), findsOneWidget);
      expect(find.text('AI'), findsOneWidget);
      await _shot(tester, 'prc-picker-service');
    });

    testWidgets('the language picker: follow-the-app first, then languages', (
      tester,
    ) async {
      await _openSettings(tester);
      await tester.tap(find.text('Default translation language'));
      await tester.pumpAndSettle();
      expect(
        find.text('Used for songs that have no language of their own.'),
        findsOneWidget,
      );
      expect(find.text('Follows the app language (English)'), findsOneWidget);
      expect(find.text('Japanese'), findsOneWidget);
      await _shot(tester, 'prc-picker-language');
    });

    testWidgets('the size picker: Small / Medium (Default) / Large, caption', (
      tester,
    ) async {
      await _openSettings(tester);
      expect(_inRow('Translation text size', 'Medium'), findsOne);
      await tester.tap(find.text('Translation text size'));
      await tester.pumpAndSettle();
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Medium'), findsWidgets);
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
      expect(
        find.textContaining('The translation line under the lyrics'),
        findsOneWidget,
      );
      await _shot(tester, 'prc-picker-size');
    });
  });

  group('translation size on the lyrics views', () {
    for (final size in TranslationSize.values) {
      for (final replace in [false, true]) {
        final display = replace ? 'replace' : 'under';
        testWidgets('synced lines, ${size.name}, $display', (tester) async {
          final host = LyricsUiHost(
            line: 2,
            extra: translationOverrides(target: 'vi'),
          );
          await turnTranslationOn(host.container, replace: replace);
          await host.container.read(translationSizeProvider.notifier).set(size);
          host.container.read(viewBox.notifier).set(readyView(_map));
          await host.pump(
            tester,
            SyncedLyricsView(
              lyrics: syncedLyrics(5, text: (i) => _lines[i]),
              lineSize: _lineSize,
              sidePadding: 24,
              viewportHeight: 800,
              dim: LyricsDim.light,
              align: LyricsAlign.start,
              autoReturn: LyricsAutoReturn.off,
              trackId: trackOne,
            ),
            size: const Size(700, 900),
          );
          await settleScroll(tester);
          if (replace) {
            expect(_styleOf(tester, _vi[2]).fontSize, _lineSize);
            expect(
              _styleOf(tester, _lines[2]).fontSize,
              closeTo(_lineSize * size.replacedOriginal, 1e-9),
            );
          } else {
            expect(_styleOf(tester, _lines[2]).fontSize, _lineSize);
            expect(
              _styleOf(tester, _vi[2]).fontSize,
              closeTo(_lineSize * size.translation, 1e-9),
            );
          }
          await _shot(tester, 'prc-lines-${size.name}-$display');
        });
      }
    }

    for (final size in [TranslationSize.small, TranslationSize.large]) {
      testWidgets('Now Playing card translation, ${size.name}', (tester) async {
        final host = LyricsUiHost(
          lyrics: LyricsShown(syncedLyrics(5, text: (i) => _lines[i])),
          line: 2,
          extra: translationOverrides(target: 'vi'),
        );
        await turnTranslationOn(host.container);
        await host.container.read(translationSizeProvider.notifier).set(size);
        host.container.read(viewBox.notifier).set(readyView(_map));
        await host.pump(
          tester,
          const Padding(
            padding: EdgeInsets.all(16),
            child: LyricsCard(onOpen: null),
          ),
          size: const Size(480, 360),
        );
        final style = tester.widget<Text>(find.text(_vi[2])).style!;
        expect(style.fontSize, size.card);
        expect(
          style.height! * style.fontSize!,
          closeTo(size.cardLineHeight, 1e-5),
        );
        await _shot(tester, 'prc-card-${size.name}');
      });
    }
  });

  group('plugin page and remove dialog', () {
    testWidgets('the page row: Set as default, then Default', (tester) async {
      await pumpPlugins(
        tester,
        StoreFixture(),
        location: pagePath,
        size: _desktop,
        overrides: pageOverrides(
          AsyncData(pageData(row: pageRow(kind: 'translate'))),
        ),
      );
      expect(find.text('Default translation service'), findsOneWidget);
      expect(find.text('Set as default'), findsOneWidget);
      expect(find.text('Default'), findsNothing);
      await _shot(tester, 'prc-plugin-page-set');

      await tester.tap(find.text('Set as default'));
      await tester.pumpAndSettle();
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Set as default'), findsNothing);
      await _shot(tester, 'prc-plugin-page-default');
    });

    testWidgets('the remove dialog of a translate plugin says what is kept', (
      tester,
    ) async {
      final ops = FakeInstallOps()
        ..preview = const RemovePreview(
          installId: 'id-demo',
          name: 'Demo',
          author: 'someone',
          version: 3,
          kind: PluginKind.translate,
        );
      await pumpFlowHost(
        tester,
        ops: ops,
        size: _desktop,
        onTap: (c) => removePluginFlow(c, ops, 'id-demo'),
      );
      expect(find.text('Remove Demo?'), findsOneWidget);
      expect(find.text('Kept'), findsOneWidget);
      expect(
        find.text(
          'Saved translations, until you choose “Delete saved translations”',
        ),
        findsOneWidget,
      );
      expect(ops.removed, isEmpty, reason: 'nothing before Remove');
      await _shot(tester, 'prc-remove-dialog');
    });
  });

  group('mobile width (400 px)', () {
    testWidgets('settings block: no service, then a chosen one', (
      tester,
    ) async {
      final h = await _openSettings(tester, size: _mobile);
      expect(_inRow('Default translation service', 'Not chosen'), findsOne);
      await _shot(tester, 'prc-m-settings-no-service');
      await h.container.read(translationServiceProvider.notifier).set('id-g');
      await tester.pumpAndSettle();
      expect(_inRow('Default translation service', 'Google'), findsOne);
      await _shot(tester, 'prc-m-settings-service');
    });

    testWidgets('the size picker is a sheet with the caption', (tester) async {
      await _openSettings(tester, size: _mobile);
      await tester.tap(find.text('Translation text size'));
      await tester.pumpAndSettle();
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
      expect(
        find.textContaining('The translation line under the lyrics'),
        findsOneWidget,
      );
      await _shot(tester, 'prc-m-picker-size');
    });

    for (final size in [TranslationSize.small, TranslationSize.large]) {
      testWidgets('Now Playing card translation, ${size.name}', (tester) async {
        final host = LyricsUiHost(
          lyrics: LyricsShown(syncedLyrics(5, text: (i) => _lines[i])),
          line: 2,
          extra: translationOverrides(target: 'vi'),
        );
        await turnTranslationOn(host.container);
        await host.container.read(translationSizeProvider.notifier).set(size);
        host.container.read(viewBox.notifier).set(readyView(_map));
        await host.pump(
          tester,
          const Padding(
            padding: EdgeInsets.all(16),
            child: LyricsCard(onOpen: null),
          ),
          size: const Size(400, 360),
        );
        expect(
          tester.widget<Text>(find.text(_vi[2])).style!.fontSize,
          size.card,
        );
        expect(tester.takeException(), isNull);
        await _shot(tester, 'prc-m-card-${size.name}');
      });
    }
  });
}
