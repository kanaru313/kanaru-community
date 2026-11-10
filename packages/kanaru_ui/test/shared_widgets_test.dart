import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

void main() {
  for (final (name, brightness, scale) in hostVariants) {
    testWidgets('KListRow, KChip render without overflow ($name)', (tester) async {
      useWindow(tester, const Size(360, 800));
      await tester.pumpWidget(host(
        const Column(children: [
          KListRow(
            leading: Icon(KIcons.settings),
            title: Text('A long settings title that should wrap or ellipsize safely'),
            subtitle: Text('detail'),
            trailing: Icon(KIcons.chevronRight),
          ),
          KChip(label: Text('Go to'), icon: Icon(KIcons.folders), selected: true),
        ]),
        brightness: brightness,
        textScale: scale,
      ));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(KListRow)).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(find.byType(KChip)).height, greaterThanOrEqualTo(48));
    });
  }

  testWidgets('disabled KListRow is dimmed and inert', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(KListRow(
      title: const Text('Soon'),
      enabled: false,
      onTap: () => taps++,
    )));
    await tester.tap(find.text('Soon'));
    expect(taps, 0);
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, lessThan(1));
  });

  testWidgets('KChip taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(KChip(label: const Text('c'), onTap: () => taps++)));
    await tester.tap(find.text('c'));
    expect(taps, 1);
  });

  testWidgets('confirmAction: confirm true, cancel false, scrim false', (tester) async {
    late Future<bool> result;
    await tester.pumpWidget(host(Builder(
      builder: (context) => TextButton(
        onPressed: () => result = confirmAction(
          context,
          title: 'Delete?',
          message: 'Gone',
          confirmLabel: 'Delete',
          destructive: true,
        ),
        child: const Text('go'),
      ),
    )));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await result, isTrue);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  testWidgets('showAppSnackBar shows message and action, replaces previous', (tester) async {
    var undone = 0;
    await tester.pumpWidget(host(Builder(
      builder: (context) => Column(children: [
        TextButton(
          onPressed: () => showAppSnackBar(context, 'first'),
          child: const Text('one'),
        ),
        TextButton(
          onPressed: () => showAppSnackBar(context, 'second',
              actionLabel: 'Undo', onAction: () => undone++),
          child: const Text('two'),
        ),
      ]),
    )));
    await tester.tap(find.text('one'));
    await tester.pump();
    await tester.tap(find.text('two'));
    await tester.pumpAndSettle();
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    expect(undone, 1);
  });

  testWidgets('PageHeaderScope appends trailing widgets to PageHeader', (tester) async {
    await tester.pumpWidget(host(const PageHeaderScope(
      trailing: [Icon(KIcons.search)],
      child: PageHeader(title: 'Songs'),
    )));
    expect(find.byIcon(KIcons.search), findsOneWidget);
    await tester.pumpWidget(host(const PageHeader(title: 'Songs')));
    expect(find.byIcon(KIcons.search), findsNothing);
  });

  testWidgets('KGap spaces siblings', (tester) async {
    await tester.pumpWidget(host(const Column(children: [Text('a'), KGap(KSpace.x4), Text('b')])));
    expect(tester.getTopLeft(find.text('b')).dy - tester.getBottomLeft(find.text('a')).dy, 16);
  });

  testWidgets('disabled KChip ignores taps and reports disabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(KChip(label: const Text('c'), enabled: false, onTap: () => taps++)));
    await tester.tap(find.text('c'), warnIfMissed: false);
    expect(taps, 0);
  });
}
