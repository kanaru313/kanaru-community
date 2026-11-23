import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/domain/online/online_search_state.dart';
import 'package:kanaru/src/lyrics/state/lyrics_settings.dart';
import 'package:kanaru/src/lyrics/state/online/online_lookup_providers.dart';
import 'package:kanaru/src/lyrics/state/online/online_search_provider.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import '../support/fake_plugin_runner.dart';
import '../support/lyrics_harness.dart';
import '../support/online_lookup_rig.dart' show inlineLyrics;

void main() {
  late LyricsHarness h;
  late TrackId track;

  Future<void> start({int? slots}) async {
    h = LyricsHarness(runnerSlots: slots);
    track = await h.addSongRow('a.flac');
  }

  tearDown(() => h.dispose());

  ProviderSubscription<OnlineSearchState> listen() =>
      h.container.listen(onlineSearchProvider(track), (_, _) {});

  OnlineSearchNotifier notifier() =>
      h.container.read(onlineSearchProvider(track).notifier);

  test('12 sources, 4 admitted at a time: none fails for queue time', () async {
    await start(slots: 4);
    final ids = [for (var i = 0; i < 12; i++) await h.installLyrics('s$i')];
    for (final id in ids) {
      h.runner.on(id, 'search', (_, _) async {
        await Future<void>.delayed(const Duration(milliseconds: 5));
        return searchAnswer([searchItem(id: id, lyrics: inlineLyrics)]);
      });
    }
    final sub = listen();
    await notifier().search('artist song');
    final state = sub.read();
    expect(state.bySource.keys.toList(), ids);
    expect(state.bySource.values.map((s) => s.phase).toSet(), {
      SourceSearchPhase.results,
    });
    expect(h.runner.maxInFlight, 4);
    expect(h.runner.calls, hasLength(12));
    expect(h.runner.calls.every((c) => c.input.keys.single == 'text'), isTrue);
  });

  test(
    'per source state: results, empty, failed, needs config, paused',
    () async {
      await start();
      final ok = await h.installLyrics('ok');
      final none = await h.installLyrics('none');
      final bad = await h.installLyrics('bad');
      final cfg = await h.installLyrics('cfg');
      final pause = await h.installLyrics('pause');
      h.runner.answer(
        ok,
        'search',
        searchAnswer([searchItem(lyrics: inlineLyrics)]),
      );
      h.runner.answer(none, 'search', searchAnswer([]));
      h.runner.answer(bad, 'search', const RunFailed(RunFailReason.timeout));
      h.runner.answer(cfg, 'search', const RunNeedsConfig(['Key']));
      h.runner.answer(pause, 'search', RunPaused(DateTime.utc(2027)));
      final sub = listen();
      await notifier().search('x');
      final s = sub.read().bySource;
      expect(s[ok]!.phase, SourceSearchPhase.results);
      expect(s[none]!.phase, SourceSearchPhase.empty);
      expect(s[bad]!.phase, SourceSearchPhase.failed);
      expect(s[bad]!.failure, SourceSearchFailure.network);
      expect(s[cfg]!.phase, SourceSearchPhase.needsConfig);
      expect(s[pause]!.phase, SourceSearchPhase.paused);
      expect(s[pause]!.until, DateTime.utc(2027));
    },
  );

  test('results are ranked with the difference against the song', () async {
    await start();
    final p = await h.installLyrics('p');
    h.runner.answer(
      p,
      'search',
      searchAnswer([
        searchItem(id: '1', durationMs: 230000, lyrics: '[00:01.00] a'),
        searchItem(id: '2', durationMs: 201000, lyrics: '[00:01.00] b'),
        searchItem(id: '3', durationMs: 201000, lyrics: 'plain only'),
      ]),
    );
    final sub = listen();
    await notifier().search('x');
    final matches = sub.read().bySource[p]!.matches;
    expect([for (final m in matches) m.candidate.remoteId], ['2', '1', '3']);
    expect(matches.first.delta, const Duration(seconds: 1));
  });

  test(
    'a newer search cancels the older and its answers are dropped',
    () async {
      await start();
      final slow = await h.installLyrics('slow');
      var round = 0;
      h.runner.on(slow, 'search', (r, cancel) {
        round++;
        if (round == 1) return Completer<RunOutcome>().future;
        return searchAnswer([searchItem(id: 'new', lyrics: inlineLyrics)]);
      });
      final sub = listen();
      final first = notifier().search('one');
      await h.until(() => h.runner.calls.length == 1);
      await notifier().search('two');
      await first;
      expect(h.runner.cancelled, hasLength(1));
      final state = sub.read();
      expect(state.text, 'two');
      expect(state.bySource[slow]!.matches.single.candidate.remoteId, 'new');
    },
  );

  test('disabled sources are asked only on request; settings stay', () async {
    await start();
    final on = await h.installLyrics('on');
    final off = await h.installLyrics('off', fromRepo: false);
    h.runner.answer(on, 'search', searchAnswer([]));
    h.runner.answer(
      off,
      'search',
      searchAnswer([searchItem(lyrics: inlineLyrics)]),
    );
    final sub = listen();
    await notifier().search('x');
    expect(h.runner.callsOf(off), 0);
    expect(sub.read().bySource.keys, [on]);
    await notifier().searchDisabled();
    expect(h.runner.callsOf(off), 1);
    expect(sub.read().onDemand, {off});
    expect(sub.read().bySource[off]!.phase, SourceSearchPhase.results);
    expect(h.container.read(lyricsOnlineSourcesProvider), isEmpty);
    // A new search drops the on-demand sources of the old one.
    await notifier().search('y');
    expect(sub.read().onDemand, isEmpty);
    expect(sub.read().bySource.keys, [on]);
  });

  test('a result without lyrics is fetched; one with its own is not', () async {
    await start();
    final p = await h.installLyrics('p');
    h.runner.answer(
      p,
      'search',
      searchAnswer([
        searchItem(id: 'own', lyrics: inlineLyrics),
        searchItem(id: 'two-step'),
      ]),
    );
    h.runner.answer(p, 'lyrics', lyricsAnswer(plain: 'fetched'));
    final sub = listen();
    await notifier().search('x');
    final matches = sub.read().bySource[p]!.matches;
    final own = matches.firstWhere((m) => m.candidate.remoteId == 'own');
    final twoStep = matches.firstWhere(
      (m) => m.candidate.remoteId == 'two-step',
    );
    expect(
      (await notifier().fetchLyrics(own.candidate))!.syncedLrc,
      inlineLyrics,
    );
    expect(h.runner.callsOf(p, 'lyrics'), 0);
    final body = await notifier().fetchLyrics(twoStep.candidate);
    expect(body!.plain, 'fetched');
    expect(h.runner.callsOf(p, 'lyrics'), 1);
    expect(sub.read().bodyFetches, isEmpty);
    expect(
      sub
          .read()
          .bySource[p]!
          .matches
          .firstWhere((m) => m.candidate.remoteId == 'two-step')
          .candidate
          .hasBody,
      isTrue,
    );
  });

  test('a failed or empty fetch shows in the state', () async {
    await start();
    final p = await h.installLyrics('p');
    h.runner.answer(p, 'search', searchAnswer([searchItem(id: 'a')]));
    h.runner.answer(p, 'lyrics', const RunFailed(RunFailReason.timeout));
    final sub = listen();
    await notifier().search('x');
    final cand = sub.read().bySource[p]!.matches.single.candidate;
    expect(await notifier().fetchLyrics(cand), isNull);
    expect(sub.read().bodyFetches[cand.ref]!.phase, BodyFetchPhase.failed);
    h.runner.answer(p, 'lyrics', const RunOk('null'));
    expect(await notifier().fetchLyrics(cand), isNull);
    expect(sub.read().bodyFetches[cand.ref]!.phase, BodyFetchPhase.missing);
  });

  test('a search lifts the failure backoff of the sources', () async {
    await start();
    final p = await h.installLyrics('p');
    h.runner.answer(p, 'search', searchAnswer([]));
    final sub = listen();
    final backoff = h.container.read(onlineBackoffProvider);
    backoff.failed(p, network: true);
    expect(backoff.of(p), isNotNull);
    await notifier().search('x');
    expect(backoff.of(p), isNull);
    sub.close();
  });

  test('a blank text searches nothing', () async {
    await start();
    final p = await h.installLyrics('p');
    final sub = listen();
    await notifier().search('   ');
    expect(h.runner.calls, isEmpty);
    expect(sub.read().bySource, isEmpty);
    expect(p, isNotEmpty);
  });
}
