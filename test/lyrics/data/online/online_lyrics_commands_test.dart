import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/lyrics/data/lyrics_choice_store.dart';
import 'package:kanaru/src/lyrics/data/online/online_cache_store.dart';
import 'package:kanaru/src/lyrics/data/online/online_lyrics_commands.dart';
import 'package:kanaru/src/lyrics/data/online/pin_store.dart';
import 'package:kanaru/src/lyrics/data/online/reject_store.dart';
import 'package:kanaru/src/lyrics/data/online/store_result.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_candidate.dart';
import 'package:kanaru/src/lyrics/domain/online/online_lyrics_ref.dart';
import 'package:kanaru/src/lyrics/domain/online/online_text.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../../database/support/test_db.dart';
import '../../support/online_lookup_rig.dart' show inlineLyrics;

void main() {
  late AppDatabase db;
  late TrackId track;
  late OnlineLyricsCommands commands;
  late PinStore pins;
  late OnlineCacheStore cache;
  late RejectStore rejects;
  OnlineLyricsRef? shown;
  final rejectedKeys = <String>[];

  setUp(() async {
    db = openTestDb();
    track = TrackId(await addTrack(db, await addSource(db), locator: 'a.flac'));
    pins = PinStore(db);
    cache = OnlineCacheStore(db);
    rejects = RejectStore(db);
    shown = null;
    rejectedKeys.clear();
    commands = OnlineLyricsCommands(
      db: db,
      pins: pins,
      cache: cache,
      rejects: rejects,
      now: () => 5000,
      shownOnline: (_) => shown,
      cacheKeyOf: (_) => 'key',
      onRejected: rejectedKeys.add,
      run: <R>(f) async => await f(),
    );
  });
  tearDown(() => db.close());

  LyricsCandidate result({LyricsBody? body}) => LyricsCandidate(
    providerId: 'p',
    remoteId: 'r1',
    title: 'Song',
    artist: 'Artist',
    duration: const Duration(seconds: 200),
    body: body ?? const LyricsBody(syncedLrc: inlineLyrics),
  );

  OnlineLyricsRef ref(OnlineHow how) => OnlineLyricsRef(
    providerId: 'p',
    providerName: 'P',
    remoteId: 'r1',
    how: how,
  );

  Future<void> cached() => cache.putFound(
    'key',
    'p',
    remoteId: 'r1',
    syncedText: inlineLyrics,
    remoteDurationMs: 200000,
    now: 1000,
  );

  test('keep pins the fetched text and drops a file choice', () async {
    await setLyricsFile(db, track, now: 1);
    expect(
      await commands.keep(track, result(), providerName: 'P'),
      StoreResult.stored,
    );
    final pin = (await pins.read(track))!;
    expect(
      (pin.providerId, pin.providerName, pin.remoteId, pin.syncedText),
      ('p', 'P', 'r1', inlineLyrics),
    );
    expect(pin.remoteDurationMs, 200000);
    expect(await db.select(db.trackLyricsChoices).get(), isEmpty);
  });

  test(
    'keep leaves an off choice alone and refuses a result with no lyrics',
    () async {
      await setLyricsOff(db, track, now: 1);
      await commands.keep(track, result(), providerName: 'P');
      expect(await db.select(db.trackLyricsChoices).get(), hasLength(1));
      expect(
        await commands.keep(
          track,
          result(body: const LyricsBody()),
          providerName: 'P',
        ),
        StoreResult.notStored,
      );
      expect(
        await commands.keep(const TrackId(9999), result(), providerName: 'P'),
        StoreResult.notStored,
      );
    },
  );

  test(
    'keepAuto pins the cached copy with the source name it has now',
    () async {
      await cached();
      shown = ref(OnlineHow.auto);
      expect(await commands.keepAuto(track), StoreResult.stored);
      final pin = (await pins.read(track))!;
      expect((pin.providerName, pin.syncedText), ('P', inlineLyrics));
      // The kept copy cannot be kept again from the cache path.
      shown = ref(OnlineHow.kept);
      expect(await commands.keepAuto(track), StoreResult.notStored);
    },
  );

  test(
    'reject: reject row, cache row gone, the lookup told; pin untouched',
    () async {
      await cached();
      await commands.keep(track, result(), providerName: 'P');
      shown = ref(OnlineHow.auto);
      await commands.reject(track);
      final row = (await rejects.list(track)).single;
      expect((row.providerId, row.remoteId), ('p', 'r1'));
      expect(
        row.contentHash,
        lyricsContentHash(parseOnlineText(synced: inlineLyrics)!.lines),
      );
      expect(await cache.readFresh('key', now: 6000), isEmpty);
      expect(await pins.read(track), isNotNull);
      expect(rejectedKeys, ['key']);
    },
  );

  test(
    'reject of the kept copy deletes the pin and the same cache row',
    () async {
      await cached();
      await commands.keep(track, result(), providerName: 'P');
      shown = ref(OnlineHow.kept);
      await commands.reject(track);
      expect(await pins.read(track), isNull);
      expect(await cache.readFresh('key', now: 6000), isEmpty);
      expect(await rejects.list(track), hasLength(1));
    },
  );

  test('reject keeps a cache row of another result of that source', () async {
    await cache.putFound(
      'key',
      'p',
      remoteId: 'other',
      syncedText: inlineLyrics,
      now: 1000,
    );
    await commands.keep(track, result(), providerName: 'P');
    shown = ref(OnlineHow.kept);
    await commands.reject(track);
    expect(await cache.readFresh('key', now: 6000), hasLength(1));
  });

  test('reject with nothing online shown does nothing', () async {
    await commands.reject(track);
    expect(await rejects.list(track), isEmpty);
    expect(rejectedKeys, isEmpty);
  });

  test('useFile and useOnline write the choice', () async {
    await commands.useFile(track);
    expect((await db.select(db.trackLyricsChoices).get()).single.mode, 'file');
    await commands.useOnline(track);
    expect(await db.select(db.trackLyricsChoices).get(), isEmpty);
  });
}
