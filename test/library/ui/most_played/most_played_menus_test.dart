import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/domain/history/history_ranges.dart';
import 'package:kanaru/src/library/state/favorites_providers.dart';
import 'package:kanaru/src/library/ui/history/history_locations.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/most_played/most_played_hero.dart';
import 'package:kanaru/src/library/ui/most_played/most_played_menus.dart';
import 'package:kanaru/src/library/ui/songs/song_tile.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../support/fake_playback_commands.dart';
import '../../../support/icon_button_finders.dart';
import '../../history/state/fake_history_store.dart';
import '../menus/menu_fixtures.dart' show rowIds, rowOf;
import '../menus/menu_pump.dart';
import 'most_played_harness.dart';

final _l10n = AppLocalizationsEn();
final _today = DateTime(2026, 11, 20);

MenuSpec _menu({
  required List<TopEntry> entries,
  MostPlayedRange range = const MostPlayedRange(),
  bool stale = false,
}) => buildMostPlayedMenu(
  _l10n,
  data: topList(entries),
  range: range,
  today: _today,
  stale: stale,
);

class _Favorites implements FavoritesController {
  final calls = <(List<TrackId>, bool)>[];
  Object? error;

  @override
  Future<void> setFavorite(List<TrackId> tracks, bool favorite) async {
    if (error != null) throw error!;
    calls.add((tracks, favorite));
  }

  @override
  Future<void> toggle(TrackId track) => throw UnimplementedError();
}

/// The ⋮ button of the row titled [title].
Finder _rowMenuButton(WidgetTester tester, String title) => find.descendant(
  of: find.ancestor(of: find.text(title), matching: find.byType(KMediaCard)),
  matching: byIconButton(mostPlayedL10n(tester).libraryMenuMore),
);

Future<void> _openPageMenu(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(MostPlayedHero),
      matching: byIconButton(mostPlayedL10n(tester).libraryMenuMore),
    ),
  );
  await pumpMenu(tester);
}

