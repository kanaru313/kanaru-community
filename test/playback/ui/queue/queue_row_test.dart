import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/ui/queue/queue_list.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row.dart';
import 'package:kanaru/src/playback/ui/queue/queue_row_hooks.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'queue_test_support.dart';

Color? _background(WidgetTester tester, Finder row) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: row, matching: find.byType(DecoratedBox)).first,
  );
  return (box.decoration as BoxDecoration).color;
}

void main() {
  Future<void> pump(
    WidgetTester tester, {
    bool playing = true,
    QueueRowSize size = QueueRowSize.mobile,
  }) => pumpFakeQueue(
    tester,
    QueueList(size: size),
    view: fakeView(6, current: 2),
    playing: playing,
  );

  testWidgets('current row is tonal with the equalizer on the cover', (
    tester,
  ) async {
    await pump(tester);
    final scheme = Theme.of(tester.element(find.byType(QueueList))).colorScheme;
    final rows = find.byType(QueueRow);
    expect(_background(tester, rows.at(2)), scheme.secondaryContainer);
    expect(_background(tester, rows.at(3)), isNull);
    expect(
      find.descendant(of: rows.at(2), matching: find.byType(KEqualizerIcon)),
      findsOneWidget,
    );
    expect(find.byType(KEqualizerIcon), findsOneWidget);
    expect(
      tester.widget<KEqualizerIcon>(find.byType(KEqualizerIcon)).playing,
      isTrue,
    );
  });

  testWidgets('a paused current row shows the pause glyph', (tester) async {
    await pump(tester, playing: false);
    expect(
      tester.widget<KEqualizerIcon>(find.byType(KEqualizerIcon)).playing,
      isFalse,
    );
    expect(find.byIcon(KIcons.pause), findsOneWidget);
  });

  testWidgets('played rows are at half opacity, the others are not', (
    tester,
  ) async {
    await pump(tester);
    double opacityOf(int i) {
      final o = find.descendant(
        of: find.byType(QueueRow).at(i),
        matching: find.byType(Opacity),
      );
      return tester.widget<Opacity>(o.first).opacity;
    }

    expect(opacityOf(0), 0.5);
    expect(opacityOf(1), 0.5);
    expect(opacityOf(2), 1);
    expect(opacityOf(4), 1);
    // The background of a played row is unchanged.
    expect(_background(tester, find.byType(QueueRow).at(0)), isNull);
  });

  testWidgets('desktop rows are 72 tall and show album and year', (
    tester,
  ) async {
    await pump(tester, size: QueueRowSize.desktop);
    expect(tester.getSize(find.byType(QueueRow).first).height, 72);
    expect(find.text('Album • 2020'), findsWidgets);
  });

  testWidgets('mobile rows are 60 tall with a 48 dp handle', (tester) async {
    await pump(tester);
    expect(tester.getSize(find.byType(QueueRow).first).height, 60);
    final handle = find.byType(ReorderableDragStartListener).first;
    expect(tester.getSize(handle), const Size.square(48));
  });

  testWidgets('a row without its info shows a placeholder of the same height', (
    tester,
  ) async {
    final loader = CountingLoader();
    await pumpFakeQueue(
      tester,
      const QueueList(size: QueueRowSize.mobile),
      view: fakeView(3, current: 0),
      loader: loader,
    );
    expect(tester.getSize(find.byType(QueueRow).first).height, 60);
  });
}
