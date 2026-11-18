import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/settings/settings_routes.dart';
import 'package:kanaru/src/screens/settings/state/app_edition.dart';

import 'support/settings_host.dart';

void main() {
  testWidgets('free edition: name, edition, licence, native libraries', (
    tester,
  ) async {
    await pumpSettings(tester, location: SettingsPaths.about);
    expect(find.text('Kanaru'), findsOneWidget);
    expect(find.text('Free edition'), findsOneWidget);
    expect(find.text('GPL-3.0-or-later'), findsOneWidget);
    expect(find.text('License'), findsOneWidget);
    expect(find.text('Open source licenses'), findsOneWidget);
    expect(find.text('Native libraries'), findsOneWidget);
    expect(find.text('bridge 0.1.0, media 0.1.0'), findsOneWidget);
  });

  testWidgets('pro override changes the edition line', (tester) async {
    await pumpSettings(
      tester,
      location: SettingsPaths.about,
      overrides: [appEditionProvider.overrideWithValue(AppEdition.pro)],
    );
    expect(find.text('Kanaru Pro'), findsOneWidget);
    expect(find.text('Free edition'), findsNothing);
  });

  testWidgets('the licences row opens the licence page', (tester) async {
    await pumpSettings(tester, location: SettingsPaths.about);
    await tester.tap(find.text('Open source licenses'));
    await tester.pumpAndSettle();
    expect(find.text('Licenses'), findsWidgets);
  });
}
