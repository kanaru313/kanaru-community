import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/lyrics/data/online/online_cache_store.dart';
import 'package:kanaru/src/lyrics/data/online/pin_store.dart';
import 'package:kanaru/src/lyrics/domain/embedded_lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/state/lyrics_choice_commands.dart';
import 'package:kanaru/src/lyrics/state/lyrics_settings.dart';
import 'package:kanaru/src/lyrics/state/online/lyrics_sources_provider.dart';
import 'package:kanaru/src/lyrics/state/online/online_commands_provider.dart';
import 'package:kanaru/src/lyrics/state/online/online_lookup_providers.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import '../support/fake_plugin_runner.dart';
import '../support/lyrics_harness.dart';
import '../support/online_lookup_rig.dart' show songTarget;

void main() {
  late LyricsHarness h;
  setUp(() => h = LyricsHarness());
  tearDown(() => h.dispose());

  /// A track tagged Song / Artist, 200 s.
  Future<TrackId> song(String locator, {String title = 'Song'}) async {
    final id = await h.addTrackRow(locator);
    await (h.db.update(h.db.tracks)..where((t) => t.id.equals(id.value))).write(
      TracksCompanion(
        title: Value(title),
        artist: const Value('Artist'),
        durationMs: const Value(200000),
      ),
    );
    return id;
  }

  ProviderSubscription<TrackLyrics> watch(TrackId id) =>
      h.container.listen(trackLyricsProvider(id), (_, _) {});

  Future<void> settled(ProviderSubscription<TrackLyrics> sub) async {
    await h.until(() => sub.read() is! LyricsLoading);
  }

  test(
    'a playing track with no lyrics: searching, then the online lyrics, cached',
    () async {
      final plugin = await h.installLyrics('lrclib');
      h.runner.answer(
        plugin,
        'search',
        searchAnswer([searchItem(lyrics: '[00:01.00] hello')]),
      );
      final id = await song('a.flac');
      h.play(id);
      final seen = <TrackLyrics>[];
      final sub = h.container.listen(
        trackLyricsProvider(id),
        (_, n) => seen.add(n),
        fireImmediately: true,
      );
      await h.until(() => sub.read() is LyricsShown);
      expect(seen.whereType<LyricsSearching>(), isNotEmpty);
      final shown = (sub.read() as LyricsShown).lyrics;
      expect(shown.origin, LyricsOrigin.online);
      expect(shown.online!.providerId, plugin);
      expect(shown.lines.single.text, 'hello');
      expect(await h.db.select(h.db.onlineLyrics).get(), hasLength(1));

      // Shown again later: from the cache, no run.
      sub.close();
      final before = h.runner.calls.length;
      final again = watch(id);
      await h.until(() => again.read() is LyricsShown);
      expect(h.runner.calls.length, before);
    },
  );

  test('a track that is not playing never starts a lookup', () async {
    final plugin = await h.installLyrics('lrclib');
    h.runner.answer(plugin, 'search', searchAnswer([searchItem(lyrics: 'x')]));
    final id = await song('a.flac');
    final other = await song('b.flac', title: 'Other');
    h.play(other);
    final sub = watch(id);
    await settled(sub);
    await h.until(() => sub.read() is! LyricsSearching);
    await pumpEventQueue();
    expect(sub.read(), const LyricsNone(reason: LyricsNoneReason.notPlaying));
    expect(
      h.runner.calls.where((c) => (c.input! as Map)['title'] == 'Song'),
      isEmpty,
    );
    expect(h.runner.calls, isEmpty);
  });

  test('local lyrics come first and no lookup starts', () async {
    final plugin = await h.installLyrics('lrclib');
    final id = await song('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(
      text: '[00:01.00]file',
    );
    h.play(id);
    final sub = watch(id);
    await h.until(() => sub.read() is LyricsShown);
    await pumpEventQueue();
    expect((sub.read() as LyricsShown).lyrics.origin, LyricsOrigin.tag);
    expect(h.runner.callsOf(plugin), 0);
  });

  Future<void> keepPin(TrackId id, String plugin) => PinStore(h.db)
      .put(
        id,
        providerId: plugin,
        providerName: 'lrclib',
        remoteId: 'k',
        syncedText: '[00:01.00] kept',
        now: 1,
      )
      .then((_) {});

  test('a kept copy beats the file; the file choice beats the kept copy; no lookup', () async {
    final plugin = await h.installLyrics('lrclib');
    final id = await song('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(
      text: '[00:01.00]file',
    );
    await keepPin(id, plugin);
    h.play(id);
    final sub = watch(id);
    await h.until(() => sub.read() is LyricsShown);
    expect((sub.read() as LyricsShown).lyrics.online!.how.name, 'kept');
    await h.container.read(lyricsChoiceCommandsProvider).setFile(id);
    await h.until(
      () => (sub.read() as LyricsShown).lyrics.origin == LyricsOrigin.tag,
    );
    await pumpEventQueue();
    expect(h.runner.calls, isEmpty);
  });

  test('off wins; clearing it shows the automatic result', () async {
    final plugin = await h.installLyrics('lrclib');
    final id = await song('a.flac');
    await keepPin(id, plugin);
    await h.container.read(lyricsChoiceCommandsProvider).setOff(id);
    h.play(id);
    final sub = watch(id);
    await h.until(() => sub.read() is LyricsOff);
    expect((sub.read() as LyricsOff).available, isNotNull);
    expect(h.runner.calls, isEmpty);
  });

  test(
    'every source says not found: LyricsNotFound, cached, no second run',
    () async {
      final a = await h.installLyrics('a');
      final b = await h.installLyrics('b');
      h.runner.answer(a, 'search', searchAnswer([]));
      h.runner.answer(b, 'search', searchAnswer([]));
      final id = await song('a.flac');
      h.play(id);
      final sub = watch(id);
      await h.until(() => sub.read() is LyricsNotFound);
      expect(sub.read(), const LyricsNotFound(asked: 2, off: 0));
      expect(h.runner.calls, hasLength(2));
      await pumpEventQueue();
      expect(h.runner.calls, hasLength(2), reason: 'no loop on rebuilds');
    },
  );

  test('a failing source ends as LyricsLookupFailed, not a spinner', () async {
    final a = await h.installLyrics('a');
    h.runner.answer(a, 'search', const RunFailed(RunFailReason.timeout));
    final id = await song('a.flac');
    h.play(id);
    final sub = watch(id);
    await h.until(() => sub.read() is LyricsLookupFailed);
    expect(h.runner.calls, hasLength(1));
    await pumpEventQueue();
    expect(h.runner.calls, hasLength(1));
    expect(await h.db.select(h.db.onlineLyrics).get(), isEmpty);
  });

  test(
    'no plugin installed is LyricsNoSource; auto off is LyricsNone',
    () async {
      final id = await song('a.flac');
      h.play(id);
      final sub = watch(id);
      await h.until(() => sub.read() is LyricsNoSource);
      await h.installLyrics('lrclib');
      await h.container.read(lyricsAutoSearchProvider.notifier).set(false);
      await h.until(() => sub.read() is LyricsNone);
      expect(h.runner.calls, isEmpty);
    },
  );

  test('a track without title or duration is not searchable', () async {
    final plugin = await h.installLyrics('lrclib');
    final id = await h.addTrackRow('a.flac');
    h.play(id);
    final sub = watch(id);
    await h.until(() => sub.read() is LyricsNone);
    expect(
      sub.read(),
      const LyricsNone(reason: LyricsNoneReason.notSearchable),
    );
    expect(h.runner.callsOf(plugin), 0);
  });

  test('skipping to another track cancels the old lookup', () async {
    final plugin = await h.installLyrics('lrclib');
    h.runner.blockUntilCancelled(plugin, 'search');
    final one = await song('a.flac', title: 'One');
    final two = await song('b.flac', title: 'Two');
    h.play(one);
    final subOne = watch(one);
    await h.until(() => h.runner.calls.length == 1);
    subOne.close();
    h.play(two, entryId: 2);
    final subTwo = watch(two);
    await h.until(() => h.runner.cancelled.length == 1);
    await h.until(() => h.runner.calls.length == 2);
    expect((h.runner.calls.last.input! as Map)['title'], 'Two');
    subTwo.close();
  });

  test('two tracks of one song share the lookup and one cache row', () async {
    final plugin = await h.installLyrics('lrclib');
    h.runner.answer(
      plugin,
      'search',
      searchAnswer([searchItem(lyrics: '[00:01.00] shared')]),
    );
    final one = await song('a.flac');
    final two = await song('b.flac');
    h.play(one);
    final subOne = watch(one);
    await h.until(() => subOne.read() is LyricsShown);
    final subTwo = watch(two);
    await h.until(() => subTwo.read() is LyricsShown);
    expect(h.runner.callsOf(plugin), 1);
    expect(await h.db.select(h.db.onlineLyrics).get(), hasLength(1));
  });

  test('a track the user rejected a result for does not show it from the shared row', () async {
    final plugin = await h.installLyrics('lrclib');
    final one = await song('a.flac');
    final two = await song('b.flac');
    h.play(two);
    final key = songTarget().cacheKey;
    await OnlineCacheStore(h.db).putFound(
      key,
      plugin,
      remoteId: 'x',
      syncedText: '[00:01.00] shared',
      remoteDurationMs: 200000,
      now: h.clock.millisecondsSinceEpoch,
    );
    h.runner.answer(plugin, 'search', searchAnswer([]));
    await h.container
        .read(rejectStoreProvider)
        .add(one, providerId: plugin, remoteId: 'x', now: 1);
    final subOne = watch(one);
    final subTwo = watch(two);
    await h.until(() => subTwo.read() is LyricsShown);
    expect(subOne.read(), isNot(isA<LyricsShown>()));
  });

  group('retry', () {
    test(
      'a failed lookup of the playing track is retried at retryAt',
      () async {
        final plugin = await h.installLyrics('a');
        h.runner.answer(
          plugin,
          'search',
          const RunFailed(RunFailReason.timeout),
        );
        final id = await song('a.flac');
        h.play(id);
        final sub = watch(id);
        await h.until(() => sub.read() is LyricsLookupFailed);
        expect(h.runner.calls, hasLength(1));
        final wake = h.wakeTimers.where((t) => t.isActive).single;
        expect(wake.after, const Duration(seconds: 60, milliseconds: 1));

        // Nobody holds the lookup: the timer alone brings it back.
        h.runner.answer(
          plugin,
          'search',
          searchAnswer([searchItem(lyrics: '[00:01.00] back')]),
        );
        h.clock = h.clock.add(const Duration(seconds: 61));
        wake.fire();
        await h.until(() => sub.read() is LyricsShown);
        expect(h.runner.calls, hasLength(2));
        expect(h.wakeTimers.where((t) => t.isActive), isEmpty);
      },
    );

    test('a track that is not playing arms nothing', () async {
      final plugin = await h.installLyrics('a');
      h.runner.answer(plugin, 'search', const RunFailed(RunFailReason.timeout));
      final one = await song('a.flac', title: 'One');
      final two = await song('b.flac', title: 'Two');
      h.play(one);
      final sub = watch(one);
      await h.until(() => sub.read() is LyricsLookupFailed);
      expect(h.wakeTimers.where((t) => t.isActive), hasLength(1));
      h.play(two, entryId: 2);
      await h.until(() => h.wakeTimers.every((t) => !t.isActive));
      expect(sub.read(), isNot(isA<LyricsSearching>()));
      expect(h.runner.calls, hasLength(1));
    });

    test('a rebuilt lookups service starts with no recorded end', () async {
      final plugin = await h.installLyrics('a');
      h.runner.answer(plugin, 'search', const RunFailed(RunFailReason.timeout));
      final id = await song('a.flac');
      h.play(id);
      final sub = watch(id);
      await h.until(() => sub.read() is LyricsLookupFailed);
      expect(h.container.read(lookupOutcomesProvider), isNotEmpty);
      h.container.invalidate(onlineLookupsProvider);
      await pumpEventQueue();
      expect(h.container.read(lookupOutcomesProvider), isEmpty);
    });
  });

  test('plugin rows touched without a source change keep the run', () async {
    final plugin = await h.installLyrics('a');
    h.runner.blockUntilCancelled(plugin, 'search');
    final id = await song('a.flac');
    h.play(id);
    watch(id);
    await h.until(() => h.runner.calls.length == 1);
    await h.db.customStatement(
      'UPDATE plugins SET updated_at = updated_at + 1',
    );
    // The list is rebuilt (a new list with the same sources).
    final before = h.container.read(lyricsSourcesProvider);
    h.container.invalidate(lyricsSourcesProvider);
    expect(identical(h.container.read(lyricsSourcesProvider), before), isFalse);
    await pumpEventQueue();
    await pumpEventQueue();
    expect(h.runner.cancelled, isEmpty);
    expect(h.runner.calls, hasLength(1));
  });

  test(
    'a miss over a found row this track refused ends as not found',
    () async {
      final plugin = await h.installLyrics('lrclib');
      final id = await song('a.flac');
      await OnlineCacheStore(h.db).putFound(
        songTarget().cacheKey,
        plugin,
        remoteId: 'x',
        syncedText: '[00:01.00] shared',
        remoteDurationMs: 200000,
        now: h.clock.millisecondsSinceEpoch,
      );
      h.runner.answer(plugin, 'search', searchAnswer([]));
      await h.container
          .read(rejectStoreProvider)
          .add(id, providerId: plugin, remoteId: 'x', now: 1);
      h.play(id);
      final sub = watch(id);
      await h.until(() => sub.read() is LyricsNotFound);
      expect(h.runner.calls, hasLength(1));
      await pumpEventQueue();
      expect(h.runner.calls, hasLength(1), reason: 'no loop');
      final rows = await h.db.select(h.db.onlineLyrics).get();
      expect(rows.single.remoteId, 'x', reason: 'the shared row stays');
    },
  );

  group('a not-found end over a refused shared row', () {
    Future<(String, ProviderSubscription<TrackLyrics>)> reach() async {
      final plugin = await h.installLyrics('lrclib');
      final b = await song('b.flac');
      await OnlineCacheStore(h.db).putFound(
        songTarget().cacheKey,
        plugin,
        remoteId: 'x',
        syncedText: '[00:01.00] shared',
        remoteDurationMs: 200000,
        now: h.clock.millisecondsSinceEpoch,
      );
      h.runner.answer(plugin, 'search', searchAnswer([]));
      await h.container
          .read(rejectStoreProvider)
          .add(b, providerId: plugin, remoteId: 'x', now: 1);
      h.play(b);
      final sub = watch(b);
      await h.until(() => sub.read() is LyricsNotFound);
      return (plugin, sub);
    }

    test('a new source drops the end and is asked', () async {
      final (_, sub) = await reach();
      final two = await h.installLyrics('two');
      h.runner.answer(
        two,
        'search',
        searchAnswer([searchItem(lyrics: '[00:01.00] two')]),
      );
      await h.until(() => sub.read() is LyricsShown);
      expect((sub.read() as LyricsShown).lyrics.online!.providerId, two);
    });

    test(
      'another track rejecting the shared row makes this one ask again',
      () async {
        final (plugin, sub) = await reach();
        final a = await song('a.flac');
        final subA = watch(a);
        await h.until(() => subA.read() is LyricsShown);
        final before = h.runner.calls.length;
        h.runner.answer(
          plugin,
          'search',
          searchAnswer([searchItem(id: 'y', lyrics: '[00:01.00] y')]),
        );
        await h.container.read(onlineLyricsCommandsProvider).reject(a);
        await h.until(() => sub.read() is LyricsShown);
        expect(h.runner.calls.length, greaterThan(before));
      },
    );

    test('auto search off then on asks once, no loop', () async {
      final (_, sub) = await reach();
      final before = h.runner.calls.length;
      final auto = h.container.read(lyricsAutoSearchProvider.notifier);
      await auto.set(false);
      await h.until(() => sub.read() is LyricsNone);
      await auto.set(true);
      await h.until(() => h.runner.calls.length > before);
      await h.until(() => sub.read() is LyricsNotFound);
      for (var i = 0; i < 10; i++) {
        await pumpEventQueue();
      }
      expect(h.runner.calls.length, before + 1);
    });
  });
}
