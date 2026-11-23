import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/online/online_cache_store.dart';
import 'package:kanaru/src/lyrics/data/online/online_row_mapper.dart';
import 'package:kanaru/src/lyrics/data/online/pin_store.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/online/lyrics_source.dart';
import 'package:kanaru/src/lyrics/domain/online/online_resolution.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../../../database/support/test_db.dart';

void main() {
  test('stored rows resolve to online lyrics, kept before cached', () async {
    final db = openTestDb();
    addTearDown(db.close);
    final track = TrackId(
      await addTrack(db, await addSource(db), locator: 'a'),
    );
    await PinStore(db).put(
      track,
      providerId: 'gone',
      providerName: 'Old',
      remoteId: 'r',
      syncedText: '[00:01.00] kept',
      now: 1,
    );
    final cache = OnlineCacheStore(db);
    await cache.putFound('k', 'p', remoteId: 'c', plainText: 'cached', now: 2);

    const sources = [
      LyricsSource(
        id: 'p',
        name: 'P',
        version: 1,
        origin: LyricsSourceOrigin.repo,
        enabled: true,
      ),
    ];
    final entries = [
      for (final r in await cache.readFresh('k', now: 3)) entryOfRow(r),
    ];
    final pin = pickOfRow((await PinStore(db).read(track))!);
    LyricsResolution resolve({bool withPin = true}) => resolveTrackLyrics(
      choice: null,
      pin: withPin ? pin : null,
      local: null,
      cache: entries,
      sources: sources,
      autoOn: true,
      autoSearchable: true,
      now: DateTime.fromMillisecondsSinceEpoch(3),
    );

    final kept = (resolve().state as LyricsShown).lyrics;
    expect(
      (kept.online!.providerName, kept.synced, kept.lines.single.text),
      ('Old', true, 'kept'),
    );
    final auto = (resolve(withPin: false).state as LyricsShown).lyrics;
    expect(
      (auto.online!.providerName, auto.synced, auto.lines.single.text),
      ('P', false, 'cached'),
    );
  });
}
