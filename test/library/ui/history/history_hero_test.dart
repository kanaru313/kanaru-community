import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/ui/history/history_hero.dart';
import 'package:kanaru/src/library/ui/detail/detail_header.dart';
import 'package:kanaru/src/library/ui/detail/detail_tint.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/playback/state/cover_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'history_page_harness.dart';

TrackInfo _song(int id, {String? cover, String? album}) => TrackInfo(
  id: TrackId(id),
  title: 'Song $id',
  status: TrackAvailability.present,
  relPath: 't$id.flac',
  coverKey: cover,
  albumKey: album == null ? null : AlbumKey('artist', album),
);

HistoryPlay _play(int id, {String? cover, String? album}) => playAt(
  id,
  testToday,
  track: _song(id, cover: cover, album: album),
);

void main() {
  group('historyCoverKeys', () {
    test('newest first, one per album, at most four', () {
      final keys = historyCoverKeys([
        _play(1, cover: 'c1', album: 'a'),
        _play(2, cover: 'c1b', album: 'a'),
        _play(3, cover: 'c2', album: 'b'),
        _play(4, cover: 'c3', album: 'c'),
        _play(5, cover: 'c4', album: 'd'),
        _play(6, cover: 'c5', album: 'e'),
      ]);
      expect(keys, ['c1', 'c2', 'c3', 'c4']);
    });

    test('a repeated cover key counts once', () {
      final keys = historyCoverKeys([
        _play(1, cover: 'same', album: 'a'),
        _play(2, cover: 'same', album: 'b'),
        _play(3, cover: 'c2', album: 'c'),
      ]);
      expect(keys, ['same', 'c2']);
    });

    test('songs without a cover are skipped; a song without an album is '
        'its own group', () {
      final keys = historyCoverKeys([
        _play(1),
        _play(2, cover: 'x'),
        _play(3, cover: 'y'),
      ]);
      expect(keys, ['x', 'y']);
    });

    test('a missing file is skipped', () {
      final missing = playAt(
        1,
        testToday,
        track: TrackInfo(
          id: TrackId(1),
          title: 'Gone',
          relPath: 'g.flac',
          coverKey: 'gone',
          status: TrackAvailability.missing,
        ),
      );
      expect(historyCoverKeys([missing, _play(2, cover: 'ok')]), ['ok']);
    });

    test('one key, many keys and none give 1, 2 to 4 and 0', () {
      expect(historyCoverKeys(const []), isEmpty);
      expect(historyCoverKeys([_play(1, cover: 'a', album: 'a')]), ['a']);
      expect(
        historyCoverKeys([
          for (var i = 1; i <= 3; i++) _play(i, cover: 'c$i', album: 'a$i'),
        ]),
        hasLength(3),
      );
    });
  });

  group('hero', () {
    for (final width in [400.0, 1280.0]) {
      testWidgets('uses the framed cover at width $width', (tester) async {
        await pumpHistoryPage(
          tester,
          byYear: {
            2026: playsOverDays([3]),
          },
          width: width,
        );
        final hero = tester.widget<KDetailHero>(find.byType(KDetailHero));
        expect(hero.framedCover, isTrue);
      });
    }

    testWidgets('tints the page from the first cover', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: [
            playAt(
              1,
              testToday,
              track: _song(1, cover: 'c1', album: 'a'),
            ),
            playAt(
              2,
              testToday,
              track: _song(2, cover: 'c2', album: 'b'),
            ),
          ],
        },
        overrides: <Override>[
          coverColorsProvider.overrideWith(
            (ref, key) => Stream.value(
              const CoverColors(seed: 0xFF445566, palette: [0xFF445566]),
            ),
          ),
        ],
      );
      final frame = tester.widget<DetailFrame>(find.byType(DetailFrame));
      expect(frame.tint, isNotNull);
      expect(frame.tint!.palette, isNotEmpty);
    });

    testWidgets('no cover: the page is not tinted', (tester) async {
      await pumpHistoryPage(
        tester,
        byYear: {
          2026: playsOverDays([2]),
        },
      );
      final frame = tester.widget<DetailFrame>(find.byType(DetailFrame));
      expect(frame.tint, DetailTint.none);
    });
  });
}
