import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/lyrics/data/local_lyrics_read.dart';
import 'package:kanaru/src/lyrics/data/local_lyrics_reader.dart';
import 'package:kanaru/src/lyrics/data/tag_read_queue.dart';
import 'package:kanaru/src/lyrics/domain/embedded_lyrics.dart';

import '../support/fake_local_lyrics_reader.dart';

void main() {
  late FakeLocalLyricsReader reader;
  late TagReadQueue queue;
  setUp(() {
    reader = FakeLocalLyricsReader();
    queue = TagReadQueue(reader);
    for (final p in ['b', 'c']) {
      reader.tags[p] = EmbeddedLyrics(text: p);
    }
  });

  test(
    'one read at a time; the newest waiting one runs next, none dropped',
    () async {
      reader.holdTags.add('a');
      final a = queue.read('a');
      await pumpEventQueue();
      final b = queue.read('b');
      final c = queue.read('c');
      await pumpEventQueue();
      expect(reader.tagReads, ['a'], reason: 'b and c wait for a');
      reader.releaseTag('a');
      expect(await a.result, isNull);
      expect((await c.result)!.text, 'c');
      expect((await b.result)!.text, 'b');
      expect(reader.tagReads, ['a', 'c', 'b'], reason: 'newest first');
    },
  );

  test(
    'a waiting read whose requester cancelled is dropped, never read',
    () async {
      reader.holdTags.add('a');
      final a = queue.read('a');
      await pumpEventQueue();
      final b = queue.read('b');
      final c = queue.read('c');
      final dropped = expectLater(b.result, throwsA(isA<LyricsSuperseded>()));
      b.cancel();
      await dropped;
      reader.releaseTag('a');
      await a.result;
      expect((await c.result)!.text, 'c');
      await pumpEventQueue();
      expect(reader.tagReads, ['a', 'c']);
    },
  );

  test('cancelling a running or finished read changes nothing', () async {
    reader.holdTags.add('a');
    final a = queue.read('a');
    await pumpEventQueue();
    a.cancel();
    reader.releaseTag('a');
    expect(await a.result, isNull);
    final b = queue.read('b');
    expect((await b.result)!.text, 'b');
    b.cancel();
  });

  test('a failed read completes its request and the queue goes on', () async {
    reader.tagErrors['a'] = const LyricsReadFailure(
      kind: 'io',
      transient: true,
    );
    await expectLater(
      queue.read('a').result,
      throwsA(isA<LyricsReadFailure>()),
    );
    expect((await queue.read('b').result)!.text, 'b');
  });
}
