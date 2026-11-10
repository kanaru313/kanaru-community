import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/scan_status.dart';
import 'package:kanaru/src/library/state/scan/scan_capabilities.dart';
import 'package:kanaru/src/library/state/scan_providers.dart';
import 'package:kanaru/src/library/ui/scan/scan_card_state.dart';
import 'package:kanaru/src/library/ui/scan/scan_progress_card.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

final _t0 = DateTime(2026, 11, 10, 12);

class _Commands implements LibraryScanCommands, ScanOrigin {
  _Commands(this.lastFinishWasRequested);

  @override
  final bool lastFinishWasRequested;

  @override
  Future<void> rescan({bool full = false}) async {}
}

ScanFinished _finished({int tracks = 242, int added = 242, DateTime? at}) =>
    ScanFinished(
      tracks: tracks,
      albums: 186,
      artists: 142,
      added: added,
      at: at ?? _t0,
    );

void main() {
  late StreamController<ScanStatus> status;
  late DateTime now;

  setUp(() {
    status = StreamController<ScanStatus>();
    addTearDown(() => unawaited(status.close()));
    now = _t0;
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    double textScale = 1,
    bool requested = true,
    String locale = 'en',
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scanStatusProvider.overrideWith((ref) => status.stream),
          libraryScanCommandsProvider.overrideWithValue(_Commands(requested)),
        ],
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          locale: Locale(locale),
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(body: ScanProgressCard(now: () => now)),
        ),
      ),
    );
  }

  Future<void> emit(WidgetTester tester, ScanStatus s) async {
    status.add(s);
    await tester.pump();
    await tester.pump();
  }

  double? bar(WidgetTester tester) => tester
      .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
      .value;

  testWidgets('shows nothing before the first status and while idle', (
    tester,
  ) async {
    await pumpCard(tester);
    expect(find.byType(ProgressNoticeCard), findsNothing);
    await emit(tester, const ScanIdle());
    expect(find.byType(ProgressNoticeCard), findsNothing);
  });

  testWidgets('a status stream error shows nothing', (tester) async {
    await pumpCard(tester);
    status.addError(StateError('boom'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(ProgressNoticeCard), findsNothing);
  });

  testWidgets('listing, and a phase with no total, stay invisible', (
    tester,
  ) async {
    await pumpCard(tester);
    await emit(
      tester,
      const ScanRunning(phase: ScanPhase.listing, done: 0, total: 0),
    );
    expect(find.byType(ProgressNoticeCard), findsNothing);
    await emit(
      tester,
      const ScanRunning(phase: ScanPhase.tags, done: 0, total: 0),
    );
    expect(find.byType(ProgressNoticeCard), findsNothing);
    await emit(
      tester,
      const ScanRunning(phase: ScanPhase.covers, done: 0, total: 0),
    );
    expect(find.byType(ProgressNoticeCard), findsNothing);
  });

  testWidgets('tags fill the first half of the bar, covers the second', (
    tester,
  ) async {
    await pumpCard(tester);
    await emit(
      tester,
      const ScanRunning(phase: ScanPhase.tags, done: 120, total: 242),
    );
    expect(find.text('Scanning the library'), findsOneWidget);
    expect(find.text('Reading tags and covers · 120 / 242 songs'), findsOne);
    expect(bar(tester), closeTo(120 / 242 / 2, 1e-9));

    await emit(
      tester,
      const ScanRunning(phase: ScanPhase.covers, done: 0, total: 242),
    );
    expect(bar(tester), 0.5);

    await emit(
      tester,
      const ScanRunning(phase: ScanPhase.covers, done: 242, total: 242),
    );
    expect(bar(tester), 1.0);
  });

  testWidgets('a fresh scan that added tracks shows the summary, then hides '
      'after 4 s', (tester) async {
    await pumpCard(tester);
    await emit(tester, _finished());
    expect(find.text('Added 242 songs'), findsOneWidget);
    expect(find.text('186 albums · 142 artists'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Added 242 songs'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1, milliseconds: 1));
    expect(find.byType(ProgressNoticeCard), findsNothing);
  });

  testWidgets('a new announcement after the first one hid shows again', (
    tester,
  ) async {
    await pumpCard(tester);
    await emit(tester, _finished());
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(ProgressNoticeCard), findsNothing);

    now = _t0.add(const Duration(seconds: 5));
    await emit(tester, _finished(added: 3, at: now));
    expect(find.text('Added 3 songs'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(ProgressNoticeCard), findsNothing);
  });

  testWidgets('an empty library says so in text only, then hides', (
    tester,
  ) async {
    await pumpCard(tester);
    await emit(tester, _finished(tracks: 0, added: 0));
    expect(find.text('No songs found'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    expect(find.byType(ProgressNoticeCard), findsNothing);
  });

  testWidgets('an empty library found by the startup scan stays quiet', (
    tester,
  ) async {
    await pumpCard(tester, requested: false);
    await emit(tester, _finished(tracks: 0, added: 0));
    expect(find.byType(ProgressNoticeCard), findsNothing);
  });

  testWidgets('counts show a thousands separator', (tester) async {
    await pumpCard(tester);
    await emit(
      tester,
      const ScanRunning(phase: ScanPhase.tags, done: 1200, total: 2418),
    );
    expect(
      find.text('Reading tags and covers · 1,200 / 2,418 songs'),
      findsOneWidget,
    );
    await emit(tester, _finished(tracks: 2418, added: 2418));
    expect(find.text('Added 2,418 songs'), findsOneWidget);
  });

  testWidgets('Vietnamese groups thousands with a dot', (tester) async {
    await pumpCard(tester, locale: 'vi');
    await emit(tester, _finished(tracks: 2418, added: 2418));
    expect(find.text('Đã thêm 2.418 bài'), findsOneWidget);
  });

  testWidgets('a scan that added nothing stays invisible', (tester) async {
    await pumpCard(tester);
    await emit(tester, _finished(added: 0));
    expect(find.byType(ProgressNoticeCard), findsNothing);
  });

  testWidgets('a summary 11 s old is not shown', (tester) async {
    await pumpCard(tester);
    await emit(
      tester,
      _finished(at: _t0.subtract(const Duration(seconds: 11))),
    );
    expect(find.byType(ProgressNoticeCard), findsNothing);
  });

  testWidgets('a summary 8 s old hides when its 10 s are up', (tester) async {
    await pumpCard(tester);
    await emit(tester, _finished(at: _t0.subtract(const Duration(seconds: 8))));
    expect(find.text('Added 242 songs'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2, milliseconds: 1));
    expect(find.byType(ProgressNoticeCard), findsNothing);
  });

  testWidgets('a failed scan shows nothing', (tester) async {
    await pumpCard(tester);
    await emit(tester, const ScanFailed('permission'));
    expect(find.byType(ProgressNoticeCard), findsNothing);
  });

  testWidgets('the text fits at 150 %', (tester) async {
    await pumpCard(tester, textScale: 1.5);
    await emit(
      tester,
      const ScanRunning(phase: ScanPhase.tags, done: 120, total: 242),
    );
    expect(tester.takeException(), isNull);
    await emit(tester, _finished());
    expect(tester.takeException(), isNull);
    expect(find.text('Added 242 songs'), findsOneWidget);
  });

  test('the bar never goes back when tags hand over to covers', () {
    double at(ScanPhase p, int done) => (scanCardStateOf(
      ScanRunning(phase: p, done: done, total: 10),
      _t0,
    ) as ScanCardProgress).progress;
    var last = -1.0;
    for (final p in [ScanPhase.tags, ScanPhase.covers]) {
      for (var done = 0; done <= 10; done++) {
        final v = at(p, done);
        expect(v, greaterThanOrEqualTo(last));
        last = v;
      }
    }
  });
}
