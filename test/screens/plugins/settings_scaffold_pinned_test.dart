import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/platform/state/settings_save_status_provider.dart';
import 'package:kanaru/src/screens/settings/ui/settings_scaffold.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

Widget _app({Widget? pinned}) => ProviderScope(
  overrides: [
    settingsSaveFailingProvider.overrideWith((ref) => Stream.value(false)),
  ],
  child: MaterialApp(
    theme: buildKanaruTheme(brightness: Brightness.light),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SettingsScaffold(
        title: 'Kho plugin',
        pinnedBelowHeader: pinned,
        children: [
          for (var i = 0; i < 40; i++)
            SizedBox(height: 60, child: Text('row $i')),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('without a pinned widget the header scrolls with the page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app());
    await tester.pump();
    expect(find.text('Kho plugin'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pump();
    expect(find.text('Kho plugin'), findsNothing);
  });

  testWidgets('pinned widget and header stay while the body scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(pinned: const Text('PINNED')));
    await tester.pump();
    final before = tester.getTopLeft(find.text('PINNED'));
    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pump();
    expect(find.text('Kho plugin'), findsOneWidget);
    expect(find.text('PINNED'), findsOneWidget);
    expect(tester.getTopLeft(find.text('PINNED')), before);
    expect(find.text('row 0'), findsNothing);
  });

  testWidgets('a header builder replaces the header and stays fixed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    VoidCallback? back;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsSaveFailingProvider.overrideWith(
            (ref) => Stream.value(false),
          ),
        ],
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SettingsScaffold(
              title: 'unused',
              parentPath: '/up',
              headerBuilder: (context, onBack) {
                back = onBack;
                return const Text('CUSTOM HEADER');
              },
              children: [
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 60, child: Text('row $i')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('unused'), findsNothing);
    expect(back, isNotNull, reason: 'a page with a parent gets a back action');
    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pump();
    expect(find.text('CUSTOM HEADER'), findsOneWidget);
    expect(find.text('row 0'), findsNothing);
  });
}