void main() {
  setUpAll(() => initializeDateFormatting('en'));

  group('the menu', () {
    final entries = [
      topEntry(1),
      topEntry(
        2,
        track: info(2, title: 'Gone', status: TrackAvailability.missing),
      ),
      topEntry(3),
    ];

    test('rows in their groups, named after the range', () {
      final spec = _menu(entries: entries);
      expect(
        [
          for (final g in spec.groups) rowIds([g]),
        ],
        [
          [
            MenuItemId.play,
            MenuItemId.shuffle,
            MenuItemId.playlist,
            MenuItemId.favorite,
            MenuItemId.playlistExportM3u,
          ],
        ],
      );
      expect(spec.header.title, 'Most played');
      expect(spec.header.subtitle, '30 days · 22/10 – 20/11/2026');
      expect(rowOf(spec, MenuItemId.play).title, 'Play (by rank)');
      expect(rowOf(spec, MenuItemId.shuffle).title, 'Shuffle');
      expect(rowOf(spec, MenuItemId.favorite).title, 'Add all to favorites');
      for (final id in [
        MenuItemId.play,
        MenuItemId.shuffle,
        MenuItemId.playlist,
        MenuItemId.favorite,
        MenuItemId.playlistExportM3u,
      ]) {
        expect(rowOf(spec, id).enabled, isTrue, reason: '$id');
      }
    });

    test('empty list or a reload: every row is off', () {
      for (final spec in [
        _menu(entries: const []),
        _menu(entries: entries, stale: true),
      ]) {
        for (final g in spec.groups) {
          for (final row in g) {
            expect(row.enabled, isFalse, reason: '${row.id}');
          }
        }
      }
    });

    test('only missing songs: nothing plays, the export still works', () {
      final spec = _menu(
        entries: [
          topEntry(1, track: info(1, status: TrackAvailability.missing)),
        ],
      );
      for (final row in spec.groups.expand((g) => g)) {
        expect(
          row.enabled,
          row.id == MenuItemId.playlistExportM3u,
          reason: '${row.id}',
        );
      }
    });

    test('the export lists every song by rank, missing ones included', () {
      final ids = mostPlayedExportTracks([
        topEntry(3),
        topEntry(
          2,
          track: info(2, title: 'Gone', status: TrackAvailability.missing),
        ),
        topEntry(1),
      ]);
      expect([for (final t in ids) t.value], [1, 2, 3]);
    });
  });

  group('on the page', () {
    testWidgets('the hero ⋮ opens the menu in a sheet with every row', (
      tester,
    ) async {
      await pumpMostPlayed(tester, top: topList([topEntry(1), topEntry(2)]));
      await _openPageMenu(tester);
      for (final label in [
        'Phát (theo thứ hạng)',
        'Phát ngẫu nhiên',
        'Thêm vào playlist…',
        'Thêm tất cả vào Yêu thích',
        'Xuất tệp M3U…',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Phát tất cả'), findsNothing);
      expect(find.textContaining('đường dẫn tương đối'), findsNothing);
    });

    testWidgets('Phát plays in rank order without the missing songs; '
        'Phát ngẫu nhiên shuffles', (tester) async {
      final h = await pumpMostPlayed(
        tester,
        top: topList([
          topEntry(1),
          topEntry(
            2,
            track: info(2, title: 'Gone', status: TrackAvailability.missing),
          ),
          topEntry(3),
        ]),
      );
      await _openPageMenu(tester);
      await tester.tap(find.text('Phát (theo thứ hạng)'));
      await pumpMenu(tester);
      var call = h.playback.calls.single as PlayTracksCall;
      expect(call.tracks.map((t) => t.value), [1, 3]);
      expect(call.shuffle, isFalse);
      expect(call.context.kind, PlayContextKind.mostPlayed);

      await _openPageMenu(tester);
      await tester.tap(find.text('Phát ngẫu nhiên'));
      await pumpMenu(tester);
      call = h.playback.calls.last as PlayTracksCall;
      expect(call.shuffle, isTrue);
      expect(h.playback.calls, hasLength(2));
    });

    testWidgets('the hero Play does the same', (tester) async {
      final h = await pumpMostPlayed(
        tester,
        top: topList([topEntry(1), topEntry(2)]),
      );
      await tester.tap(find.text('Phát'));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      final call = h.playback.calls.single as PlayTracksCall;
      expect(call.tracks.map((t) => t.value), [1, 2]);
    });

    testWidgets('Thêm vào playlist… offers the songs under the range name', (
      tester,
    ) async {
      await pumpMostPlayed(tester, top: topList([topEntry(1), topEntry(2)]));
      await _openPageMenu(tester);
      await tester.tap(find.text('Thêm vào playlist…'));
      await pumpMenu(tester);
      expect(find.textContaining('Nghe nhiều nhất · 30 ngày'), findsOneWidget);
    });

    testWidgets('Thêm tất cả vào Yêu thích sets them and says how many were '
        'added and skipped', (tester) async {
      final favorites = _Favorites();
      await pumpMostPlayed(
        tester,
        top: topList([topEntry(1), topEntry(2), topEntry(3)]),
        overrides: [
          favoritesControllerProvider.overrideWithValue(favorites),
          favoriteTrackIdsProvider.overrideWith(
            (ref) => Stream.value({TrackId(2)}),
          ),
        ],
      );
      await _openPageMenu(tester);
      await tester.tap(find.text('Thêm tất cả vào Yêu thích'));
      await pumpMenu(tester);
      expect(favorites.calls.single.$1.map((t) => t.value), [1, 2, 3]);
      expect(favorites.calls.single.$2, isTrue);
      expect(
        find.text('Đã thêm 2 bài vào Yêu thích, bỏ qua 1'),
        findsOneWidget,
      );
    });

    testWidgets('a failed favourite write says so', (tester) async {
      final favorites = _Favorites()..error = StateError('db');
      await pumpMostPlayed(
        tester,
        top: topList([topEntry(1)]),
        overrides: [
          favoritesControllerProvider.overrideWithValue(favorites),
          favoriteTrackIdsProvider.overrideWith((ref) => Stream.value({})),
        ],
      );
      await _openPageMenu(tester);
      await tester.tap(find.text('Thêm tất cả vào Yêu thích'));
      await pumpMenu(tester);
      expect(find.text('Không thêm được vào Yêu thích'), findsOneWidget);
    });

    testWidgets('a row adds the song\'s history to the song menu and has no '
        'Delete key removal', (tester) async {
      await pumpMostPlayed(tester, top: topList([topEntry(7)]));
      final tile = tester.widget<SongTile>(find.byType(SongTile));
      expect([for (final r in tile.menuExtras) r.title], ['Lịch sử bài này']);
      expect(
        tile.menuExtras.single.action,
        MenuAction.go(HistoryLocations.mostPlayedTrack(7)),
      );
      expect(tile.onDelete, isNull);
      expect(tile.onMenu, isNull);
    });

    testWidgets('a missing row\'s ⋮ holds only the song\'s history', (
      tester,
    ) async {
      await pumpMostPlayed(
        tester,
        width: 1400,
        top: topList([
          topEntry(
            1,
            track: info(1, title: 'Gone', status: TrackAvailability.missing),
          ),
        ]),
      );
      await tester.tap(_rowMenuButton(tester, 'Gone'));
      await pumpMenu(tester);
      expect(find.text('Lịch sử bài này'), findsOneWidget);
      expect(find.text('Thêm vào playlist…'), findsNothing);
    });
  });
}
