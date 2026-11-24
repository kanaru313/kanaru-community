import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_status.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_services_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_tune_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_view.dart';
import 'package:kanaru/src/plugins/data/store/plugin_config_store.dart'
    show ConfigWrite;
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'translate_modal_host.dart';

/// The segment [label] as a screen reader sees it: enabled or not.
bool _segmentEnabled(WidgetTester tester, String label) => isSemantics(
  hasEnabledState: true,
  isEnabled: true,
).matches(tester.getSemantics(find.bySemanticsLabel(label)), {});

bool _segmentSelected(WidgetTester tester, String label) =>
    isSemantics(isSelected: true)
        .matches(tester.getSemantics(find.bySemanticsLabel(label)), {});

Future<TranslateHost> _openService(
  WidgetTester tester, {
  Size size = const Size(400, 800),
}) async {
  final host = TranslateHost(tune: tuneOf());
  await host.turnOn();
  await host.open(tester, size: size);
  await tester.tap(find.text('Google Translate').first);
  await host.settle(tester);
  return host;
}

/// The sheet scrolls when the bar and the rows do not fit.
Future<void> _tapTuneRow(WidgetTester tester, TranslateHost host) async {
  await tester.ensureVisible(find.text('AI tuning'));
  await tester.pump();
  await tester.tap(find.text('AI tuning'));
  await host.settle(tester);
}

Future<TranslateHost> _openTune(
  WidgetTester tester, {
  TranslateTune? tune,
  bool differ = false,
}) async {
  final host = TranslateHost(tune: tune ?? tuneOf());
  host.setServices(
    const TranslateServices(all: [google, gemini], current: gemini),
  );
  await host.turnOn();
  host.setView(
    TranslationView(
      status: const TranslationStatus.ready(),
      map: const {'Line 1': 'Dòng 1'},
      installId: 'gemini',
      settingsDiffer: differ,
    ),
  );
  await host.open(tester);
  await _tapTuneRow(tester, host);
  return host;
}

