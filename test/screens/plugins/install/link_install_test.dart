import 'package:flutter/widgets.dart' show EditableText;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/screens/plugins/install/link_install_dialog.dart';

import '../support/install_fixtures.dart';

Future<FakeInstallOps> _open(WidgetTester tester, {required bool wide}) async {
  final ops = FakeInstallOps();
  await pumpFlowHost(
    tester,
    ops: ops,
    size: wide ? wideWindow : narrowWindow,
    onTap: (c) => installFromLink(c, ops),
  );
  return ops;
}

String _fieldText(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

void main() {
  test('only absolute http(s) addresses are links', () {
    expect(isPackageLink('https://x.example.com/a.zip'), isTrue);
    expect(isPackageLink('http://192.168.1.5:8000/a.zip'), isTrue);
    expect(isPackageLink('ftp://x.example.com/a.zip'), isFalse);
    expect(isPackageLink('not a link'), isFalse);
    expect(isPackageLink('/relative/a.zip'), isFalse);
  });

  test('a plugins.json address is a catalog link', () {
    expect(isCatalogLink('https://x.example.com/p/plugins.json'), isTrue);
    expect(isCatalogLink('https://x.example.com/p/PLUGINS.JSON?t=1'), isTrue);
    expect(isCatalogLink('https://x.example.com/a.zip'), isFalse);
  });

  for (final wide in [false, true]) {
    group(wide ? 'wide' : 'narrow', () {
      testWidgets(
        'the dialog asks for the link and explains nothing installs',
        (tester) async {
          await _open(tester, wide: wide);
          expect(find.text('Install from link'), findsOneWidget);
          expect(find.text('Link to the .zip package'), findsWidgets);
          expect(
            find.text(
              'Kanaru downloads the package and checks it, then shows the install screen. Nothing is installed until you tap Install.',
            ),
            findsOneWidget,
          );
          expect(find.text('Continue'), findsOneWidget);
        },
      );

      testWidgets('a bad address says so in place of the helper', (
        tester,
      ) async {
        final ops = await _open(tester, wide: wide);
        await tester.enterText(find.byType(EditableText), 'nonsense');
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(find.text('Invalid URL'), findsOneWidget);
        expect(
          find.textContaining('Kanaru downloads the package'),
          findsNothing,
        );
        expect(ops.prepared, isEmpty);
      });

      testWidgets('a good link opens the install screen for it', (
        tester,
      ) async {
        final ops = await _open(tester, wide: wide);
        await tester.enterText(
          find.byType(EditableText),
          '  https://plugins.example.org/nhac.zip ',
        );
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
        expect(ops.prepared, ['link:https://plugins.example.org/nhac.zip']);
        expect(find.text('Install Demo?'), findsOneWidget);
      });

      testWidgets('a plugins.json link offers to add a repository', (
        tester,
      ) async {
        final ops = await _open(tester, wide: wide);
        const url = 'https://raw.example.com/kanaru/plugins.json';
        await tester.enterText(find.byType(EditableText), url);
        await tester.pump();
        expect(
          find.text(
            'This is a plugin list (plugins.json), not a package. Add it as a repository?',
          ),
          findsOneWidget,
        );
        expect(find.text('Continue'), findsNothing);
        await tester.tap(find.text('Add repository'));
        await tester.pumpAndSettle();
        expect(ops.prepared, isEmpty);
        expect(find.text('Install from link'), findsNothing);
        // The add-repository dialog opens with the link already in its field.
        expect(_fieldText(tester), url);
      });
    });
  }
}
