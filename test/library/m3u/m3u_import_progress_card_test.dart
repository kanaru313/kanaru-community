import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/data/m3u/m3u_results.dart';
import 'package:kanaru/src/library/state/m3u/m3u_import_progress.dart';
import 'package:kanaru/src/library/ui/m3u/m3u_import_progress_card.dart';
import 'package:material_ui/material_ui.dart';

M3uImportProgress _p(int done, int? total) =>
    M3uImportProgress(fileName: 'Road.m3u8', done: done, total: total);

Future<ProviderContainer> _pump(
  WidgetTester t, {
  String locale = 'en',
  double width = 400,
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 800);
  addTearDown(t.view.reset);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        home: const Scaffold(body: M3uImportProgressCard()),
      ),
    ),
  );
  return container;
}

void main() {
  testWidgets('hidden before begin and during the first second', (t) async {
    final c = await _pump(t);
    expect(find.textContaining('Road'), findsNothing);
    final n = c.read(m3uImportProgressProvider.notifier)..begin('Road.m3u8');
    await t.pump(const Duration(milliseconds: 900));
    expect(find.textContaining('Road'), findsNothing);
    n.end();
    await t.pump();
    expect(find.textContaining('Road'), findsNothing);
  });

  testWidgets('title only, no count, while total is unknown', (t) async {
    final c = await _pump(t);
    final n = c.read(m3uImportProgressProvider.notifier)..begin('Road.m3u8');
    n.update(_p(0, null));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Importing Road.m3u8'), findsOneWidget);
    expect(find.textContaining('lines'), findsNothing);
    expect(find.textContaining('/'), findsNothing);
    n.end();
    await t.pump();
  });

  testWidgets('N / M lines once total is known', (t) async {
    final c = await _pump(t);
    final n = c.read(m3uImportProgressProvider.notifier)..begin('Road.m3u8');
    await t.pump(const Duration(seconds: 1));
    n.update(_p(6, 10));
    await t.pump();
    expect(find.text('6 / 10 lines'), findsOneWidget);
    n.end();
    await t.pump();
    expect(find.text('Importing Road.m3u8'), findsNothing);
  });

  testWidgets('an empty file (total 0) shows 0 / 0 without dividing', (
    t,
  ) async {
    final c = await _pump(t);
    final n = c.read(m3uImportProgressProvider.notifier)..begin('Road.m3u8');
    n.update(_p(0, 0));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('0 / 0 lines'), findsOneWidget);
    n.end();
    await t.pump();
  });

  testWidgets('Vietnamese text', (t) async {
    final c = await _pump(t, locale: 'vi');
    final n = c.read(m3uImportProgressProvider.notifier)..begin('Road.m3u8');
    n.update(_p(1200, 5000));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Đang nhập Road.m3u8'), findsOneWidget);
    expect(find.text('1.200 / 5.000 dòng'), findsOneWidget);
    n.end();
    await t.pump();
  });

  for (final (width, scale, anim) in [
    (360.0, 1.5, false),
    (360.0, 2.0, true),
    (1280.0, 2.0, false),
  ]) {
    testWidgets('no overflow at $width px, $scale x text, '
        'animations ${anim ? 'off' : 'on'}', (t) async {
      final c = await _pump(
        t,
        width: width,
        textScale: scale,
        disableAnimations: anim,
      );
      final n = c.read(m3uImportProgressProvider.notifier)
        ..begin('A very long playlist file name for a road trip 2026.m3u8');
      n.update(_p(5, 10));
      await t.pump(const Duration(seconds: 1));
      expect(find.textContaining('A very long'), findsOneWidget);
      expect(t.takeException(), isNull);
      n.end();
      await t.pump();
    });
  }
}
