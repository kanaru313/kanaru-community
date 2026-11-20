import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/app_database.dart';
import 'package:kanaru/src/library/domain/history/history_clear_scope.dart';
import 'package:kanaru/src/library/domain/history/history_models.dart';
import 'package:kanaru/src/library/state/browse/song_list_providers.dart';
import 'package:kanaru/src/library/state/history/history_actions.dart';
import 'package:kanaru/src/library/state/history/history_providers.dart';
import 'package:kanaru/src/library/state/history/history_removal_holder.dart';
import 'package:kanaru/src/media/domain/play_context.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/platform/state/settings_providers.dart';
import 'package:kanaru/src/playback/data/play_log_writer.dart';
import 'package:kanaru/src/playback/state/listen_recorder.dart';
import 'package:kanaru/src/playback/state/listen_recorder_provider.dart';
import 'package:kanaru/src/playback/state/playback_providers.dart';
import 'package:kanaru/src/playback/state/playback_settings_providers.dart';

import '../../../database/support/test_db.dart';
import '../../../support/fake_playback_commands.dart';
import '../../../support/memory_settings_store.dart';
import '../data/history_fixture.dart';
import 'fake_history_store.dart';

/// A recorder that notes what [probe] says when a clear starts.
class _ProbingRecorder extends ListenRecorder {
  _ProbingRecorder(PlayLogWriter w, this.probe)
    : super(writer: w, deviceId: () => 'dev');

  final bool Function() probe;
  final seen = <bool>[];

  @override
  Future<int?> clearHistory({int? from, int? to}) {
    seen.add(probe());
    return super.clearHistory(from: from, to: to);
  }
}

/// A recorder whose clear fails.
class _FailingRecorder extends ListenRecorder {
  _FailingRecorder(PlayLogWriter w) : super(writer: w, deviceId: () => 'dev');

  @override
  Future<int?> clearHistory({int? from, int? to}) async => null;
}

