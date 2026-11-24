import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/lyrics/data/online/pin_store.dart';
import 'package:kanaru/src/lyrics/domain/embedded_lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/online/online_lyrics_ref.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';
import 'package:kanaru/src/lyrics/state/lyrics_choice_commands.dart';
import 'package:kanaru/src/lyrics/state/stored_track_lyrics_provider.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

import '../support/lyrics_harness.dart';
import '../support/fake_plugin_runner.dart';

void main() {
  late LyricsHarness h;
  setUp(() => h = LyricsHarness());
  tearDown(() => h.dispose());

  Future<TrackId> song(String locator) async {
    final id = await h.addTrackRow(locator);
    await (h.db.update(h.db.tracks)..where((t) => t.id.equals(id.value))).write(
      const TracksCompanion(
        title: Value('Song'),
        artist: Value('Artist'),
        durationMs: Value(200000),
      ),
    );
    return id;
  }

  ProviderSubscription<TrackLyrics> stored(TrackId id) =>
      h.container.listen(storedTrackLyricsProvider(id), (_, _) {});

  test(
    'the playing track with no lyrics and auto search on starts no plugin',
    () async {
      final plugin = await h.installLyrics('lrclib');
      h.runner.answer(
        plugin,
        'search',
        searchAnswer([searchItem(lyrics: '[00:01.00] hello')]),
      );
      final id = await song('a.flac');
      h.play(id);
      final sub = stored(id);
      await h.until(() => sub.read() is! LyricsLoading);
      await pumpEventQueue();
      expect(sub.read(), const LyricsNone(reason: LyricsNoneReason.notPlaying));
      expect(h.runner.calls, isEmpty);
      sub.close();
    },
  );

  test(
    'the same setup through trackLyricsProvider does call the runner',
    () async {
      final plugin = await h.installLyrics('lrclib');
      h.runner.answer(
        plugin,
        'search',
        searchAnswer([searchItem(lyrics: '[00:01.00] hello')]),
      );
      final id = await song('a.flac');
      h.play(id);
      final sub = h.container.listen(trackLyricsProvider(id), (_, _) {});
      await h.until(() => sub.read() is LyricsShown);
      expect(h.runner.calls, isNotEmpty);
      sub.close();
    },
  );

  test('local lyrics are shown with the same selection rules', () async {
    final id = await song('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(
      text: '[00:01.00]hi',
    );
    h.play(id);
    final sub = stored(id);
    await h.until(() => sub.read() is LyricsShown);
    expect((sub.read() as LyricsShown).lyrics.origin, LyricsOrigin.tag);
    expect(h.runner.calls, isEmpty);
    sub.close();
  });

  test('a kept online copy shows and the file choice beats it', () async {
    final plugin = await h.installLyrics('lrclib');
    final id = await song('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(
      text: '[00:01.00]file',
    );
    await PinStore(h.db).put(
      id,
      providerId: plugin,
      providerName: 'lrclib',
      remoteId: 'k',
      syncedText: '[00:01.00] kept',
      now: 1,
    );
    h.play(id);
    final sub = stored(id);
    await h.until(() => sub.read() is LyricsShown);
    expect((sub.read() as LyricsShown).lyrics.online!.how.name, 'kept');
    await h.container.read(lyricsChoiceCommandsProvider).setFile(id);
    await h.until(
      () => (sub.read() as LyricsShown).lyrics.origin == LyricsOrigin.tag,
    );
    expect(h.runner.calls, isEmpty);
    sub.close();
  });

  test('off keeps what would show', () async {
    final id = await song('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(text: 'x');
    await h.container.read(lyricsChoiceCommandsProvider).setOff(id);
    final sub = stored(id);
    await h.until(() => sub.read() is LyricsOff);
    expect((sub.read() as LyricsOff).available, isNotNull);
    sub.close();
  });

  test(
    'a lookup started for Now Playing: stored stays empty, then repaints',
    () async {
      final plugin = await h.installLyrics('lrclib');
      final answer = Completer<RunOutcome>();
      h.runner.on(plugin, 'search', (_, _) => answer.future);
      final id = await song('a.flac');
      h.play(id);
      final seen = <TrackLyrics>[];
      final sub = h.container.listen(
        storedTrackLyricsProvider(id),
        (_, n) => seen.add(n),
      );
      final np = h.container.listen(trackLyricsProvider(id), (_, _) {});
      await h.until(() => h.runner.calls.isNotEmpty);
      await h.until(() => sub.read() is! LyricsLoading);
      expect(sub.read(), const LyricsNone(reason: LyricsNoneReason.notPlaying));
      answer.complete(searchAnswer([searchItem(lyrics: '[00:01.00] hello')]));
      await h.until(() => sub.read() is LyricsShown);
      final shown = (sub.read() as LyricsShown).lyrics;
      expect(shown.origin, LyricsOrigin.online);
      expect(shown.online!.how, OnlineHow.auto);
      // The result is cached: the stored view alone shows it later, no run.
      np.close();
      sub.close();
      final calls = h.runner.calls.length;
      final again = stored(id);
      await h.until(() => again.read() is LyricsShown);
      expect(h.runner.calls.length, calls);
      again.close();
    },
  );

  test('both providers on one track share one file read', () async {
    final id = await song('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(text: 'x');
    final a = stored(id);
    final b = h.container.listen(trackLyricsProvider(id), (_, _) {});
    await h.until(() => a.read() is LyricsShown && b.read() is LyricsShown);
    expect(h.reader.tagReads, hasLength(1));
    a.close();
    b.close();
  });
}
