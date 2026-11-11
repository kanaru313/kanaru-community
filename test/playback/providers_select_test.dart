import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/database.dart' hide CoverColors;
import 'package:kanaru/src/database/state/database_providers.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru/src/playback/state/cover_providers.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/track_info_providers.dart';

import '../database/support/test_db.dart';
import '../support/fake_playback_commands.dart';

NowPlaying _np(int track, {bool playing = true}) => NowPlaying(
  entryId: track * 10,
  trackId: TrackId(track),
  playing: playing,
  index: 0,
  length: 3,
);

void main() {
  group('now playing selects', () {
    late StreamController<NowPlaying> feed;
    late ProviderContainer c;
    setUp(() {
      feed = StreamController<NowPlaying>.broadcast();
      c = ProviderContainer(
        overrides: [nowPlayingProvider.overrideWith((ref) => feed.stream)],
      );
      addTearDown(c.dispose);
      addTearDown(feed.close);
    });

    test('a tile is notified only when its own answer changes', () async {
      final a = <bool>[], b = <bool>[];
      c.listen(isCurrentTrackProvider(TrackId(1)), (_, n) => a.add(n));
      c.listen(isCurrentTrackProvider(TrackId(2)), (_, n) => b.add(n));
      feed.add(_np(1));
      await pumpEventQueue();
      feed.add(_np(1, playing: false)); // pause: no tile changes
      await pumpEventQueue();
      feed.add(_np(2)); // track change: both flip
      await pumpEventQueue();
      expect(a, [true, false]);
      expect(b, [true]);
    });

    test('isPlaying and hasCurrentTrack follow the snapshot', () async {
      final playing = <bool>[], has = <bool>[];
      c.listen(isPlayingProvider, (_, n) => playing.add(n));
      c.listen(hasCurrentTrackProvider, (_, n) => has.add(n));
      feed.add(_np(1));
      await pumpEventQueue();
      feed.add(_np(1, playing: false));
      await pumpEventQueue();
      feed.add(NowPlaying.none);
      await pumpEventQueue();
      expect(playing, [true, false]);
      expect(has, [true, false]);
    });
  });

  group('family providers are disposed with their last listener', () {
    late AppDatabase db;
    late ProviderContainer c;
    setUp(() {
      db = openTestDb();
      // Registered first, so it runs after the container is disposed.
      addTearDown(db.close);
      c = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(c.dispose);
    });

    test('isCurrentTrack, trackInfo and coverColors', () async {
      final subs = [
        c.listen(isCurrentTrackProvider(TrackId(7)), (_, _) {}),
        c.listen(trackInfoProvider(TrackId(7)), (_, _) {}),
        c.listen(coverColorsProvider('aa/${'b' * 32}'), (_, _) {}),
      ];
      expect(c.read(isCurrentTrackProvider(TrackId(7)).exists), isTrue);
      expect(c.read(trackInfoProvider(TrackId(7)).exists), isTrue);
      for (final s in subs) {
        s.close();
      }
      await pumpEventQueue();
      expect(c.read(isCurrentTrackProvider(TrackId(7)).exists), isFalse);
      expect(c.read(trackInfoProvider(TrackId(7)).exists), isFalse);
      expect(c.read(coverColorsProvider('aa/${'b' * 32}').exists), isFalse);
    });

    test('coverColors streams the stored colours', () async {
      final key = 'aa/${'c' * 32}';
      final seen = <CoverColors?>[];
      c.listen(
        coverColorsProvider(key),
        (_, n) => seen.add(n.value),
        fireImmediately: true,
      );
      await pumpEventQueue();
      await upsertCoverColors(
        db,
        coverKey: key,
        seed: 5,
        colors: [1, 2],
        version: coverColorsVersion,
        now: 1,
      );
      await pumpEventQueue();
      expect(seen.last, const CoverColors(seed: 5, palette: [1, 2]));
    });
  });

  group('seeds', () {
    test('fake records calls and validates like the player', () async {
      final fake = FakePlaybackCommands();
      const ctx = PlayContext(PlayContextKind.songs);
      await fake.playTracks(
        [TrackId(1), TrackId(2)],
        startIndex: 1,
        context: ctx,
      );
      expect(fake.calls.single, isA<PlayTracksCall>());
      expect(
        () => fake.playTracks(const [], context: ctx),
        throwsArgumentError,
      );
      expect(
        () => fake.playTracks([TrackId(1)], startIndex: 1, context: ctx),
        throwsRangeError,
      );
      expect(fake.calls, hasLength(1));
    });
  });

  group('cover miss sink', () {
    test('keys reported before any listener go to the first one', () async {
      final sink = CoverMissSink();
      sink.report('early1');
      sink.report('early2');
      sink.report('early1'); // deduped
      final seen = <String>[];
      sink.misses.listen(seen.add);
      await pumpEventQueue();
      sink.report('late');
      await pumpEventQueue();
      expect(seen, ['early1', 'early2', 'late']);
      await sink.close();
    });

    test('the buffer keeps the newest keys', () async {
      final sink = CoverMissSink();
      for (var i = 0; i < coverMissBufferLimit + 5; i++) {
        sink.report('k$i');
      }
      final seen = <String>[];
      sink.misses.listen(seen.add);
      await pumpEventQueue();
      expect(seen, hasLength(coverMissBufferLimit));
      expect(seen.first, 'k5');
      await sink.close();
    });

    test('dedupes a key inside the window, not after it', () async {
      var now = DateTime(2026);
      final sink = CoverMissSink(now: () => now);
      final seen = <String>[];
      sink.misses.listen(seen.add);
      sink.report('k1');
      sink.report('k1');
      sink.report('k2');
      now = now.add(const Duration(seconds: 59));
      sink.report('k1');
      now = now.add(const Duration(seconds: 2));
      sink.report('k1');
      await pumpEventQueue();
      expect(seen, ['k1', 'k2', 'k1']);
      await sink.close();
      sink.report('k3'); // after close: ignored, no throw
    });
  });
}
