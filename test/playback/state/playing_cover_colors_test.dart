import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/playback/domain/now_playing.dart';
import 'package:kanaru/src/playback/state/cover_providers.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/player_ready.dart';
import 'package:kanaru/src/playback/state/playing_cover_colors.dart';
import 'package:kanaru/src/playback/state/track_info_providers.dart';

class _Phase extends PlayerPhaseNotifier {
  _Phase(this._initial);
  final PlayerPhase _initial;

  @override
  PlayerPhase build() => _initial;

  void set(PlayerPhase p) => state = p;
}

TrackInfo _info(int id, String? coverKey) => TrackInfo(
  id: TrackId(id),
  title: 't$id',
  status: TrackAvailability.present,
  relPath: 't$id.mp3',
  coverKey: coverKey,
);

NowPlaying _np(int? id) => id == null
    ? NowPlaying.none
    : NowPlaying(entryId: id, trackId: TrackId(id), playing: true);

const _red = CoverColors(seed: 0xFFC62828, palette: [0xFFC62828]);
const _blue = CoverColors(seed: 0xFF1E88E5, palette: [0xFF1E88E5]);

void main() {
  late StreamController<NowPlaying> nowFeed;
  late Map<int, StreamController<TrackInfo?>> infoFeeds;
  late Map<String, StreamController<CoverColors?>> colorFeeds;
  late ProviderContainer c;
  late List<PlayingCoverColors> seen;
  late _Phase phase;

  void build({PlayerPhase initial = PlayerPhase.ready}) {
    phase = _Phase(initial);
    c = ProviderContainer(
      overrides: [
        playerPhaseProvider.overrideWith(() => phase),
        nowPlayingProvider.overrideWith((ref) => nowFeed.stream),
        trackInfoProvider.overrideWith(
          (ref, id) =>
              (infoFeeds[id.value] ??= StreamController<TrackInfo?>()).stream,
        ),
        coverColorsProvider.overrideWith(
          (ref, key) =>
              (colorFeeds[key] ??= StreamController<CoverColors?>()).stream,
        ),
      ],
    );
    addTearDown(c.dispose);
    seen = [];
    c.listen(playingCoverColorsProvider, (_, v) => seen.add(v));
  }

  Future<void> settle() => pumpEventQueue();

  setUp(() {
    nowFeed = StreamController<NowPlaying>();
    infoFeeds = {};
    colorFeeds = {};
  });

  // A close() that nobody listens to never completes, so it is not awaited.
  tearDown(() {
    unawaited(nowFeed.close());
    for (final f in [...infoFeeds.values]) {
      unawaited(f.close());
    }
    for (final f in [...colorFeeds.values]) {
      unawaited(f.close());
    }
  });

  PlayingCoverColors value() => c.read(playingCoverColorsProvider);

  test('before the player is ready it is pending and reads nothing', () async {
    build(initial: PlayerPhase.notCreated);
    nowFeed.add(_np(1));
    await settle();
    expect(value(), const PlayingCoverColorsPending());
    // Not even the player's stream was subscribed.
    expect(nowFeed.hasListener, isFalse);
    phase.set(PlayerPhase.restoring);
    await settle();
    expect(value(), const PlayingCoverColorsPending());
  });

  test('restore to a coloured track gives its colours', () async {
    build(initial: PlayerPhase.restoring);
    phase.set(PlayerPhase.ready);
    nowFeed.add(_np(1));
    await settle();
    infoFeeds[1]!.add(_info(1, 'a'));
    await settle();
    expect(value(), const PlayingCoverColorsPending());
    colorFeeds['a']!.add(_red);
    await settle();
    expect(value(), const PlayingCoverColorsFound(_red));
  });

  test(
    'settled with nothing playing, no cover or no colours is none',
    () async {
      build();
      expect(value(), const PlayingCoverColorsPending());
      nowFeed.add(NowPlaying.none);
      await settle();
      expect(value(), const PlayingCoverColorsNone());

      nowFeed.add(_np(2));
      await settle();
      infoFeeds[2]!.add(_info(2, null));
      await settle();
      expect(value(), const PlayingCoverColorsNone());

      nowFeed.add(_np(3));
      await settle();
      infoFeeds[3]!.add(_info(3, 'gray'));
      await settle();
      expect(value(), const PlayingCoverColorsPending());
      colorFeeds['gray']!.add(null);
      await settle();
      expect(value(), const PlayingCoverColorsNone());
    },
  );

  test('a skip between coloured covers is never none, also while the '
      'track info loads', () async {
    build();
    nowFeed.add(_np(1));
    await settle();
    infoFeeds[1]!.add(_info(1, 'a'));
    colorFeeds['a'] = StreamController<CoverColors?>()..add(_red);
    await settle();
    expect(value(), const PlayingCoverColorsFound(_red));
    seen.clear();

    nowFeed.add(_np(2));
    await settle();
    infoFeeds[2]!.add(_info(2, 'b'));
    await settle();
    colorFeeds['b']!.add(_blue);
    await settle();
    expect(seen, [
      const PlayingCoverColorsPending(),
      const PlayingCoverColorsFound(_blue),
    ]);
  });

  test(
    'fast skip A, B, C: a late answer for B never shows, B is dropped',
    () async {
      build();
      nowFeed.add(_np(1));
      await settle();
      nowFeed.add(_np(2));
      await settle();
      nowFeed.add(_np(3));
      await settle();
      // B's streams lost their listeners when the track changed.
      expect(infoFeeds[2]!.hasListener, isFalse);
      infoFeeds[2]!.add(_info(2, 'b'));
      await settle();
      expect(value(), const PlayingCoverColorsPending());

      infoFeeds[3]!.add(_info(3, 'c'));
      await settle();
      colorFeeds['c']!.add(_red);
      await settle();
      expect(value(), const PlayingCoverColorsFound(_red));
      expect(seen.whereType<PlayingCoverColorsFound>().map((f) => f.colors), [
        _red,
      ]);
      expect(colorFeeds.containsKey('b'), isFalse);
    },
  );

  test('an answer about another track is not used', () async {
    build();
    nowFeed.add(_np(1));
    await settle();
    infoFeeds[1]!.add(_info(9, 'other'));
    await settle();
    expect(value(), const PlayingCoverColorsNone());
    expect(colorFeeds.containsKey('other'), isFalse);
  });

  test('colours computed later re-theme the same track', () async {
    build();
    nowFeed.add(_np(1));
    await settle();
    infoFeeds[1]!.add(_info(1, 'a'));
    await settle();
    colorFeeds['a']!.add(null);
    await settle();
    expect(value(), const PlayingCoverColorsNone());
    colorFeeds['a']!.add(_blue);
    await settle();
    expect(value(), const PlayingCoverColorsFound(_blue));
  });

  test('play and pause do not notify', () async {
    build();
    nowFeed.add(_np(1));
    await settle();
    infoFeeds[1]!.add(_info(1, 'a'));
    await settle();
    colorFeeds['a']!.add(_red);
    await settle();
    seen.clear();
    nowFeed.add(const NowPlaying(entryId: 1, trackId: TrackId(1)));
    await settle();
    expect(seen, isEmpty);
  });
}
