import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_change.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/domain/history/history_days.dart';
import 'package:kanaru/src/library/state/history/history_providers.dart';
import 'package:kanaru/src/library/state/history/local_day_provider.dart';
import 'package:kanaru/src/library/ui/history/history_locations.dart';
import 'package:kanaru/src/library/ui/history/history_page.dart';
import 'package:kanaru/src/library/ui/history/track/track_history_page.dart';
import 'package:kanaru/src/library/ui/history/track/track_history_rows.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/router/state/router_provider.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../support/app_harness.dart';
import '../../../../support/icon_button_finders.dart';
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

const _empty = 'Chưa có lượt nghe nào';
const _removeTip = 'Xoá khỏi lịch sử';

Finder _row(int i) => find.byType(TrackHistoryRow).at(i);

/// The text of the cell [text] inside row [i].
Finder _in(int i, String text) =>
    find.descendant(of: _row(i), matching: find.text(text));

/// The Delete key on row [i]: its button takes the focus, as Tab would.
Future<void> _remove(WidgetTester tester, int i) async {
  final icon = find
      .descendant(
        of: byIconButton(_removeTip).at(i),
        matching: find.byType(Icon),
      )
      .first;
  Focus.of(tester.element(icon)).requestFocus();
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.delete);
  await _settle(tester);
}

