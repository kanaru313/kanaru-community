import 'dart:async';

import 'package:flutter/semantics.dart'
    show CustomSemanticsAction, SemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_change.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/state/browse/selection_providers.dart';
import 'package:kanaru/src/library/domain/history/history_days.dart';
import 'package:kanaru/src/library/state/history/history_providers.dart';
import 'package:kanaru/src/library/state/history/local_day_provider.dart';
import 'package:kanaru/src/library/ui/history/history_locations.dart';
import 'package:kanaru/src/library/ui/history/history_page.dart';
import 'package:kanaru/src/library/ui/history/track/track_history_page.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../support/app_harness.dart';
import '../../../history/state/fake_history_store.dart';
import '../history_page_harness.dart';

const _id = 7;

/// Three plays of song 7: today 21:42, 14/11 21:42 (the 14th is a Saturday)
/// and the first one on 07/10, whose length is unknown. 22 minutes in all.
List<HistoryPlay> _plays() => [
  playAt(_id, DateTime(2026, 11, 20, 21, 42), uid: 'a', listenedMs: 192000),
  playAt(_id, DateTime(2026, 11, 14, 21, 42), uid: 'b', listenedMs: 1128000),
  HistoryPlay(
    id: 3,
    uid: 'c',
    track: info(_id, title: 'Song 7', artist: 'Artist'),
    playedAt: DateTime(2026, 10, 7, 8, 30).millisecondsSinceEpoch,
    listenedMs: null,
    ordinal: 1,
  ),
];

FakeHistoryStore _store({
  List<HistoryPlay>? plays,
  TrackAvailability status = TrackAvailability.present,
}) {
  final store = FakeHistoryStore();
  store.trackInfos[_id] = info(
    _id,
    title: 'Song 7',
    artist: 'Artist',
    status: status,
  );
  store.trackPlays[_id] = plays ?? _plays();
  return store;
}

Future<HistoryHarness> _pump(
  WidgetTester tester, {
  FakeHistoryStore? store,
  int? trackId = _id,
  double width = 400,
  double textScale = 1,
}) => pumpHistoryPage(
  tester,
  byYear: const {},
  store: store ?? _store(),
  width: width,
  textScale: textScale,
  page: TrackHistoryPage(trackId: trackId),
);

/// Lets a write and the re-read it triggers finish, then draws the result.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 2; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
}

const _rowToday = 'Hôm nay · 20/11/2026 · 21:42';
const _rowSaturday = 'Thứ Bảy · 14/11/2026 · 21:42';
const _empty = 'Chưa có lượt nghe nào';

/// The Delete key on the row of [title].
Future<void> _remove(WidgetTester tester, String title) async {
  await focusRow(tester, title);
  await tester.sendKeyEvent(LogicalKeyboardKey.delete);
  await _settle(tester);
}

List<bool> _selectedRows(WidgetTester tester) => [
  for (final row in tester.widgetList<KMediaCard>(find.byType(KMediaCard)))
    row.selected,
];

