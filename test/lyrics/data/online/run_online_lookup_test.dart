import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/online/lyrics_run_client.dart';
import 'package:kanaru/src/lyrics/data/online/run_online_lookup.dart';
import 'package:kanaru/src/lyrics/domain/online/online_cache_pick.dart';
import 'package:kanaru/src/lyrics/domain/online/online_text.dart';
import 'package:kanaru/src/plugins/data/run/run_cancel.dart';
import 'package:kanaru/src/plugins/domain/run/run_outcome.dart';

import '../../support/fake_plugin_runner.dart';
import '../../support/online_lookup_rig.dart';

const _id = 'p1';

void main() {
  late FakePluginRunner runner;
  late LyricsRunClient client;
  setUp(() {
    runner = FakePluginRunner();
    client = LyricsRunClient(runner);
  });

  Future<SourceLookup> lookup({
    RejectedResults rejected = const RejectedResults(),
    RunCancel? cancel,
  }) => runOnlineLookup(
    client: client,
    installId: _id,
    target: songTarget(),
    rejected: rejected,
    cancel: cancel,
  );

  test('a good match with inline lyrics wins with no lyrics call', () async {
    runner.answer(
      _id,
      'search',
      searchAnswer([searchItem(lyrics: inlineLyrics)]),
    );
    final found = await lookup() as LookupFound;
    expect(found.chosen.body!.syncedLrc, inlineLyrics);
    expect(runner.callsOf(_id, 'lyrics'), 0);
  });

  test('a match without lyrics is fetched; instrumental counts', () async {
    runner.answer(_id, 'search', searchAnswer([searchItem(id: '9')]));
    runner.answer(_id, 'lyrics', lyricsAnswer(instrumental: true));
    final found = await lookup() as LookupFound;
    expect(found.chosen.remoteId, '9');
    expect(found.chosen.body!.instrumental, isTrue);
    expect(runner.calls.last.input, {'id': '9'});
  });

  test('at most three lyrics calls, then a miss', () async {
    runner.answer(
      _id,
      'search',
      searchAnswer([for (var i = 1; i <= 5; i++) searchItem(id: '$i')]),
    );
    runner.answer(_id, 'lyrics', const RunOk('null'));
    expect(await lookup(), isA<LookupMiss>());
    expect(runner.callsOf(_id, 'lyrics'), 3);
  });

  test('a candidate whose duration is off is not a match', () async {
    runner.answer(
      _id,
      'search',
      searchAnswer([searchItem(durationMs: 260000, lyrics: inlineLyrics)]),
    );
    expect(await lookup(), isA<LookupMiss>());
    expect(runner.callsOf(_id, 'lyrics'), 0);
  });

  test('a rejected id or text never wins, the next candidate does', () async {
    runner.answer(
      _id,
      'search',
      searchAnswer([
        searchItem(id: '1', lyrics: inlineLyrics),
        searchItem(id: '2', durationMs: 201000, lyrics: '[00:02.00] other'),
      ]),
    );
    final byId = await lookup(
      rejected: const RejectedResults(refs: {(providerId: _id, remoteId: '1')}),
    ) as LookupFound;
    expect(byId.chosen.remoteId, '2');
    final hash = lyricsContentHash(
      parseOnlineText(synced: inlineLyrics)!.lines,
    );
    final byText =
        await lookup(rejected: RejectedResults(hashes: {hash})) as LookupFound;
    expect(byText.chosen.remoteId, '2');
  });

  test('fetched text that was refused is skipped', () async {
    runner.answer(_id, 'search', searchAnswer([searchItem(id: '1')]));
    runner.answer(_id, 'lyrics', lyricsAnswer(synced: inlineLyrics));
    final hash = lyricsContentHash(
      parseOnlineText(synced: inlineLyrics)!.lines,
    );
    expect(
      await lookup(rejected: RejectedResults(hashes: {hash})),
      isA<LookupMiss>(),
    );
  });

  test('failures are returned, never turned into a miss', () async {
    runner.answer(_id, 'search', const RunFailed(RunFailReason.timeout));
    expect(await lookup(), isA<LookupSourceFailed>());
    runner.answer(
      _id,
      'search',
      const RunOk(
        '[]',
        fetchFailure: FetchFailureInfo(kind: FetchFailureKind.network),
      ),
    );
    expect(await lookup(), isA<LookupSourceFailed>());
    runner.answer(_id, 'search', searchAnswer([searchItem()]));
    runner.answer(
      _id,
      'lyrics',
      const RunScriptError(RunErrorKind.server, 'x'),
    );
    expect(await lookup(), isA<LookupSourceFailed>());
  });

  test('an honest empty answer is a miss', () async {
    runner.answer(_id, 'search', searchAnswer([]));
    expect(await lookup(), isA<LookupMiss>());
  });

  test('skips and a cancel pass through', () async {
    runner.answer(_id, 'search', const RunBusy());
    expect((await lookup() as LookupSourceSkipped).reason, isNotNull);
    runner.blockUntilCancelled(_id, 'search');
    final cancel = RunCancel();
    final pending = lookup(cancel: cancel);
    await pumpEventQueue();
    cancel.cancel();
    expect(await pending, isA<LookupAbandoned>());
  });

  test('the search sends only the tags of the song', () async {
    runner.answer(_id, 'search', searchAnswer([]));
    await lookup();
    expect(runner.calls.single.input.keys, {
      'title',
      'artist',
      'artists',
      'album',
      'durationMs',
    });
    expect(runner.calls.single.input['album'], isNull);
  });
}
