import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/lyrics/data/local_lyrics_reader.dart';
import 'package:kanaru/src/lyrics/domain/embedded_lyrics.dart';
import 'package:kanaru/src/lyrics/domain/local_lyrics_pick.dart';
import 'package:kanaru/src/lyrics/domain/lyrics.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_status.dart';
import 'package:kanaru/src/lyrics/domain/lyrics_summary.dart';
import 'package:kanaru/src/lyrics/state/lyrics_choice_commands.dart';
import 'package:kanaru/src/lyrics/state/lyrics_settings.dart';
import 'package:kanaru/src/lyrics/state/track_lyrics_providers.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/playback/domain/playable.dart';

import '../support/lyrics_harness.dart';

void main() {
  late LyricsHarness h;
  setUp(() => h = LyricsHarness());
  tearDown(() => h.dispose());

  /// Watches the lyrics of [id] and waits until it is no longer loading.
  Future<ProviderSubscription<TrackLyrics>> watch(TrackId id) async {
    final sub = h.container.listen(trackLyricsProvider(id), (_, _) {});
    await h.until(() => sub.read() is! LyricsLoading);
    return sub;
  }

  test('shows the tag lyrics of a file', () async {
    final id = await h.addTrackRow('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(
      text: '[00:01.00]hi',
    );
    final sub = await watch(id);
    final state = sub.read() as LyricsShown;
    expect(state.lyrics.origin, LyricsOrigin.tag);
    expect(summaryOf(state), LyricsSummary.tagSynced);
  });

  test('the .lrc is read beside the audio from the scan locator', () async {
    final id = await h.addTrackRow(
      'a.flac',
      lrcLocator: 'sub/A.LRC',
      lrcRevision: '1:1',
    );
    h.reader.lrcs['/m/A.LRC'] = '[00:01.00]hi';
    final sub = await watch(id);
    expect((sub.read() as LyricsShown).lyrics.origin, LyricsOrigin.lrc);
  });

  test('loading first; nothing found is LyricsNone', () async {
    final id = await h.addTrackRow('a.flac');
    final sub = h.container.listen(trackLyricsProvider(id), (_, _) {});
    expect(sub.read(), isA<LyricsLoading>());
    await h.until(() => sub.read() is! LyricsLoading);
    expect(sub.read(), isA<LyricsNone>());
  });

  test('one read per key, however often it is watched', () async {
    final id = await h.addTrackRow('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(text: 'x');
    final a = await watch(id);
    final b = await watch(id);
    expect(h.reader.tagReads, hasLength(1));
    a.close();
    b.close();
  });

  test('flipping lyrics.local_first re-picks without a new read', () async {
    final id = await h.addTrackRow(
      'a.flac',
      lrcLocator: 'a.lrc',
      lrcRevision: '1:1',
    );
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(
      text: '[00:01.00]tag',
    );
    h.reader.lrcs['/m/a.lrc'] = '[00:01.00]lrc';
    final sub = await watch(id);
    expect((sub.read() as LyricsShown).lyrics.origin, LyricsOrigin.tag);
    await h.container
        .read(lyricsLocalFirstProvider.notifier)
        .set(LocalFirst.lrc);
    expect((sub.read() as LyricsShown).lyrics.origin, LyricsOrigin.lrc);
    expect(h.reader.tagReads, hasLength(1));
    expect(h.reader.lrcReads, hasLength(1));
  });

  test('a choice write re-reads nothing and gives LyricsOff with what is available', () async {
    final id = await h.addTrackRow('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(
      text: '[00:01.00]hi',
    );
    final sub = await watch(id);
    final commands = h.container.read(lyricsChoiceCommandsProvider);
    await commands.setOff(id);
    await h.until(() => sub.read() is LyricsOff);
    expect((sub.read() as LyricsOff).available, isNotNull);
    await commands.clear(id);
    await h.until(() => sub.read() is LyricsShown);
    expect(h.reader.tagReads, hasLength(1));
    expect(h.resolver.calls, 1);
  });

  test('toggle flips between off and automatic', () async {
    final id = await h.addTrackRow('a.flac');
    final sub = await watch(id);
    final commands = h.container.read(lyricsChoiceCommandsProvider);
    await commands.toggle(id, currentlyOff: false);
    await h.until(() => sub.read() is LyricsOff);
    await commands.toggle(id, currentlyOff: true);
    await h.until(() => sub.read() is LyricsNone);
  });

  test('an unplayable track is unavailable and nothing is read', () async {
    final id = await h.addTrackRow('a.flac');
    h.resolver.answers[id] = const Unplayable(UnplayableReason.missing);
    final sub = await watch(id);
    expect(sub.read(), const LyricsUnavailable(UnplayableReason.missing));
    expect(h.reader.tagReads, isEmpty);
    expect(h.reader.stats, isEmpty);
  });

  test('an unknown track is unavailable', () async {
    h.resolver.answers[const TrackId(777)] = const Unplayable(
      UnplayableReason.unknownTrack,
    );
    final sub = await watch(const TrackId(777));
    expect(sub.read(), const LyricsUnavailable(UnplayableReason.unknownTrack));
  });

  test(
    'a remount that makes the file playable reads it on the next watch',
    () async {
      final id = await h.addTrackRow('a.flac');
      h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(text: 'x');
      h.resolver.answers[id] = const Unplayable(UnplayableReason.noMount);
      var sub = await watch(id);
      expect(sub.read(), isA<LyricsUnavailable>());
      sub.close();
      await pumpEventQueue();
      h.resolver.answers.remove(id);
      sub = await watch(id);
      expect(sub.read(), isA<LyricsShown>());
      expect(h.reader.tagReads, hasLength(1));
    },
  );

  test(
    'a transient failure shows the other source and is re-read next time',
    () async {
      final id = await h.addTrackRow(
        'a.flac',
        lrcLocator: 'a.lrc',
        lrcRevision: '1:1',
      );
      h.reader.tagErrors['/m/${id.value}.flac'] = const LyricsReadFailure(
        kind: 'timeout',
        transient: true,
      );
      h.reader.lrcs['/m/a.lrc'] = '[00:01.00]lrc';
      var sub = await watch(id);
      expect((sub.read() as LyricsShown).lyrics.origin, LyricsOrigin.lrc);
      sub.close();
      await pumpEventQueue();
      h.reader.tagErrors.clear();
      h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(
        text: '[00:01.00]tag',
      );
      sub = await watch(id);
      expect((sub.read() as LyricsShown).lyrics.origin, LyricsOrigin.tag);
      expect(h.reader.tagReads, hasLength(2));
    },
  );

  test(
    'a read that never lands keeps the state loading, not another track',
    () async {
      final a = await h.addTrackRow('a.flac');
      final b = await h.addTrackRow('b.flac');
      h.reader.tags['/m/${a.value}.flac'] = const EmbeddedLyrics(text: 'A');
      h.reader.holdTags.add('/m/${b.value}.flac');
      final subA = await watch(a);
      final subB = h.container.listen(trackLyricsProvider(b), (_, _) {});
      await pumpEventQueue();
      expect(subB.read(), isA<LyricsLoading>());
      expect(subA.read(), isA<LyricsShown>());
      h.reader.releaseTag('/m/${b.value}.flac');
      await h.until(() => subB.read() is! LyricsLoading);
    },
  );

  test('two watched tracks behind a slow read both get their lyrics', () async {
    // The playing track and a modal track at once: the newer request runs
    // first, the older one is not dropped.
    final a = await h.addTrackRow('a.flac');
    final b = await h.addTrackRow('b.flac');
    final c = await h.addTrackRow('c.flac');
    for (final id in [a, b, c]) {
      h.reader.tags['/m/${id.value}.flac'] = EmbeddedLyrics(
        text: 'L${id.value}',
      );
    }
    h.reader.holdTags.add('/m/${a.value}.flac');
    final subA = h.container.listen(trackLyricsProvider(a), (_, _) {});
    await h.until(() => h.reader.tagReads.isNotEmpty);
    final subB = h.container.listen(trackLyricsProvider(b), (_, _) {});
    await h.until(() => h.resolver.calls >= 2);
    final subC = h.container.listen(trackLyricsProvider(c), (_, _) {});
    await h.until(() => h.resolver.calls >= 3);
    await pumpEventQueue();
    h.reader.releaseTag('/m/${a.value}.flac');
    for (final sub in [subA, subB, subC]) {
      await h.until(() => sub.read() is LyricsShown);
    }
    expect(h.reader.tagReads.first, '/m/${a.value}.flac');
  });

  test('a disposed requester\'s waiting read is dropped', () async {
    final a = await h.addTrackRow('a.flac');
    final b = await h.addTrackRow('b.flac');
    h.reader.holdTags.add('/m/${a.value}.flac');
    h.reader.tags['/m/${b.value}.flac'] = const EmbeddedLyrics(text: 'B');
    final subA = h.container.listen(trackLyricsProvider(a), (_, _) {});
    await h.until(() => h.reader.tagReads.isNotEmpty);
    final subB = h.container.listen(trackLyricsProvider(b), (_, _) {});
    await h.until(() => h.resolver.calls >= 2);
    await pumpEventQueue();
    subB.close();
    await pumpEventQueue();
    h.reader.releaseTag('/m/${a.value}.flac');
    await h.until(() => subA.read() is! LyricsLoading);
    await pumpEventQueue();
    expect(h.reader.tagReads, ['/m/${a.value}.flac']);
  });

  test('a revision change re-reads and keeps showing meanwhile', () async {
    final id = await h.addTrackRow('a.flac');
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(text: 'old');
    final sub = await watch(id);
    h.reader.tags['/m/${id.value}.flac'] = const EmbeddedLyrics(text: 'new');
    h.reader.holdTags.add('/m/${id.value}.flac');
    await h.db.customUpdate(
      "UPDATE tracks SET revision = 'r2' WHERE id = ?",
      variables: [Variable.withInt(id.value)],
      updates: {h.db.tracks},
    );
    await h.until(() => h.reader.tagReads.length == 2);
    expect(sub.read(), isA<LyricsShown>(), reason: 'same track: no blank');
    h.reader.releaseTag('/m/${id.value}.flac');
    await h.until(
      () => (sub.read() as LyricsShown).lyrics.lines.single.text == 'new',
    );
  });

  test('a new .lrc locator re-reads the .lrc', () async {
    final id = await h.addTrackRow('a.flac');
    h.reader.lrcs['/m/a.lrc'] = '[00:01.00]lrc';
    final sub = await watch(id);
    expect(sub.read(), isA<LyricsNone>());
    await h.db
        .into(h.db.trackDetails)
        .insert(
          TrackDetailsCompanion.insert(
            trackId: Value(id.value),
            lrcLocator: const Value('a.lrc'),
            lrcRevision: const Value('1:1'),
          ),
        );
    await h.until(() => sub.read() is LyricsShown);
    expect(h.reader.lrcReads, ['/m/a.lrc']);
  });

  test('closing the last listener disposes the track provider', () async {
    final id = await h.addTrackRow('a.flac');
    final sub = await watch(id);
    expect(h.container.read(trackLyricsProvider(id).exists), isTrue);
    sub.close();
    await pumpEventQueue();
    expect(h.container.read(trackLyricsProvider(id).exists), isFalse);
  });
}