void main() {
  group('with plays', () {
    testWidgets('the hero names the song and the rows list every play, '
        'newest first', (tester) async {
      await _pump(tester);
      expect(find.text('Song 7'), findsWidgets);
      expect(find.text('Artist'), findsOneWidget);
      expect(find.text('3 lượt nghe'), findsOneWidget);
      expect(
        find.text(
          'Lần cuối hôm nay 21:42 · lần đầu 07/10/2026 · '
          'đã nghe tổng 22 phút.',
        ),
        findsOneWidget,
      );
      expect(find.text(_rowToday), findsOneWidget);
      expect(find.text(_rowSaturday), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(_rowToday)).dy,
        lessThan(tester.getTopLeft(find.text(_rowSaturday)).dy),
      );
      expect(find.text('đã nghe 3:12'), findsOneWidget);
      expect(find.text('đã nghe 18:48'), findsOneWidget);
      // The play with no length has no second line.
      expect(find.textContaining('đã nghe '), findsNWidgets(2 + 1));
    });

    testWidgets('a last play of yesterday reads "hôm qua"', (tester) async {
      final plays = [playAt(_id, DateTime(2026, 11, 19, 8, 5), uid: 'y')];
      await _pump(tester, store: _store(plays: plays));
      expect(find.textContaining('Lần cuối hôm qua 8:05'), findsOneWidget);
    });

    testWidgets('a last play of an older day reads its date', (tester) async {
      final plays = [playAt(_id, DateTime(2026, 10, 7, 21, 42), uid: 'o')];
      await _pump(tester, store: _store(plays: plays));
      expect(find.textContaining('Lần cuối 07/10 21:42'), findsOneWidget);
    });

    testWidgets('a last play within a week reads its weekday', (tester) async {
      final plays = [playAt(_id, DateTime(2026, 11, 14, 21, 42), uid: 'w')];
      await _pump(tester, store: _store(plays: plays));
      expect(find.textContaining('Lần cuối thứ bảy 21:42'), findsOneWidget);
    });

    testWidgets('a tap on a row does nothing', (tester) async {
      final h = await _pump(tester);
      await tester.tap(find.text(_rowToday));
      await _settle(tester);
      expect(h.playback.calls, isEmpty);
      expect(_selectedRows(tester), everyElement(isFalse));
    });

    testWidgets('Play queues just this song', (tester) async {
      final h = await _pump(tester);
      await tester.tap(find.text('Phát'));
      await _settle(tester);
      expect(h.playback.calls, hasLength(1));
    });

    testWidgets('both languages: English words the rows and the summary', (
      tester,
    ) async {
      await pumpHistoryPage(
        tester,
        byYear: const {},
        store: _store(),
        locale: const Locale('en'),
        page: const TrackHistoryPage(trackId: _id),
      );
      expect(find.text('Today · 20/11/2026 · 21:42'), findsOneWidget);
      expect(find.text('listened 3:12'), findsOneWidget);
      expect(
        find.text(
          'Last played today 21:42 · first played 07/10/2026 · '
          '22 min listened in total.',
        ),
        findsOneWidget,
      );
    });
  });

  group('empty and missing', () {
    testWidgets('no plays left: the hero stays and the line says so', (
      tester,
    ) async {
      await _pump(tester, store: _store(plays: const []));
      expect(find.text(_empty), findsOneWidget);
      expect(find.text('Song 7'), findsWidgets);
      expect(find.text('0 lượt nghe'), findsOneWidget);
      expect(find.byType(KMediaCard), findsNothing);
    });

    testWidgets('a song whose file is gone: dimmed hero, Play disabled with '
        'the reason', (tester) async {
      final semantics = tester.ensureSemantics();
      final h = await _pump(
        tester,
        store: _store(status: TrackAvailability.missing),
      );
      expect(find.byTooltip('Không phát được bài này'), findsOneWidget);
      expect(
        tester.getSemantics(
          find.ancestor(
            of: find.text('Phát'),
            matching: find.byType(FilledButton),
          ),
        ),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      await tester.tap(find.text('Phát'), warnIfMissed: false);
      await _settle(tester);
      expect(h.playback.calls, isEmpty);
      // The plays are still listed.
      expect(find.text(_rowToday), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('an id that names no song shows the empty line', (
      tester,
    ) async {
      await _pump(tester, store: _store(), trackId: 99);
      expect(find.text(_empty), findsOneWidget);
      expect(find.byType(KMediaCard), findsNothing);
    });

    testWidgets('a path with no usable id shows the empty line', (
      tester,
    ) async {
      await _pump(tester, trackId: null);
      expect(find.text(_empty), findsOneWidget);
    });
  });

  group('removing a play', () {
    testWidgets('Delete removes the row and Undo brings it back', (
      tester,
    ) async {
      final h = await _pump(tester, width: 1400);
      await _remove(tester, _rowSaturday);
      expect(h.store.removed, [
        ['b'],
      ]);
      expect(find.text(_rowSaturday), findsNothing);
      expect(find.text('2 lượt nghe'), findsOneWidget);
      expect(find.text('Đã xoá 1 lượt nghe'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Hoàn tác'));
      await _settle(tester);
      await tester.pumpAndSettle();
      expect(find.text(_rowSaturday), findsOneWidget);
      expect(find.text('3 lượt nghe'), findsOneWidget);
    });

    testWidgets('removing the last play shows the empty line, Undo restores '
        'the list', (tester) async {
      final plays = [playAt(_id, DateTime(2026, 11, 20, 21, 42), uid: 'a')];
      await _pump(tester, store: _store(plays: plays), width: 1400);
      await _remove(tester, _rowToday);
      expect(find.text(_empty), findsOneWidget);
      expect(find.text('Song 7'), findsWidgets);
      expect(find.byType(KMediaCard), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Hoàn tác'));
      await _settle(tester);
      await tester.pumpAndSettle();
      expect(find.text(_empty), findsNothing);
      expect(find.text(_rowToday), findsOneWidget);
    });

    testWidgets('the ⋮ menu removes a play too', (tester) async {
      final h = await _pump(tester);
      await tester.tap(find.byType(KMoreButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xoá khỏi lịch sử'));
      await _settle(tester);
      await tester.pumpAndSettle();
      expect(h.store.removed, [
        ['a'],
      ]);
    });

    testWidgets('a failed write shows the error toast and keeps the row', (
      tester,
    ) async {
      final store = _store()..removeError = StateError('disk');
      await _pump(tester, store: store, width: 1400);
      await _remove(tester, _rowSaturday);
      expect(find.text('Không xoá được lượt nghe'), findsOneWidget);
      expect(find.textContaining('Đã xoá'), findsNothing);
      expect(find.text(_rowSaturday), findsOneWidget);
    });
  });

  group('semantics and reload errors', () {
    testWidgets('a row reads as one labelled node with a remove action, not '
        'a button', (tester) async {
      final semantics = tester.ensureSemantics();
      final h = await _pump(tester);
      final node = tester.getSemantics(find.text(_rowToday));
      expect(node.label, '$_rowToday, đã nghe 3:12');
      expect(node.flagsCollection.isButton, isFalse);
      final data = node.getSemanticsData();
      expect(data.customSemanticsActionIds, isNotEmpty);
      final action = CustomSemanticsAction.getAction(
        data.customSemanticsActionIds!.single,
      )!;
      expect(action.label, 'Xoá khỏi lịch sử');
      tester.semantics.performAction(
        find.semantics.byLabel(RegExp('^$_rowToday')),
        SemanticsAction.customAction,
        args: data.customSemanticsActionIds!.single,
      );
      await _settle(tester);
      expect(h.store.removed, [
        ['a'],
      ]);
      semantics.dispose();
    });

    testWidgets('a reload that fails keeps the rows and shows the error', (
      tester,
    ) async {
      final h = await _pump(tester);
      h.store.trackError = StateError('disk');
      h.store.playsChanged.add(const HistoryChange(inserted: true));
      await _settle(tester);
      expect(find.text('Không tải được danh sách'), findsOneWidget);
      expect(find.text(_rowToday), findsOneWidget);
    });
  });

  group('selection', () {
    testWidgets('a long press selects the song and every row shows it', (
      tester,
    ) async {
      final h = await _pump(tester);
      await tester.longPress(find.text(_rowToday));
      await _settle(tester);
      expect(
        h.container.read(librarySelectionProvider).set,
        contains(const TrackId(_id)),
      );
      expect(_selectedRows(tester), [true, true, true]);
    });

    testWidgets('a tap while selecting toggles the song off', (tester) async {
      final h = await _pump(tester);
      await tester.longPress(find.text(_rowToday));
      await _settle(tester);
      await tester.tap(find.text(_rowSaturday));
      await _settle(tester);
      expect(h.container.read(librarySelectionProvider).isEmpty, isTrue);
      expect(_selectedRows(tester), everyElement(isFalse));
    });
  });

  testWidgets('200 % text: the hero and the rows lay out without overflow', (
    tester,
  ) async {
    await _pump(tester, textScale: 2);
    expect(tester.takeException(), isNull);
    expect(find.text('Song 7'), findsWidgets);
    expect(find.text(_rowToday), findsOneWidget);
    await tester.drag(find.text(_rowToday), const Offset(0, -400));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile: Back from the sub-page goes to the History page', (
    tester,
  ) async {
    final store = _store();
    final c = await pumpKanaruApp(
      tester,
      width: 400,
      height: 800,
      overrides: [
        historyStoreProvider.overrideWithValue(store),
        // A fixed day: the real one keeps a midnight timer pending.
        localDayProvider.overrideWith(_FixedDay.new),
      ],
    );
    final router = c.read(routerProvider);
    router.go(HistoryLocations.history);
    await tester.pumpAndSettle();
    expect(find.byType(HistoryPage), findsOneWidget);

    unawaited(router.push(HistoryLocations.track(_id)));
    await tester.pumpAndSettle();
    expect(find.byType(TrackHistoryPage), findsOneWidget);
    await _settle(tester);
    expect(find.byType(KMediaCard), findsNWidgets(3));

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(TrackHistoryPage), findsNothing);
    expect(
      router.routerDelegate.currentConfiguration.last.matchedLocation,
      HistoryLocations.history,
    );
    expect(find.byType(HistoryPage), findsOneWidget);
  });
}

class _FixedDay extends LocalDayNotifier {
  @override
  DateTime build() => localDay(testToday);
}
