import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/lyrics/data/local_lyrics_read.dart';
import 'package:kanaru/src/lyrics/data/lyrics_choice_store.dart';
import 'package:kanaru/src/lyrics/data/lyrics_loader.dart';
import 'package:kanaru/src/lyrics/domain/embedded_lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/lyrics_loader_provider.dart';
import 'package:kanaru/src/lyrics/state/playing_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/lyrics/ui/song_lyrics_entry_impl.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../database/support/test_db.dart';
import '../../support/memory_settings_store.dart';
import '../support/fake_local_lyrics_reader.dart';

/// The playing entry, moved by the test.
class _Playing extends Notifier<PlayingLyrics> {
  @override
  PlayingLyrics build() => const PlayingLyrics(
    entryId: 1,
    trackId: TrackId(1),
    lyrics: LyricsNone(),
  );

  void play(int entry) => state = PlayingLyrics(
    entryId: entry,
    trackId: TrackId(entry),
    lyrics: const LyricsNone(),
  );
}

void main() {
  late AppDatabase db;
  late TrackId track;
  late FakeLocalLyricsReader reader;
  late LyricsLoader loader;
  late ProviderContainer container;
  final l10n = AppLocalizationsEn();
  const entry = LyricsSongEntry();

  setUp(() async {
    db = openTestDb();
    track = TrackId(await addTrack(db, await addSource(db), locator: 'a.flac'));
    reader = FakeLocalLyricsReader();
    loader = LyricsLoader(reader);
    container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(MemorySettingsStore()),
        lyricsLoaderProvider.overrideWithValue(loader),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  LyricsRequest request() => LyricsRequest(
    trackId: track,
    audioPath: '/m/a.flac',
    trackRevision: 'r1',
    lrcPath: null,
  );

  test('lyrics turned off for the song: the off label, nothing read', () async {
    await setLyricsOff(db, track, now: 1);
    expect(await entry.label(db, container, track, l10n), 'Lyrics off');
    expect(reader.tagReads, isEmpty);
    expect(reader.stats, isEmpty);
  });

  test('a read cached this session gives its label', () async {
    reader.tags['/m/a.flac'] = const EmbeddedLyrics(text: 'plain tag');
    await loader.load(request());
    final reads = reader.tagReads.length;
    expect(
      await entry.label(db, container, track, l10n),
      'Lyrics in tag · Plain',
    );
    expect(reader.tagReads, hasLength(reads));
  });

  test('a cached read without lyrics says there are none', () async {
    await loader.load(request());
    expect(await entry.label(db, container, track, l10n), 'No lyrics');
  });

  test('nothing cached: no label and no file read', () async {
    expect(await entry.label(db, container, track, l10n), isNull);
    expect(reader.tagReads, isEmpty);
    expect(reader.lrcReads, isEmpty);
    expect(reader.stats, isEmpty);
  });

  testWidgets('open shows the modal of that song and stays on it', (
    tester,
  ) async {
    final playing = NotifierProvider<_Playing, PlayingLyrics>(_Playing.new);
    final host = ProviderContainer(
      overrides: [
        trackLyricsProvider.overrideWith((ref, id) => const LyricsNone()),
        playingLyricsProvider.overrideWith((ref) => ref.watch(playing)),
      ],
    );
    addTearDown(host.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: host,
        child: MaterialApp(
          theme: buildKanaruTheme(brightness: Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => entry.open(context, const TrackId(1)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Lyrics for this song'), findsOneWidget);
    // Playback moves to another song: the modal stays.
    host.read(playing.notifier).play(2);
    await tester.pumpAndSettle();
    expect(find.text('Lyrics for this song'), findsOneWidget);
  });
}