void main() {
  late AppDatabase db;
  late FakeHistoryStore store;
  late FakePlaybackCommands commands;
  late MemorySettingsStore settings;
  late ProviderContainer c;
  var infos = <TrackInfo>[];

  ProviderContainer make({ListenRecorder? recorder}) => ProviderContainer(
    overrides: [
      historyStoreProvider.overrideWithValue(store),
      playbackCommandsProvider.overrideWithValue(commands),
      settingsStoreProvider.overrideWithValue(settings),
      trackRowLoaderProvider.overrideWithValue(
        (ids) async => [
          for (final id in ids) infos.firstWhere((i) => i.id == id),
        ],
      ),
      listenRecorderProvider.overrideWithValue(
        recorder ??
            ListenRecorder(writer: PlayLogWriter(db), deviceId: () => 'dev'),
      ),
    ],
  );

  setUp(() {
    db = openTestDb();
    store = FakeHistoryStore();
    commands = FakePlaybackCommands();
    settings = MemorySettingsStore();
    infos = [
      info(1),
      info(2, status: TrackAvailability.missing),
      info(3),
      info(4, status: TrackAvailability.hidden),
    ];
    c = make();
  });
  tearDown(() async {
    c.dispose();
    await pumpEventQueue();
    await db.close();
  });

  HistoryActions actions() => c.read(historyActionsProvider);

  test(
    'playAllHistory plays playable songs newest first, shuffle passed',
    () async {
      store.playedTracks = [
        for (final i in [4, 3, 2, 1]) TrackId(i),
      ];
      expect(await actions().playAllHistory(shuffle: true, label: 'L'), isTrue);
      final call = commands.calls.single as PlayTracksCall;
      expect(call.tracks.map((t) => t.value), [3, 1]);
      expect(call.shuffle, isTrue);
      expect(
        call.context,
        const PlayContext(PlayContextKind.history, label: 'L'),
      );
    },
  );

  test('playAllHistory with nothing playable plays nothing', () async {
    store.playedTracks = [TrackId(2), TrackId(4)];
    expect(await actions().playAllHistory(), isFalse);
    expect(commands.calls, isEmpty);
  });

  test('playDay queues each song once without unplayable ones', () async {
    final day = HistoryDay(DateTime(2026, 6, 1), [
      play(1, 2026, track: infos[0]),
      play(2, 2026, track: infos[1]),
      play(3, 2026, track: infos[2]),
      play(4, 2026, track: infos[0]),
    ]);
    expect(await actions().playDay(day), isTrue);
    final call = commands.calls.single as PlayTracksCall;
    expect(call.tracks.map((t) => t.value), [1, 3]);
    expect(call.context.kind, PlayContextKind.history);
  });

  test(
    'playFrom starts at the tapped song; unplayable tapped does nothing',
    () async {
      expect(await actions().playFrom(infos, infos[2]), isTrue);
      final call = commands.calls.single as PlayTracksCall;
      expect(call.tracks.map((t) => t.value), [1, 3]);
      expect(call.startIndex, 1);
      expect(await actions().playFrom(infos, infos[1]), isFalse);
      expect(commands.calls.length, 1);
    },
  );

  test('playTop uses the Most played context, in rank order', () async {
    final entries = [
      for (var i = 0; i < 4; i++)
        TopEntry(rank: i + 1, track: infos[i], count: 4 - i, lastPlayedAt: 1),
    ];
    expect(await actions().playTop(entries, label: 'Top'), isTrue);
    final call = commands.calls.single as PlayTracksCall;
    expect(call.tracks.map((t) => t.value), [1, 3]);
    expect(
      call.context,
      const PlayContext(PlayContextKind.mostPlayed, label: 'Top'),
    );
    expect(await actions().playTop(entries, tapped: infos[2]), isTrue);
    expect((commands.calls.last as PlayTracksCall).startIndex, 1);
  });

  group('remove and undo', () {
    test('removals merge into one pending total, undo restores all', () async {
      final a = actions();
      expect(await a.remove(play(1, 2026)), 1);
      expect(await a.remove(play(2, 2026)), 2);
      expect(await a.undo(), isTrue);
      expect(store.undone.single.length, 2);
      expect(c.read(historyRemovalHolderProvider).hasPending, isFalse);
    });

    test('a failing remove reports null and adds no batch', () async {
      store.removeError = StateError('x');
      expect(await actions().remove(play(1, 2026)), isNull);
      expect(c.read(historyRemovalHolderProvider).hasPending, isFalse);
    });

    test('a failing undo reports false', () async {
      await actions().remove(play(1, 2026));
      store.undoError = StateError('x');
      expect(await actions().undo(), isFalse);
    });

    test('a removal reports the pending total', () async {
      expect(await actions().remove(play(1, 2026)), 1);
    });
  });

  group('clear', () {
    test(
      'commits pending removals, then deletes through the recorder',
      () async {
        final ids = await addTracks(db, 1);
        await addPlay(db, ids.first, playedAt: ms(2026, 11, 20, 9));
        await addPlay(db, ids.first, playedAt: ms(2026, 11, 19, 9));
        await actions().remove(play(1, 2026));
        final now = DateTime(2026, 11, 20, 10);
        expect(await actions().clear(ClearScope.today, now), 1);
        expect(store.committed.length, 1, reason: 'removals committed first');
        expect(await actions().clear(ClearScope.all, now), 1);
      },
    );

    test('pending removals are committed before the delete starts', () async {
      late final ProviderContainer probed;
      final recorder = _ProbingRecorder(
        PlayLogWriter(db),
        () => probed.read(historyRemovalHolderProvider).hasPending,
      );
      c.dispose();
      probed = c = make(recorder: recorder);
      await actions().remove(play(1, 2026));
      expect(c.read(historyRemovalHolderProvider).hasPending, isTrue);
      await actions().clear(ClearScope.all, DateTime(2026, 11, 20));
      expect(recorder.seen, [false]);
      expect(store.committed.length, 1);
    });

    test('a failing commit does not stop the clear', () async {
      await actions().remove(play(1, 2026));
      store.commitError = StateError('x');
      expect(await actions().clear(ClearScope.all, DateTime(2026)), 0);
    });

    test('a closing toast reports a failed commit', () async {
      void hide() {}
      await actions().remove(play(1, 2026));
      c.read(historyRemovalHolderProvider).attachToast(hide);
      store.commitError = StateError('x');
      expect(await actions().toastClosed(hide), isFalse);
    });

    test('deleteDay covers exactly that local day', () async {
      final ids = await addTracks(db, 1);
      await addPlay(db, ids.first, playedAt: ms(2026, 11, 19, 0, 0));
      await addPlay(db, ids.first, playedAt: ms(2026, 11, 19, 23, 59));
      await addPlay(db, ids.first, playedAt: ms(2026, 11, 20, 0, 0));
      expect(await actions().deleteDay(DateTime(2026, 11, 19, 15)), 2);
    });

    test('a failed clear returns null', () async {
      c.dispose();
      c = make(recorder: _FailingRecorder(PlayLogWriter(db)));
      expect(await actions().clear(ClearScope.all, DateTime(2026)), isNull);
    });

    test('a recorder clear event commits the holder', () async {
      c.read(historyRemovalHolderProvider);
      await actions().remove(play(1, 2026));
      final ids = await addTracks(db, 1);
      await addPlay(db, ids.first, playedAt: ms(2026, 11, 20, 9));
      await c.read(listenRecorderProvider).clearHistory();
      await pumpEventQueue();
      expect(store.committed.length, 1);
    });
  });

  test('counts: scopes by range, all from the overview', () async {
    final now = DateTime(2026, 11, 20, 10);
    final b = ClearScope.today.bounds(now);
    store.counts = {b.from!: 4};
    store.overviewAnswer = const HistoryOverview(plays: 42, songs: 3, since: 1);
    final counts = await actions().counts(now);
    expect(counts[ClearScope.today], 4);
    expect(counts[ClearScope.hour], 0);
    expect(counts[ClearScope.all], 42);
  });

  test('enableRecording writes the switch', () async {
    await actions().enableRecording();
    expect(c.read(historyRecordingProvider), isTrue);
    await c.read(historyEnabledProvider.notifier).set(false);
    expect(c.read(historyRecordingProvider), isFalse);
    await actions().enableRecording();
    expect(c.read(historyRecordingProvider), isTrue);
  });

  test('historyClearingProvider follows the recorder', () async {
    c.listen(historyClearingProvider, (_, _) {});
    expect(c.read(historyClearingProvider), isFalse);
    final done = c.read(listenRecorderProvider).clearHistory();
    expect(c.read(historyClearingProvider), isTrue);
    await done;
    await pumpEventQueue();
    expect(c.read(historyClearingProvider), isFalse);
  });
}
