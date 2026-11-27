import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../settings/support/settings_host.dart' show SettingsHarness;
import '../support/page_fixtures.dart';
import '../support/plugin_fixtures.dart';

Future<SettingsHarness> _open(WidgetTester tester, {required String kind}) =>
    pumpPlugins(
      tester,
      StoreFixture(),
      location: pagePath,
      size: const Size(400, 2400),
      overrides: pageOverrides(AsyncData(pageData(row: pageRow(kind: kind)))),
    );

void main() {
  testWidgets('ai-chat plugin page shows the use row', (tester) async {
    final h = await _open(tester, kind: 'ai-chat');
    expect(find.text('Use in AI chat'), findsOneWidget);
    expect(
      find.text(
        'Pick it in the chat input; new chats use the service picked last.',
      ),
      findsOneWidget,
    );
    expect(find.text('Change in Settings › AI chat'), findsOneWidget);
    await tester.tap(find.text('Use in AI chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      h.router.routerDelegate.currentConfiguration.last.matchedLocation,
      '/settings/ai',
    );
  });

  for (final kind in ['lyrics', 'translate', 'streaming']) {
    testWidgets('other kinds do not ($kind)', (tester) async {
      await _open(tester, kind: kind);
      expect(find.text('Use in AI chat'), findsNothing);
    });
  }
}
