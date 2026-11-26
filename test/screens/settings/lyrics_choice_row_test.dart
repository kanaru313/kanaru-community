import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/platform/domain/setting.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/screens/settings/ui/lyrics/lyrics_choice_row.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/memory_settings_store.dart';

final _setting = Setting<String>(
  'test.choice',
  'a',
  decode: (json) => json as String,
  encode: (v) => v,
);
final _provider = settingNotifierProvider(_setting);

Future<MemorySettingsStore> _pump(
  WidgetTester tester, {
  Future<bool> Function(String value)? confirm,
}) async {
  final store = MemorySettingsStore();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [settingsStoreProvider.overrideWithValue(store)],
      child: MaterialApp(
        theme: buildKanaruTheme(brightness: Brightness.light),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LyricsChoiceRow<String>(
            icon: KIcons.settings,
            title: 'Pick',
            provider: _provider,
            confirm: confirm,
            choices: const [
              LyricsChoice('a', 'Alpha'),
              LyricsChoice('b', 'Beta', icon: KIcons.bolt),
            ],
          ),
        ),
      ),
    ),
  );
  return store;
}

void main() {
  testWidgets('confirm false keeps the old value and the picker open', (
    tester,
  ) async {
    final asked = <String>[];
    final store = await _pump(
      tester,
      confirm: (v) async {
        asked.add(v);
        return false;
      },
    );
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(asked, ['b']);
    expect(store.read('test.choice'), isNull);
    // The picker is still there (its title and both options).
    expect(find.text('Alpha'), findsWidgets);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('confirm true applies the choice', (tester) async {
    final store = await _pump(tester, confirm: (v) async => true);
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(store.read('test.choice'), 'b');
  });

  testWidgets('without confirm a tap chooses and closes', (tester) async {
    final store = await _pump(tester);
    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beta'));
    await tester.pumpAndSettle();
    expect(store.read('test.choice'), 'b');
    expect(find.text('Alpha'), findsNothing);
  });
}
