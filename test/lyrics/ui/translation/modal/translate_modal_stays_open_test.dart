import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_services_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_failure.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_status.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_credit_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_view.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'translate_modal_host.dart';

const _failed = TranslationView(
  status: TranslationStatus.failed(TranslationFailure.network()),
);

/// A run that fails never closes the modal: its status line says so.
void main() {
  aiTagTests();
  testWidgets('switch on, the run fails: the modal stays with the error', (
    tester,
  ) async {
    final host = TranslateHost();
    await host.turnOn(false);
    await host.open(tester);
    await tester.tap(find.byType(KSwitch));
    await host.settle(tester);
    host.setView(_failed);
    await host.settle(tester);
    expect(find.text('Translate lyrics'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('a service picked, the run fails: back on the main page with '
      'the error', (tester) async {
    final host = TranslateHost();
    await host.turnOn();
    await host.open(tester);
    await tester.tap(find.text('Google Translate').first);
    await host.settle(tester);
    await tester.tap(find.text('Gemini Translate'));
    await host.settle(tester);
    host.setView(_failed);
    await host.settle(tester);
    expect(find.text('Translation service'), findsNothing);
    expect(find.text('Translate lyrics'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Translate again keeps the modal open', (tester) async {
    final host = TranslateHost();
    await host.turnOn();
    host.setView(
      const TranslationView(
        status: TranslationStatus.ready(),
        map: {'Line 1': 'Dòng 1'},
        installId: 'google',
      ),
    );
    host.setCredit(
      const TranslationCredit(plugin: 'Google Translate', target: 'vi'),
    );
    await host.open(tester);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is KIconButton && w.tooltip == 'Translate again',
      ),
    );
    await host.settle(tester);
    expect(host.calls, ['retranslate']);
    host.setView(_failed);
    await host.settle(tester);
    expect(find.text('Translate lyrics'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });
}

void aiTagTests() {
  testWidgets('the AI tag of the chosen service keeps a visible fill', (
    tester,
  ) async {
    final host = TranslateHost();
    host.setServices(
      const TranslateServices(all: [google, gemini], current: gemini),
    );
    await host.turnOn();
    await host.open(tester);
    await tester.tap(find.text('Gemini Translate').first);
    await host.settle(tester);
    final scheme = Theme.of(tester.element(find.text('Translation service')))
        .colorScheme;
    final fill = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('AI').last,
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((fill.decoration as BoxDecoration).color, scheme.primary);
  });
}
