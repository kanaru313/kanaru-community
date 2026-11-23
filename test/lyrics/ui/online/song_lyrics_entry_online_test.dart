import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/lyrics/data/local_lyrics_read.dart';
import 'package:kanaru/src/lyrics/data/lyrics_choice_store.dart';
import 'package:kanaru/src/lyrics/data/lyrics_loader.dart';
import 'package:kanaru/src/lyrics/data/online/pin_store.dart';
import 'package:kanaru/src/lyrics/domain/embedded_lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/lyrics_loader_provider.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/song_lyrics_entry_impl.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';

import '../../../database/support/test_db.dart';
import '../../../support/memory_settings_store.dart';
import '../../support/fake_local_lyrics_reader.dart';
import 'online_ui_overrides.dart';

void main() {
  late AppDatabase db;
  late TrackId track;
  late FakeLocalLyricsReader reader;
  late LyricsLoader loader;
  final en = AppLocalizationsEn();
  final vi = AppLocalizationsVi();
  const entry = LyricsSongEntry();

  ProviderContainer container([PlayingLyrics? playing]) {
    final c = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        lyricsLoaderProvider.overrideWithValue(loader),
        if (playing != null) playingLyricsProvider.overrideWithValue(playing),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() async {
    db = openTestDb();
    track = TrackId(await addTrack(db, await addSource(db), locator: 'a.flac'));
    reader = FakeLocalLyricsReader();
    loader = LyricsLoader(reader);
  });
  tearDown(() => db.close());

  Future<void> keep({
    String? synced,
    String? plain,
    bool instrumental = false,
  }) => PinStore(db).put(
    track,
    providerId: 'netease',
    providerName: 'NetEase',
    remoteId: 'r1',
    syncedText: synced,
    plainText: plain,
    instrumental: instrumental,
    now: 1,
  );

  test('a kept synced copy: "NetEase · Đồng bộ", nothing read', () async {
    await keep(synced: '[00:01.00]hello');
    expect(await entry.label(db, container(), track, vi), 'NetEase · Đồng bộ');
    expect(reader.tagReads, isEmpty);
    expect(reader.stats, isEmpty);
  });

  test('a kept plain copy: "NetEase · Thường"', () async {
    await keep(plain: 'hello');
    expect(await entry.label(db, container(), track, vi), 'NetEase · Thường');
  });

  test(
    'the kind comes from the parsed copy, not from which column holds it',
    () async {
      // Stored as "synced" but without a single time tag: it parses as plain.
      await keep(synced: 'just words');
      expect(await entry.label(db, container(), track, vi), 'NetEase · Thường');
    },
  );

  test('a kept instrumental copy says so', () async {
    await keep(instrumental: true);
    expect(await entry.label(db, container(), track, en), 'Instrumental');
  });

  test('the file chosen over a kept copy: the file label wins', () async {
    await keep(synced: '[00:01.00]hello');
    await setLyricsFile(db, track, now: 2);
    reader.tags['/m/a.flac'] = const EmbeddedLyrics(text: 'plain tag');
    await loader.load(
      LyricsRequest(
        trackId: track,
        audioPath: '/m/a.flac',
        trackRevision: 'r1',
        lrcPath: null,
      ),
    );
    expect(
      await entry.label(db, container(), track, en),
      'Lyrics in tag · Plain',
    );
  });

  test('lyrics off beats a kept copy', () async {
    await keep(synced: '[00:01.00]hello');
    await setLyricsOff(db, track, now: 2);
    expect(await entry.label(db, container(), track, en), 'Lyrics off');
  });

  test('the playing song shows online lyrics found automatically', () async {
    final playing = PlayingLyrics(
      entryId: 1,
      trackId: track,
      lyrics: LyricsShown(onlineLyrics(name: 'LRCLIB')),
    );
    expect(
      await entry.label(db, container(playing), track, en),
      'LRCLIB · Synced',
    );
  });

  test('another song playing online does not label this one', () async {
    final playing = PlayingLyrics(
      entryId: 2,
      trackId: const TrackId(999),
      lyrics: LyricsShown(onlineLyrics()),
    );
    expect(await entry.label(db, container(playing), track, en), isNull);
  });
}
