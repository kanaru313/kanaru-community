import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/domain/history/history_ranges.dart';
import 'package:kanaru/src/library/state/history/most_played_selection.dart';
import 'package:kanaru/src/library/ui/history/history_hero.dart';
import 'package:kanaru/src/library/ui/history/history_locations.dart';
import 'package:kanaru/src/library/ui/history/history_day_menu.dart';
import 'package:kanaru/src/library/ui/history/history_menus.dart';
import 'package:kanaru/src/library/ui/history/history_row_menu.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/platform/domain/document_picker.dart';
import 'package:kanaru/src/platform/state/document_picker_provider.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart'
    show BottomSheet, Focus, Icon, Scaffold, Text;

import '../../../support/fake_playback_commands.dart';
import '../../../support/icon_button_finders.dart';
import '../../history/state/fake_history_store.dart';
import '../menus/menu_fixtures.dart' show rowIds, rowOf;
import '../menus/menu_pump.dart';
import 'history_page_harness.dart';

final _l10n = AppLocalizationsEn();

const _mostPlayedMarker = 'the most played page';

final _mostPlayedRoute = GoRoute(
  path: HistoryLocations.mostPlayed,
  builder: (context, state) => const Scaffold(body: Text(_mostPlayedMarker)),
);

/// Counts how often every played song is read.
class _CountingStore extends FakeHistoryStore {
  int reads = 0;

  @override
  Future<List<TrackId>> playedTracksNewestFirst() {
    reads++;
    return super.playedTracksNewestFirst();
  }
}

/// A file dialog that only notes the name it was asked for, then fails.
class _NamePicker implements DocumentPicker {
  String? suggestedName;

