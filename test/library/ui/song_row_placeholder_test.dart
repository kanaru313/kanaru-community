import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/ui/songs/song_row_placeholder.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(WidgetTester tester, Size size, Widget row) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildKanaruTheme(brightness: Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(alignment: Alignment.topCenter, child: row),
      ),
    ),
  );
}

void main() {
  const mobile = Size(400, 800);
  const desktop = Size(1300, 800);

  testWidgets('placeholder is a loading media card of the row extent', (
    tester,
  ) async {
    final extent = KMediaCard.extentOf(TextScaler.noScaling);
    await _pump(tester, mobile, SongRowPlaceholder(extent: extent));
    expect(tester.widget<KMediaCard>(find.byType(KMediaCard)).loading, isTrue);
    expect(
      tester.getSize(find.byType(KMediaCard)).height,
      closeTo(extent, 0.5),
    );
  });

  testWidgets('failed row is flat on mobile: no fill, no radius', (
    tester,
  ) async {
    final extent = KMediaCard.extentOf(TextScaler.noScaling);
    var retried = false;
    await _pump(
      tester,
      mobile,
      SongRowFailed(extent: extent, onRetry: () => retried = true),
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(SongRowFailed),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((box.decoration as BoxDecoration).color, isNull);
    expect((box.decoration as BoxDecoration).borderRadius, isNull);
    expect(
      tester.getSize(find.byType(SongRowFailed)).height,
      closeTo(extent, 0.5),
    );
    await tester.tap(find.byType(TextButton));
    expect(retried, isTrue);
  });

  testWidgets('failed row is a rounded card on desktop', (tester) async {
    await _pump(
      tester,
      desktop,
      SongRowFailed(
        extent: KMediaCard.extentOf(TextScaler.noScaling),
        onRetry: () {},
      ),
    );
    final box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(SongRowFailed),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((box.decoration as BoxDecoration).borderRadius, isNotNull);
  });
}
