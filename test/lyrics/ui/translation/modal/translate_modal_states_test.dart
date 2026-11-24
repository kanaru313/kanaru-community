import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_failure.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_status.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_credit_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_services_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_view.dart';
import 'package:kanaru/src/lyrics/ui/translation/modal/translate_retranslate.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'translate_modal_host.dart';

const _map = {'Line 1': 'Dòng 1', 'Line 0': 'Dòng 0', 'Line 2': 'Dòng 2'};

TranslationView _ready({String? source = 'en', bool differ = false}) =>
    TranslationView(
      status: const TranslationStatus.ready(),
      map: _map,
      sourceLang: source,
      installId: 'google',
      settingsDiffer: differ,
    );

const _credit = TranslationCredit(plugin: 'Google Translate', target: 'vi');

void main() {
  for (final (shell, size) in [
    ('mobile', const Size(400, 800)),
    ('desktop', const Size(1400, 900)),
  ]) {
    group(shell, () {
      testWidgets('ready: preview with the translation, credit, service row', (
        tester,
      ) async {
        final host = TranslateHost();
        await host.turnOn();
        host.setView(_ready(source: 'ja'));
        host.setCredit(_credit);
        await host.open(tester, size: size);
        expect(find.text('Translate lyrics'), findsOneWidget);
        expect(find.text('Preview'), findsOneWidget);
        // The sung line (index 1) with its translation under it.
        expect(find.text('Line 1'), findsOneWidget);
        expect(find.text('Dòng 1'), findsOneWidget);
        expect(find.text('Translated by Google Translate'), findsOneWidget);
        expect(find.text('Japanese · detected'), findsOneWidget);
        expect(find.text('Google Translate'), findsOneWidget);
        expect(find.text('Default for every song'), findsOneWidget);
        // A plain service has no tuning; nothing is wrong, so no bar.
        expect(find.text('AI tuning'), findsNothing);
        expect(
          find.text('Settings differ from the translation shown'),
          findsNothing,
        );
        // Japanese lyrics: the dim "Phiên âm" row.
        expect(find.text('Furigana, Romaji'), findsOneWidget);
        expect(find.text('Coming soon'), findsOneWidget);
      });

      testWidgets('not Japanese, Chinese or Korean: no transliteration', (
        tester,
      ) async {
        final host = TranslateHost();
        await host.turnOn();
        host.setView(_ready());
        await host.open(tester, size: size);
        expect(find.text('Furigana, Romaji'), findsNothing);
        expect(find.text('English · detected'), findsOneWidget);
      });

      testWidgets('off: preview and the language row only', (tester) async {
        final host = TranslateHost();
        await host.open(tester, size: size);
        expect(find.text('Auto-detect'), findsOneWidget);
        expect(find.text('Line 1'), findsOneWidget);
        expect(find.text('Below line'), findsNothing);
        expect(find.text('Google Translate'), findsNothing);
        expect(find.text('Default for every song'), findsNothing);
      });

      testWidgets('AI service: tag, tuning row, credit with model and style', (
        tester,
      ) async {
        final host = TranslateHost(tune: tuneOf());
        host.setServices(
          const TranslateServices(all: [google, gemini], current: gemini),
        );
        await host.turnOn();
        host.setView(_ready().copyOf(installId: 'gemini'));
        host.setCredit(
          const TranslationCredit(
            plugin: 'Gemini Translate',
            target: 'vi',
            model: 'Model 0',
            style: 'Natural',
          ),
        );
        await host.open(tester, size: size);
        expect(find.text('AI'), findsOneWidget);
        expect(find.text('AI tuning'), findsOneWidget);
        expect(find.text('Model 0 · Natural'), findsOneWidget);
        expect(
          find.text('Translated by Gemini Translate · Model 0 · Natural'),
          findsOneWidget,
        );
      });

      testWidgets('another plugin’s copy: credit and the bar offer a redo', (
        tester,
      ) async {
        final host = TranslateHost();
        host.setServices(
          const TranslateServices(all: [google, gemini], current: gemini),
        );
        await host.turnOn();
        host.setView(
          const TranslationView(
            status: TranslationStatus.other('google'),
            map: _map,
            installId: 'google',
          ),
        );
        host.setCredit(
          const TranslationCredit(
            plugin: 'Google Translate',
            target: 'vi',
            other: true,
          ),
        );
        await host.open(tester, size: size);
        // In the preview and as the bar's title.
        expect(
          find.text('Existing translation from Google Translate'),
          findsNWidgets(2),
        );
        expect(
          find.text('Translate again with Gemini Translate'),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(KModalButton, 'Translate again'));
        await host.settle(tester);
        expect(host.calls, ['retranslate']);
        // Nothing started a run: the wait for it ends by itself.
        await tester.pump(retranslateStartWait);
        // The modal stays open; the old translation stays.
        expect(find.text('Translate lyrics'), findsOneWidget);
      });

      testWidgets('settings differ: the bar names what changed', (
        tester,
      ) async {
        final host = TranslateHost(tune: tuneOf(modelValue: 'm1'));
        host.setServices(
          const TranslateServices(all: [google, gemini], current: gemini),
        );
        await host.turnOn();
        host.setView(
          const TranslationView(
            status: TranslationStatus.ready(),
            map: _map,
            installId: 'gemini',
            settingsDiffer: true,
            settingsJson: '{"pluginVersion":1,"model":"m0","style":"natural","instructionHash":null}',
          ),
        );
        await host.open(tester, size: size);
        expect(
          find.text('Settings differ from the translation shown'),
          findsOneWidget,
        );
        expect(find.text('Model 0 → Model 1'), findsOneWidget);
      });

      testWidgets('no service chosen: red row, line with [Choose]', (
        tester,
      ) async {
        final host = TranslateHost(
          services: const TranslateServices(all: [google, gemini]),
        );
        await host.turnOn();
        host.setView(
          const TranslationView(
            status: TranslationStatus.failed(TranslationFailure.noService()),
          ),
        );
        await host.open(tester, size: size);
        expect(find.text('No service chosen'), findsOneWidget);
        expect(find.text('No translation service chosen'), findsOneWidget);
        expect(
          find.text('The lyrics are sent only after you choose'),
          findsOneWidget,
        );
        // No bar: nothing can be translated again.
        expect(find.text('Translate again'), findsNothing);
        await tester.tap(find.widgetWithText(KModalButton, 'Choose'));
        await tester.pumpAndSettle();
        expect(find.text('Translation service'), findsOneWidget);
      });

      testWidgets('the chosen plugin was removed', (tester) async {
        final host = TranslateHost(
          services: const TranslateServices(all: [google], gone: true),
        );
        await host.turnOn();
        host.setView(
          const TranslationView(
            status: TranslationStatus.failed(TranslationFailure.noService()),
          ),
        );
        await host.open(tester, size: size);
        expect(
          find.text('The default service was removed, choose another'),
          findsOneWidget,
        );
        expect(
          find.text('The translation service was removed'),
          findsOneWidget,
        );
        expect(
          find.text('Choose another service to keep translating'),
          findsOneWidget,
        );
      });

      testWidgets('no translate plugin: the card leads to the store', (
        tester,
      ) async {
        final host = TranslateHost(services: const TranslateServices(all: []));
        await host.turnOn();
        await host.open(tester, size: size);
        expect(find.text('No translation plugin yet'), findsOneWidget);
        expect(find.text('Default for every song'), findsNothing);
        await tester.tap(find.text('Open plugin store'));
        await tester.pumpAndSettle();
        expect(host.location, '/settings/plugins?kind=translate');
        expect(find.text('Translate lyrics'), findsNothing);
      });

      testWidgets('same language: the line says so', (tester) async {
        final host = TranslateHost();
        await host.turnOn();
        host.setView(
          const TranslationView(
            status: TranslationStatus.same('vi'),
            sourceLang: 'vi',
            installId: 'google',
          ),
        );
        await host.open(tester, size: size);
        expect(
          find.text(
            'The lyrics already are in Vietnamese (per Google Translate)',
          ),
          findsOneWidget,
        );
        expect(find.text('Vietnamese · detected'), findsOneWidget);
      });

      testWidgets('running: counts, and Cancel only for a forced run', (
        tester,
      ) async {
        final host = TranslateHost();
        await host.turnOn();
        host.setView(
          const TranslationView(
            status: TranslationStatus.loading(1, 3),
            linesDone: 12,
            linesTotal: 24,
          ),
        );
        await host.open(tester, size: size);
        expect(find.text('Translating… 12/24 lines'), findsOneWidget);
        expect(find.text('Cancel'), findsNothing);
        host.setView(
          _ready().copyOf(
            status: const TranslationStatus.loading(1, 3, background: true),
            linesDone: 12,
            linesTotal: 24,
          ),
        );
        await tester.pump();
        expect(find.text('Translating again… 12/24 lines'), findsOneWidget);
        expect(
          find.text('Translating again, the old translation stays'),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(KModalButton, 'Cancel'));
        await tester.pump();
        expect(host.calls, ['cancel']);
      });

      testWidgets('half done: counts, the reason and [Try again]', (
        tester,
      ) async {
        final host = TranslateHost();
        await host.turnOn();
        host.setView(
          const TranslationView(
            status: TranslationStatus.failed(TranslationFailure.network()),
            map: {'Line 0': 'Dòng 0'},
            installId: 'google',
            linesDone: 6,
            linesTotal: 16,
          ),
        );
        host.setCredit(
          const TranslationCredit(
            plugin: 'Google Translate',
            target: 'vi',
            linesDone: 6,
            linesTotal: 16,
          ),
        );
        await host.open(tester, size: size);
        expect(find.text('Only 6/16 lines translated'), findsOneWidget);
        expect(
          find.text('The rest failed: cannot reach Google Translate'),
          findsOneWidget,
        );
        expect(
          find.text('Translated by Google Translate · 6/16 lines only'),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(KModalButton, 'Try again'));
        expect(host.calls, ['retry']);
      });

      for (final (name, failure, title, line, buttons) in [
        (
          'paused',
          TranslationFailure.rateLimited(DateTime(2026, 11, 24, 21, 5)),
          'Google Translate is paused',
          'The server reports too many requests (429) · Kanaru translates again after 9:05 PM',
          <String>[],
        ),
        (
          'network',
          const TranslationFailure.network(),
          'Cannot reach Google Translate',
          'Network error or timeout',
          ['Try again'],
        ),
        (
          'server',
          const TranslationFailure.server(),
          'Google Translate has an error',
          'The service\'s server returned an error',
          ['Try again'],
        ),
        (
          'quota',
          const TranslationFailure.quota(),
          'Google Translate is out of quota',
          'This API key has no translations left · wait for the next period or change service',
          ['Change service'],
        ),
        (
          'bad key',
          const TranslationFailure.badKey(),
          'Google Translate reports an error',
          'The API key is invalid or expired',
          ['Set up', 'Try again'],
        ),
        (
          'needs config',
          const TranslationFailure.needsConfig(['API key', 'Region']),
          'Google Translate needs to be set up',
          'Missing: API key, Region',
          ['Set up'],
        ),
        (
          'invalid',
          const TranslationFailure.invalidResponse(),
          'The translation has the wrong number of lines',
          'Google Translate returned a different number of lines than the lyrics',
          ['Try again', 'Change service'],
        ),
        (
          'too long',
          const TranslationFailure.tooLong(),
          'The lyrics are too long to translate',
          'The lyrics exceed what Google Translate translates in one run',
          ['Change service'],
        ),
        (
          'unsupported',
          const TranslationFailure.unsupportedLanguage('mi'),
          'Google Translate does not translate into Māori',
          'Choose another language or change service',
          ['Change service'],
        ),
      ]) {
        testWidgets('failure: $name', (tester) async {
          final host = TranslateHost();
          await host.turnOn();
          host.setView(
            TranslationView(status: TranslationStatus.failed(failure)),
          );
          await host.open(tester, size: size);
          expect(find.text(title), findsOneWidget);
          expect(find.text(line), findsOneWidget);
          for (final label in buttons) {
            expect(find.widgetWithText(KModalButton, label), findsOneWidget);
          }
          expect(find.byType(KModalButton), findsNWidgets(buttons.length));
        });
      }

      testWidgets('long names at 200 % text do not overflow', (tester) async {
        const long = TranslateService(
          installId: 'long',
          name: 'Dịch vụ dịch thuật trí tuệ nhân tạo có tên rất dài để thử cắt chữ',
          ai: true,
        );
        final host = TranslateHost(
          services: const TranslateServices(all: [long], current: long),
          tune: tuneOf(),
        );
        await host.turnOn();
        host.setView(
          const TranslationView(
            status: TranslationStatus.failed(TranslationFailure.badKey()),
          ),
        );
        await host.open(tester, size: size, textScale: 2);
        expect(tester.takeException(), isNull);
        expect(find.text('Set up'), findsOneWidget);
      });
    });
  }

  testWidgets('desktop keeps the dialog at 440 dp', (tester) async {
    final host = TranslateHost();
    await host.turnOn();
    await host.open(tester, size: const Size(1400, 900));
    expect(
      tester.getSize(find.byType(Dialog)).width,
      lessThanOrEqualTo(KLayout.dialog),
    );
  });

  testWidgets('392 dp phone: both halves fit without an overflow', (
    tester,
  ) async {
    final host = TranslateHost();
    await host.turnOn();
    host.setView(_ready(source: 'ja'));
    await host.open(tester, size: const Size(392, 800));
    expect(tester.takeException(), isNull);
    // Equal halves: the target may ellipsize when it does not fit its half
    // (the test font is far wider than the real one).
    expect(find.text('Japanese · detected'), findsOneWidget);
    expect(find.text('Vietnamese'), findsOneWidget);
  });
}

extension on TranslationView {
  TranslationView copyOf({
    TranslationStatus? status,
    String? installId,
    int? linesDone,
    int? linesTotal,
  }) => TranslationView(
    status: status ?? this.status,
    map: map,
    sourceLang: sourceLang,
    installId: installId ?? this.installId,
    settingsDiffer: settingsDiffer,
    settingsJson: settingsJson,
    linesDone: linesDone ?? this.linesDone,
    linesTotal: linesTotal ?? this.linesTotal,
  );
}