  @override
  Future<SaveTarget?> createDocument({
    required String suggestedName,
    DocumentFilter? filter,
  }) async {
    this.suggestedName = suggestedName;
    throw const DocumentPickerException(DocumentPickerFailure.unavailable);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

MenuSpec _page({
  required int plays,
  bool clearing = false,
  Future<List<TrackId>> Function()? playedTracks,
}) => buildHistoryPageMenu(
  _l10n,
  plays: plays,
  clearing: clearing,
  playedTracks: playedTracks ?? () async => const [],
);

/// The ids of each group of rows, in order.
List<List<MenuItemId>> _groups(MenuSpec spec) => [
  for (final g in spec.groups) rowIds([g]),
];

HistoryDay _day(List<HistoryPlay> plays) =>
    HistoryDay(DateTime(2026, 11, 19), plays);

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  group('page menu', () {
    test('lists the rows in their groups; every one is live', () {
      final spec = _page(plays: 12);
      expect(_groups(spec), [
        [MenuItemId.play, MenuItemId.shuffle, MenuItemId.playlist],
        [MenuItemId.link, MenuItemId.playlistExportM3u],
        [MenuItemId.delete],
      ]);
      expect(spec.header.subtitle, '12 plays');
      expect(rowOf(spec, MenuItemId.link).soon, isFalse);
      expect(rowOf(spec, MenuItemId.link).active, isTrue);
      expect(
        rowOf(spec, MenuItemId.link).action,
        MenuAction.go(HistoryLocations.mostPlayed),
      );
      for (final id in [
        MenuItemId.play,
        MenuItemId.shuffle,
        MenuItemId.playlist,
        MenuItemId.delete,
      ]) {
        expect(rowOf(spec, id).active, isTrue, reason: '$id');
      }
    });

    test('the export row dims with no plays', () {
      final spec = _page(plays: 3);
      expect(rowOf(spec, MenuItemId.playlistExportM3u).enabled, isTrue);
      expect(
        rowOf(spec, MenuItemId.playlistExportM3u).action,
        isA<RunAction>(),
      );
      final none = _page(plays: 0);
      expect(rowOf(none, MenuItemId.playlistExportM3u).enabled, isFalse);
      expect(rowOf(none, MenuItemId.link).enabled, isTrue);
    });

    testWidgets('choosing export reads the songs then asks for the file, '
        'named after the page', (tester) async {
      final store = _CountingStore()..playedTracks = [TrackId(5), TrackId(2)];
      final picker = _NamePicker();
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2, 2]),
        },
        store: store,
        overrides: [documentPickerProvider.overrideWithValue(picker)],
      );
      final l10n = l10nOf(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(HistoryHero),
          matching: byIconButton(l10n.libraryMenuMore),
        ),
      );
      await pumpMenu(tester);
      expect(store.reads, 0, reason: 'the menu opens without the list');
      await tester.tap(find.text(l10n.playlistMenuExportM3u));
      await tester.pumpAndSettle();
      expect(store.reads, 1);
      expect(picker.suggestedName, '${l10n.historyTitle}.m3u8');
    });

    test('Clear history is the only red row', () {
      final spec = _page(plays: 3);
      final red = [
        for (final g in spec.groups)
          for (final i in g)
            if (i.danger) i.id,
      ];
      expect(red, [MenuItemId.delete]);
      expect(rowOf(spec, MenuItemId.delete).title, 'Clear history…');
    });

    test('with no plays every action is off', () {
      final spec = _page(plays: 0);
      for (final id in [
        MenuItemId.play,
        MenuItemId.shuffle,
        MenuItemId.playlist,
        MenuItemId.delete,
      ]) {
        expect(rowOf(spec, id).enabled, isFalse, reason: '$id');
      }
    });

    test('Clear history waits while a clear runs', () {
      final spec = _page(plays: 3, clearing: true);
      expect(rowOf(spec, MenuItemId.delete).enabled, isFalse);
      expect(rowOf(spec, MenuItemId.play).enabled, isTrue);
    });
  });

  group('day menu', () {
    final today = DateTime(2026, 11, 20);

    test('plays, shuffles, adds, opens Most played and removes', () {
      final plays = [playAt(1, DateTime(2026, 11, 19, 20))];
      final spec = buildHistoryDayMenu(
        _l10n,
        _day(plays),
        today,
        clearing: false,
      );
      expect(_groups(spec), [
        [MenuItemId.play, MenuItemId.shuffle],
        [MenuItemId.playlist, MenuItemId.link],
        [MenuItemId.delete],
      ]);
      expect(rowOf(spec, MenuItemId.link).title, 'Open in Most played');
      expect(rowOf(spec, MenuItemId.link).active, isTrue);
      expect(spec.header.title, 'Yesterday');
      expect(rowOf(spec, MenuItemId.delete).danger, isTrue);
      expect(rowOf(spec, MenuItemId.delete).enabled, isTrue);
      expect(rowOf(spec, MenuItemId.play).title, 'Play the day');
    });

    test('add to playlist takes the day\'s songs, each once, by full date', () {
      final plays = [
        playAt(1, DateTime(2026, 11, 19, 21), uid: 'a'),
        playAt(2, DateTime(2026, 11, 19, 20), uid: 'b'),
        playAt(1, DateTime(2026, 11, 19, 19), uid: 'c'),
        playAt(
          3,
          DateTime(2026, 11, 19, 18),
          uid: 'd',
          track: info(3, status: TrackAvailability.missing),
        ),
      ];
      final spec = buildHistoryDayMenu(
        _l10n,
        _day(plays),
        today,
        clearing: false,
      );
      final action = rowOf(spec, MenuItemId.playlist).action;
      final request = (action! as AddToPlaylistAction).request;
      expect([for (final t in request.tracks) t.value], [1, 2]);
      expect(request.sourceLabel, 'Thursday, November 19, 2026');
    });

    test(
      'a day of only missing songs cannot play; deleting waits for a clear',
      () {
        final plays = [
          playAt(
            3,
            DateTime(2026, 11, 19, 18),
            track: info(3, status: TrackAvailability.missing),
          ),
        ];
        final spec = buildHistoryDayMenu(
          _l10n,
          _day(plays),
          today,
          clearing: true,
        );
        expect(rowOf(spec, MenuItemId.play).enabled, isFalse);
        expect(rowOf(spec, MenuItemId.shuffle).enabled, isFalse);
        expect(rowOf(spec, MenuItemId.playlist).enabled, isFalse);
        expect(rowOf(spec, MenuItemId.delete).enabled, isFalse);
        // The page can still show that day, whatever its songs.
        expect(rowOf(spec, MenuItemId.link).enabled, isTrue);
      },
    );
  });

  group('row menu', () {
    test('adds the song\'s history and the red removal', () {
      final play = playAt(7, DateTime(2026, 11, 19, 20));
      final rows = historyRowMenuItems(_l10n, play);
      expect(
        [for (final r in rows) r.title],
        ['History of this song', 'Remove from history'],
      );
      expect(rows.first.action, MenuAction.go(HistoryLocations.track(7)));
      expect(rows.first.danger, isFalse);
      expect(rows.last.danger, isTrue);
      expect(rows.last.action, isA<RunAction>());
    });
  });

  group('on the page', () {
    testWidgets('the page menu\'s Most played row opens that page', (
      tester,
    ) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2, 2]),
        },
        routes: [_mostPlayedRoute],
      );
      final l10n = l10nOf(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(HistoryHero),
          matching: byIconButton(l10n.libraryMenuMore),
        ),
      );
      await pumpMenu(tester);
      await tester.tap(find.text(l10n.historyMenuMostPlayed));
      await pumpMenu(tester);
      expect(find.text(_mostPlayedMarker), findsOneWidget);
      expect(find.byType(HistoryHero), findsNothing);
    });

    testWidgets('the hero ⋮ opens the page menu in a sheet', (tester) async {
      final h = await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2, 2]),
        },
      );
      final l10n = l10nOf(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(HistoryHero),
          matching: byIconButton(l10n.libraryMenuMore),
        ),
      );
      await pumpMenu(tester);
      expect(find.byType(BottomSheet), findsOneWidget);
      for (final label in [
        l10n.libraryPlayAll,
        l10n.libraryShuffle,
        l10n.libraryMenuAddToPlaylist,
        l10n.historyMenuMostPlayed,
        l10n.playlistMenuExportM3u,
        l10n.historyMenuClear,
      ]) {
        expect(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text(label),
          ),
          findsOneWidget,
          reason: label,
        );
      }
      expect(h.playback.calls, isEmpty);
    });

    testWidgets(
      'a long press on a day bar opens that day\'s menu and plays it',
      (tester) async {
        final plays = playsOverDays([2, 3]);
        final h = await pumpHistoryPage(tester, byYear: {2026: plays});
        final l10n = l10nOf(tester);
        // Yesterday's header line is the second bar on the page.
        final bar = find.text(l10n.historyDayYesterday).first;
        await tester.longPress(bar);
        await pumpMenu(tester);
        expect(find.text(l10n.historyMenuPlayDay), findsOneWidget);
        expect(find.text(l10n.historyMenuDeleteDay), findsOneWidget);
        await tester.tap(find.text(l10n.historyMenuPlayDay));
        await pumpMenu(tester);
        final call = h.playback.calls.single as PlayTracksCall;
        expect([for (final t in call.tracks) t.value], [3, 4, 5]);
        expect(call.context.kind, PlayContextKind.history);
      },
    );

    testWidgets('the day menu\'s "Open in Most played" shows that one day '
        'there', (tester) async {
      final h = await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2, 3]),
        },
        routes: [_mostPlayedRoute],
      );
      final l10n = l10nOf(tester);
      await tester.longPress(find.text(l10n.historyDayYesterday).first);
      await pumpMenu(tester);
      await tester.tap(find.text(l10n.historyMostPlayedOpenDay));
      await pumpMenu(tester);
      final range = h.container.read(mostPlayedRangeProvider);
      expect(range.preset, MostPlayedPreset.custom);
      expect(range.customStart, DateTime(2026, 11, 19));
      expect(range.customEndInclusive, DateTime(2026, 11, 19));
      expect(range.back, 0);
      expect(find.text(_mostPlayedMarker), findsOneWidget);
    });

    testWidgets('a right click on a day bar opens the menu too', (
      tester,
    ) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2, 3]),
        },
        width: 1400,
      );
      final l10n = l10nOf(tester);
      final bar = tester.getCenter(find.text(l10n.historyDayYesterday).first);
      final mouse = await tester.startGesture(
        bar,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await mouse.up();
      await pumpMenu(tester);
      expect(find.text(l10n.historyMenuPlayDay), findsOneWidget);
    });

    testWidgets('Shift+F10 on a day bar opens its menu from the keyboard', (
      tester,
    ) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2, 3]),
        },
        width: 1400,
      );
      final l10n = l10nOf(tester);
      final more = byIconButton(
        l10n.historyDayMenuLabel(l10n.historyDayYesterday),
      );
      // The nearest focus node around the button's glyph is the button's own.
      Focus.of(
        tester.element(
          find.descendant(of: more, matching: find.byType(Icon)).first,
        ),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.f10);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await pumpMenu(tester);
      expect(find.text(l10n.historyMenuPlayDay), findsOneWidget);
    });

    testWidgets('a missing play\'s menu holds only the two history rows', (
      tester,
    ) async {
      final gone = info(9, title: 'Gone', status: TrackAvailability.missing);
      final h = await pumpHistoryPage(
        tester,
        byYear: {
          2026: [
            playAt(1, DateTime(2026, 11, 20, 9), uid: 'p1', track: gone),
            playAt(2, DateTime(2026, 11, 20, 8), uid: 'p2'),
          ],
        },
        width: 1400,
      );
      final l10n = l10nOf(tester);
      // The ⋮ of the missing row is the only one on a missing row.
      final menuButtons = byIconButton(l10n.libraryMenuMore);
      expect(menuButtons, findsWidgets);
      await tester.tap(find.text('Gone'), warnIfMissed: false);
      await tester.pump();
      final row = find.ancestor(
        of: find.text('Gone'),
        matching: find.byType(KMediaCard),
      );
      await tester.tap(find.descendant(of: row, matching: menuButtons));
      await pumpMenu(tester);
      expect(find.text(l10n.historyMenuTrackHistory), findsOneWidget);
      expect(find.text(l10n.historyMenuRemovePlay), findsOneWidget);
      expect(find.text(l10n.libraryMenuAddToPlaylist), findsNothing);
      await tester.tap(find.text(l10n.historyMenuRemovePlay));
      await pumpMenu(tester);
      expect(h.store.removed, [
        ['p1'],
      ]);
      expect(find.text('Đã xoá 1 lượt nghe'), findsOneWidget);
    });
  });
}