void main() {
  group('service page', () {
    testWidgets(
      'ⓘ on the title, Pro lock on "Apply to", services as icon rows',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _openService(tester);
        // The sentence sits behind the ⓘ of the title, not as a visible line.
        expect(
          find.text(
            'Lyrics, song title and artist are sent to the plugin when translating.',
          ),
          findsNothing,
        );
        expect(find.byType(KHelpIcon), findsOneWidget);
        expect(find.text('Apply to'), findsOneWidget);
        // Free: always "Every song"; the Pro tag and its caption say why.
        expect(_segmentSelected(tester, 'Every song'), isTrue);
        expect(find.byType(ProBadge), findsOneWidget);
        expect(
          find.textContaining('A service of its own for a song or the queue'),
          findsOneWidget,
        );
        await tester.tap(find.text('This song'));
        await tester.pump();
        expect(_segmentSelected(tester, 'This song'), isFalse);
        expect(_segmentSelected(tester, 'Every song'), isTrue);
        // The chosen service is selected; the AI one carries its tag.
        expect(isSelectedRow(tester, 'Google Translate'), isTrue);
        expect(isSelectedRow(tester, 'Gemini Translate'), isFalse);
        expect(find.text('AI'), findsOneWidget);
        expect(find.text('Get more translation plugins'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets('"This song" and "Queue" are disabled, "Every song" is not', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _openService(tester);
      expect(_segmentEnabled(tester, 'This song'), isFalse);
      expect(_segmentEnabled(tester, 'Queue'), isFalse);
      expect(_segmentEnabled(tester, 'Every song'), isTrue);
      handle.dispose();
    });

    testWidgets('choosing a service saves it and closes the page', (
      tester,
    ) async {
      final host = await _openService(tester);
      await tester.tap(find.text('Gemini Translate'));
      await host.settle(tester);
      expect(host.container.read(translationServiceProvider), 'gemini');
      expect(find.text('Translation service'), findsNothing);
      expect(find.text('Translate lyrics'), findsOneWidget);
    });

    testWidgets('"Get more translation plugins" opens the store', (
      tester,
    ) async {
      final host = await _openService(tester);
      await tester.tap(find.text('Get more translation plugins'));
      await host.settle(tester);
      expect(host.location, '/settings/plugins?kind=translate');
      expect(find.text('Translation service'), findsNothing);
      expect(find.text('Translate lyrics'), findsNothing);
    });
  });

  group('target page', () {
    Future<TranslateHost> open(WidgetTester tester) async {
      final host = TranslateHost();
      await host.turnOn();
      await host.open(tester);
      await tester.tap(find.bySemanticsLabel('Translate into Vietnamese'));
      await host.settle(tester);
      return host;
    }

    testWidgets('the target is chosen; the app language says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      expect(find.text('Translate into'), findsOneWidget);
      expect(isSelectedRow(tester, 'Vietnamese'), isTrue);
      expect(isSelectedRow(tester, 'English'), isFalse);
      // The app language of the test is English.
      expect(find.text('Follows the app language'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('choosing writes the song’s language and closes', (
      tester,
    ) async {
      final host = await open(tester);
      await tester.tap(find.text('Japanese'));
      await host.settle(tester);
      expect(host.calls, ['target:ja']);
      expect(find.text('Translate into'), findsNothing);
      expect(find.text('Translate lyrics'), findsOneWidget);
      expect(find.bySemanticsLabel('Translate into Japanese'), findsOneWidget);
    });

    testWidgets('a refused write keeps the page open with a line', (
      tester,
    ) async {
      final host = await open(tester);
      host.targetOk = false;
      await tester.tap(find.text('Japanese'));
      await host.settle(tester);
      expect(find.text('Could not save the language'), findsOneWidget);
      expect(find.text('Translate into'), findsOneWidget);
    });
  });

  group('AI tuning page', () {
    testWidgets('model and style fields, the note and its helper', (
      tester,
    ) async {
      await _openTune(tester, tune: tuneOf(note: 'Use anh/em'));
      expect(find.text('Model 0'), findsOneWidget);
      expect(find.text('About 0'), findsOneWidget);
      expect(find.text('default'), findsNWidgets(2));
      expect(find.text('Natural'), findsOneWidget);
      expect(find.text('Use anh/em'), findsOneWidget);
      expect(
        find.text(
          'Extra instructions for every song (saved in the settings of Gemini Translate).',
        ),
        findsOneWidget,
      );
      // Nothing differs: a single button.
      expect(find.widgetWithText(KModalButton, 'Done'), findsOneWidget);
      expect(find.widgetWithText(KModalButton, 'Later'), findsNothing);
    });

    testWidgets('a model is chosen through the select', (tester) async {
      final host = await _openTune(tester);
      await tester.tap(find.text('Model 0'));
      await host.settle(tester);
      expect(find.text('Model 1'), findsOneWidget);
      // Three options: no search box.
      expect(find.text('Search 3 items'), findsNothing);
      await tester.tap(find.text('Model 1'));
      await host.settle(tester);
      expect(host.calls, ['model:m1']);
      expect(find.text('Model 1'), findsNothing);
    });

    testWidgets('over 8 options the select can be searched', (tester) async {
      final host = await _openTune(
        tester,
        tune: tuneOf(model: modelField(count: 12)),
      );
      await tester.tap(find.text('Model 0'));
      await host.settle(tester);
      expect(find.text('Search 12 items'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byType(KFilterField),
          matching: find.byType(TextField),
        ),
        'model 11',
      );
      await tester.pump();
      expect(find.text('Model 11'), findsOneWidget);
      expect(find.text('Model 3'), findsNothing);
    });

    testWidgets('a searched pick saves, and the picker leaves without errors', (
      tester,
    ) async {
      final host = await _openTune(
        tester,
        tune: tuneOf(model: modelField(count: 12)),
      );
      await tester.tap(find.text('Model 0'));
      await host.settle(tester);
      await tester.enterText(
        find.descendant(
          of: find.byType(KFilterField),
          matching: find.byType(TextField),
        ),
        'model 11',
      );
      await tester.pump();
      await tester.tap(find.text('Model 11'));
      // Frame by frame through the exit: the search box is still mounted
      // while the route slides out and must not read a disposed controller.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await host.settle(tester);
      expect(host.calls, ['model:m11']);
      expect(find.byType(KFilterField), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a value of the user’s own is shown', (tester) async {
      await _openTune(tester, tune: tuneOf(modelValue: 'my-own-model'));
      expect(find.text('my-own-model'), findsOneWidget);
    });

    testWidgets('a refused model write shows its error line', (tester) async {
      final host = await _openTune(tester);
      host.write = ConfigWrite.invalidValue;
      await tester.tap(find.text('Model 0'));
      await host.settle(tester);
      await tester.tap(find.text('Model 2'));
      await host.settle(tester);
      expect(host.calls, ['model:m2']);
      expect(find.text('The value is not valid'), findsOneWidget);
    });

    testWidgets('the note is saved for every song when done', (tester) async {
      final host = await _openTune(tester);
      await tester.enterText(find.byType(TextField), 'Giữ tên riêng');
      await tester.tap(find.widgetWithText(KModalButton, 'Done'));
      await host.settle(tester);
      expect(host.calls, ['note:Giữ tên riêng']);
      expect(find.text('Extra instructions'), findsNothing);
      expect(find.text('AI tuning'), findsOneWidget);
    });

    testWidgets('a refused note keeps the page with its error', (tester) async {
      final host = await _openTune(tester);
      host.write = ConfigWrite.tooLarge;
      await tester.enterText(find.byType(TextField), 'x');
      await tester.tap(find.widgetWithText(KModalButton, 'Done'));
      await host.settle(tester);
      expect(find.text('The instructions are too long'), findsOneWidget);
      expect(find.widgetWithText(KModalButton, 'Done'), findsOneWidget);
    });

    testWidgets('closing with the note typed saves it', (tester) async {
      final host = await _openTune(tester);
      await tester.enterText(find.byType(TextField), 'ghi nhớ');
      await tester.tap(
        find
            .byWidgetPredicate((w) => w is KIconButton && w.tooltip == 'Close')
            .last,
      );
      await host.settle(tester);
      expect(host.calls, ['note:ghi nhớ']);
    });

    testWidgets('settings differ: Later closes the page, Translate again '
        'runs in the background', (tester) async {
      final host = await _openTune(tester, differ: true);
      expect(find.widgetWithText(KModalButton, 'Done'), findsNothing);
      await tester.tap(find.widgetWithText(KModalButton, 'Later'));
      await host.settle(tester);
      expect(host.calls, isEmpty);
      expect(find.text('Translate lyrics'), findsOneWidget);
      await _tapTuneRow(tester, host);
      // The modal's own bar is under the page; the page's button is on top.
      await tester.tap(
        find.widgetWithText(KModalButton, 'Translate again').last,
      );
      await host.settle(tester);
      expect(host.calls, ['retranslate']);
      // The page is gone; the modal stays on its main page.
      // Only the modal's own tuning row is left.
      expect(find.text('AI tuning'), findsOneWidget);
      expect(find.text('Translate lyrics'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });
  });
}