void main() {
  group('hero', () {
    testWidgets('names the song, its artist and the plays; Play and ⋮ only', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('Song 7'), findsWidgets);
      expect(find.text('Artist'), findsOneWidget);
      expect(find.text('3 lượt nghe'), findsOneWidget);
      expect(find.text('Phát'), findsOneWidget);
      expect(find.text('Phát ngẫu nhiên'), findsNothing);
      expect(byIconButton('Phát ngẫu nhiên'), findsNothing);
      expect(byIconButton('Tùy chọn khác'), findsOneWidget);
    });

    testWidgets('the summary is three lines, no full stop', (tester) async {
      await _pump(tester);
      expect(find.text('Lần cuối: hôm nay 21:42'), findsOneWidget);
      expect(find.text('Lần đầu: 07/10/2026'), findsOneWidget);
      expect(find.text('Đã nghe tổng: 22 phút'), findsOneWidget);
      final ys = [
        for (final t in [
          'Lần cuối: hôm nay 21:42',
          'Lần đầu: 07/10/2026',
          'Đã nghe tổng: 22 phút',
        ])
          tester.getTopLeft(find.text(t)).dy,
      ];
      expect(ys[0], lessThan(ys[1]));
      expect(ys[1], lessThan(ys[2]));
    });

    testWidgets('a figure the song has none of leaves its line out', (
      tester,
    ) async {
      final plays = [
        HistoryPlay(
          id: 1,
          uid: 'n',
          track: info(_id, title: 'Song 7', artist: 'Artist'),
          playedAt: DateTime(2026, 10, 7, 8, 30).millisecondsSinceEpoch,
          listenedMs: null,
          ordinal: 1,
        ),
      ];
      await _pump(tester, store: _store(plays: plays));
      expect(find.textContaining('Lần cuối: 07/10 8:30'), findsOneWidget);
      expect(find.textContaining('Lần đầu: 07/10/2026'), findsOneWidget);
      expect(find.textContaining('Đã nghe tổng'), findsNothing);
    });

    for (final (name, at, line) in [
      ('yesterday', DateTime(2026, 11, 19, 8, 5), 'Lần cuối: hôm qua 8:05'),
      ('a weekday', DateTime(2026, 11, 14, 21, 42), 'Lần cuối: thứ bảy 21:42'),
      ('a date', DateTime(2026, 10, 7, 21, 42), 'Lần cuối: 07/10 21:42'),
    ]) {
      testWidgets('the last play reads $name', (tester) async {
        await _pump(
          tester,
          store: _store(plays: [playAt(_id, at, uid: 'x')]),
        );
        expect(find.text(line), findsOneWidget);
      });
    }

    testWidgets('Play queues just this song', (tester) async {
      final h = await _pump(tester);
      await tester.tap(find.text('Phát'));
      await _settle(tester);
      expect(h.playback.calls, hasLength(1));
    });

    testWidgets('the ⋮ opens the menu of the song', (tester) async {
      await _pump(tester);
      await tester.tap(byIconButton('Tùy chọn khác'));
      await tester.pumpAndSettle();
      // The head of the song menu: the song itself.
      expect(find.text('Song 7'), findsWidgets);
      expect(find.text(_removeTip), findsNothing);
      expect(find.text('Lịch sử bài này'), findsNothing);
    });

    testWidgets('English words the labels and the summary', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: const {},
        store: _store(),
        locale: const Locale('en'),
        page: const TrackHistoryPage(trackId: _id),
      );
      expect(find.text('Last played: today 21:42'), findsOneWidget);
      expect(find.text('First played: 07/10/2026'), findsOneWidget);
      expect(find.text('Listened in total: 22 min'), findsOneWidget);
      expect(find.text('3 plays, newest first'), findsOneWidget);
      expect(_in(0, 'Today'), findsOneWidget);
    });
  });

  group('the table of plays', () {
    testWidgets('a header row, then one row per play, newest first', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('3 lượt nghe, mới nhất trước'), findsOneWidget);
      for (final h in ['Ngày', 'Giờ', 'Đã nghe']) {
        expect(find.text(h), findsOneWidget, reason: h);
      }
      expect(find.byType(TrackHistoryRow), findsNWidgets(3));
      expect(
        tester.getTopLeft(find.text('Ngày')).dy,
        lessThan(tester.getTopLeft(_row(0)).dy),
      );
      expect(
        tester.getTopLeft(_row(0)).dy,
        lessThan(tester.getTopLeft(_row(1)).dy),
      );
    });

    testWidgets('Today and Yesterday by name, other days as dd/mm/yyyy', (
      tester,
    ) async {
      final plays = [
        playAt(_id, DateTime(2026, 11, 20, 21, 42), uid: 'a'),
        playAt(_id, DateTime(2026, 11, 19, 8, 5), uid: 'b'),
        playAt(_id, DateTime(2026, 11, 14, 21, 42), uid: 'c'),
        playAt(_id, DateTime(2026, 10, 7, 9, 30), uid: 'd'),
      ];
      await _pump(tester, store: _store(plays: plays));
      expect(_in(0, 'Hôm nay'), findsOneWidget);
      expect(_in(1, 'Hôm qua'), findsOneWidget);
      // No weekday: the date alone, with its year.
      expect(_in(2, '14/11/2026'), findsOneWidget);
      expect(_in(3, '07/10/2026'), findsOneWidget);
    });

    testWidgets('time and listened length each sit in their own cell', (
      tester,
    ) async {
      await _pump(tester);
      expect(_in(0, '21:42'), findsOneWidget);
      expect(_in(0, '3:12'), findsOneWidget);
      expect(_in(1, '18:48'), findsOneWidget);
      // The play with no length has an empty last cell, not a made-up one.
      expect(_in(2, '8:30'), findsOneWidget);
      expect(
        find.descendant(of: _row(2), matching: find.textContaining(':')),
        findsOneWidget,
      );
    });

    testWidgets('a tap on a row does nothing', (tester) async {
      final h = await _pump(tester);
      await tester.tap(_row(0));
      await _settle(tester);
      expect(h.playback.calls, isEmpty);
    });

    testWidgets('a row is 48 dp and keeps one line at 200 % text', (
      tester,
    ) async {
      await _pump(tester, textScale: 2, width: 520);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_row(0)).height, greaterThanOrEqualTo(48));
      await tester.drag(_row(0), const Offset(0, -400));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('at 200 % text the time and listened figures are never cut; '
        'the day gives way', (tester) async {
      // 520 dp: the test font is 1 em wide per glyph, about twice a real
      // digit, so this is the 400 dp phone in practice.
      await _pump(tester, textScale: 2, width: 520);
      final figures = find.descendant(
        of: _row(0),
        matching: find.textContaining(RegExp(r'^\d{1,2}:\d{2}')),
      );
      expect(figures, findsWidgets);
      for (final e in figures.evaluate()) {
        final paragraph = e.renderObject! as RenderParagraph;
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: (e.widget as Text).data,
        );
      }
      final day = find.descendant(
        of: _row(0),
        matching: find.byWidgetPredicate(
          (w) => w is Text && w.data != null && !w.data!.contains(':'),
        ),
      );
      expect(
        (day.evaluate().first.renderObject! as RenderParagraph)
            .didExceedMaxLines,
        isTrue,
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
      expect(find.byType(TrackHistoryRow), findsNothing);
      expect(find.text('Ngày'), findsNothing);
    });

    testWidgets('a song whose file is gone: dimmed hero, Play disabled with '
        'the reason, no song menu', (tester) async {
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
      expect(byIconButton('Tùy chọn khác'), findsNothing);
      // The plays are still listed.
      expect(_in(0, 'Hôm nay'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('an id that names no song shows the empty line', (
      tester,
    ) async {
      await _pump(tester, store: _store(), trackId: 99);
      expect(find.text(_empty), findsOneWidget);
      expect(find.byType(TrackHistoryRow), findsNothing);
    });

    testWidgets('a path with no usable id shows the empty line', (
      tester,
    ) async {
      await _pump(tester, trackId: null);
      expect(find.text(_empty), findsOneWidget);
    });
  });

  group('removing a play', () {
    testWidgets('the delete button removes the row; Undo brings it back', (
      tester,
    ) async {
      final h = await _pump(tester);
      expect(byIconButton(_removeTip), findsNWidgets(3));
      await tester.tap(byIconButton(_removeTip).at(1));
      await _settle(tester);
      expect(h.store.removed, [
        ['b'],
      ]);
      expect(find.byType(TrackHistoryRow), findsNWidgets(2));
      expect(find.text('2 lượt nghe'), findsOneWidget);
      expect(find.text('Đã xoá 1 lượt nghe'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Hoàn tác'));
      await _settle(tester);
      await tester.pumpAndSettle();
      expect(find.byType(TrackHistoryRow), findsNWidgets(3));
      expect(find.text('3 lượt nghe'), findsOneWidget);
    });

    testWidgets('the toast closes by itself after 4 seconds', (tester) async {
      await _pump(tester);
      await tester.tap(byIconButton(_removeTip).at(0));
      await _settle(tester);
      expect(find.text('Đã xoá 1 lượt nghe'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Đã xoá 1 lượt nghe'), findsNothing);
    });

    testWidgets('the Delete key on the focused row does the same', (
      tester,
    ) async {
      final h = await _pump(tester, width: 1400);
      await _remove(tester, 1);
      expect(h.store.removed, [
        ['b'],
      ]);
      expect(find.byType(TrackHistoryRow), findsNWidgets(2));
      expect(find.text('Đã xoá 1 lượt nghe'), findsOneWidget);
    });

    testWidgets('removing the last play shows the empty line, Undo restores '
        'the list', (tester) async {
      final plays = [playAt(_id, DateTime(2026, 11, 20, 21, 42), uid: 'a')];
      await _pump(tester, store: _store(plays: plays), width: 1400);
      await tester.tap(byIconButton(_removeTip));
      await _settle(tester);
      expect(find.text(_empty), findsOneWidget);
      expect(find.text('Song 7'), findsWidgets);
      expect(find.byType(TrackHistoryRow), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Hoàn tác'));
      await _settle(tester);
      await tester.pumpAndSettle();
      expect(find.text(_empty), findsNothing);
      expect(find.byType(TrackHistoryRow), findsOneWidget);
    });

    testWidgets('a failed write shows the error toast and keeps the row', (
      tester,
    ) async {
      final store = _store()..removeError = StateError('disk');
      await _pump(tester, store: store, width: 1400);
      await tester.tap(byIconButton(_removeTip).at(1));
      await _settle(tester);
      expect(find.text('Không xoá được lượt nghe'), findsOneWidget);
      expect(find.textContaining('Đã xoá'), findsNothing);
      expect(find.byType(TrackHistoryRow), findsNWidgets(3));
    });
  });

  group('semantics and reload errors', () {
    testWidgets('a row is one labelled node with the full date; its button '
        'names the play it removes', (tester) async {
      final semantics = tester.ensureSemantics();
      final h = await _pump(tester);
      for (final label in [
        '20/11/2026, 21:42, đã nghe 3:12',
        '14/11/2026, 21:42, đã nghe 18:48',
        // No length: nothing is said about one.
        '07/10/2026, 8:30',
      ]) {
        expect(find.semantics.byLabel(label), findsOneWidget, reason: label);
      }
      final remove = find.semantics.byLabel(
        'Xoá lượt nghe lúc 21:42, 20/11/2026',
      );
      expect(remove, findsOneWidget);
      tester.semantics.tap(remove);
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
      expect(find.byType(TrackHistoryRow), findsNWidgets(3));
    });
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
    expect(find.byType(TrackHistoryRow), findsNWidgets(3));

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
