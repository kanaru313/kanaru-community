import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/ui/markdown/chat_markdown_inline.dart';
import 'package:kanaru/src/ai/ui/markdown/chat_markdown_model.dart';
import 'package:kanaru/src/ai/ui/markdown/chat_markdown_stream.dart';

List<ChatSpan> _line(String s) => parseInline(s);

ChatParagraph _para(List<String> lines) => ChatParagraph([
  for (final l in lines) [ChatText(l)],
]);

void main() {
  group('blocks', () {
    test('blank line splits paragraphs, single newline stays a break', () {
      expect(parseBlocks('a\nb\n\nc'), [
        _para(['a', 'b']),
        _para(['c']),
      ]);
    });

    test('CRLF and CR read like LF', () {
      expect(parseBlocks('a\r\nb\r\rc'), parseBlocks('a\nb\n\nc'));
    });

    test('bullets and numbers become lists; start is kept', () {
      expect(parseBlocks('- a\n* b\n+ c'), [
        ChatList(
          ordered: false,
          start: 1,
          items: [
            [const ChatText('a')],
            [const ChatText('b')],
            [const ChatText('c')],
          ],
        ),
      ]);
      expect(parseBlocks('3. a\n4) b'), [
        ChatList(
          ordered: true,
          start: 3,
          items: [
            [const ChatText('a')],
            [const ChatText('b')],
          ],
        ),
      ]);
    });

    test('a kind switch starts a new list', () {
      final blocks = parseBlocks('- a\n1. b');
      expect(blocks.length, 2);
      expect((blocks[0] as ChatList).ordered, isFalse);
      expect((blocks[1] as ChatList).ordered, isTrue);
    });

    test('a list goes on across a blank line', () {
      final blocks = parseBlocks('1. a\n\n2. b');
      expect(blocks.length, 1);
      expect((blocks.single as ChatList).items.length, 2);
    });

    test(
      'an indented line joins the item; after a blank it is a paragraph',
      () {
        final joined = parseBlocks('- a\n  more');
        expect((joined.single as ChatList).items.single, [
          const ChatText('a'),
          const ChatText('\n'),
          const ChatText('more'),
        ]);
        final split = parseBlocks('- a\n\n  more');
        expect(split.length, 2);
        expect(split[1], isA<ChatParagraph>());
      },
    );

    test('headings, quotes and fences stay literal text', () {
      expect(parseBlocks('# x\n> y\n```'), [
        _para(['# x', '> y', '```']),
      ]);
    });

    test('a [[t:ID]] line is a track, anything else around it is text', () {
      expect(parseBlocks('[[t:12]]'), [const ChatTrack('12')]);
      expect(parseBlocks('  [[t:12]]  '), [const ChatTrack('12')]);
      expect(parseBlocks('see [[t:12]] now'), [
        _para(['see [[t:12]] now']),
      ]);
      expect(parseBlocks('- [[t:12]] extra'), [
        ChatList(
          ordered: false,
          start: 1,
          items: [
            [const ChatText('[[t:12]] extra')],
          ],
        ),
      ]);
      expect(parseBlocks('[[t:]]'), [
        _para(['[[t:]]']),
      ]);
      expect(parseBlocks('[[t:a b]]'), [
        _para(['[[t:a b]]']),
      ]);
    });

    test('a list item that is only a track ref is a track row', () {
      for (final line in [
        '- [[t:853]]',
        '* [[t:853]]',
        '+ [[t:853]]',
        '1. [[t:853]]',
        '2) [[t:853]]',
        '  - [[t:853]]  ',
      ]) {
        expect(parseBlocks(line), [const ChatTrack('853')], reason: line);
      }
      expect(parseBlocks('- [[t:1]]\n- [[t:2]]\n3. [[t:3]]'), [
        const ChatTrack('1'),
        const ChatTrack('2'),
        const ChatTrack('3'),
      ]);
    });

    test('more than eight song lines in a row are one list, eight are not', () {
      String lines(int n) =>
          [for (var i = 1; i <= n; i++) '[[t:$i]]'].join('\n');
      expect(parseBlocks(lines(8)), [
        for (var i = 1; i <= 8; i++) ChatTrack('$i'),
      ]);
      expect(parseBlocks(lines(9)), [
        ChatTrackList([for (var i = 1; i <= 9; i++) '$i']),
      ]);
    });

    test('a text line or a blank line splits song runs', () {
      String run(int from, int n) =>
          [for (var i = from; i < from + n; i++) '[[t:$i]]'].join('\n');
      final blocks = parseBlocks(
        '${run(1, 9)}\ntext\n${run(20, 9)}\n\n${run(40, 9)}',
      );
      expect(blocks.map((b) => b.runtimeType.toString()).toList(), [
        'ChatTrackList',
        'ChatParagraph',
        'ChatTrackList',
        'ChatTrackList',
      ]);
      expect((blocks[2] as ChatTrackList).ids.first, '20');
      expect((blocks[3] as ChatTrackList).ids.first, '40');
    });

    test('a mixed list keeps its text items as bullets', () {
      ChatList bullets(List<String> t) => ChatList(
        ordered: false,
        start: 1,
        items: [
          for (final s in t) [ChatText(s)],
        ],
      );
      expect(parseBlocks('- intro\n- [[t:1]]\n- [[t:2]]\n- outro'), [
        bullets(['intro']),
        const ChatTrack('1'),
        const ChatTrack('2'),
        bullets(['outro']),
      ]);
    });

    test('a line over the cap is one plain span', () {
      final long = '**x** ${'a' * chatMarkdownMaxLine}';
      expect(_line(long), [ChatText(long)]);
    });
  });

  group('inline', () {
    test('bold, italic markers dropped, underscore literal', () {
      expect(_line('a **b** c'), [
        const ChatText('a '),
        const ChatBold('b'),
        const ChatText(' c'),
      ]);
      expect(_line('*it*'), [const ChatText('it')]);
      expect(_line('_it_ snake_case'), [const ChatText('_it_ snake_case')]);
      expect(_line('2 * 3 * 4'), [const ChatText('2 * 3 * 4')]);
      expect(_line('***x***'), [const ChatText('***x***')]);
    });

    test('unterminated markers stay literal', () {
      expect(_line('**x'), [const ChatText('**x')]);
      expect(_line('a ` b'), [const ChatText('a ` b')]);
      expect(_line('a * b'), [const ChatText('a * b')]);
    });

    test('code spans keep their stars; a span splits bold', () {
      expect(_line('`a*b`'), [const ChatCode('a*b')]);
      expect(_line('``a`b``'), [const ChatCode('a`b')]);
      expect(_line('**a `b` c**'), [
        const ChatBold('a '),
        const ChatCode('b'),
        const ChatBold(' c'),
      ]);
    });

    test('an escaped star is not an escape: the backslash shows', () {
      expect(_line(r'\*x\*'), [const ChatText(r'\x\')]);
    });

    test('links, images, autolinks and HTML are the text as typed', () {
      for (final s in [
        '[a](http://x)',
        '![i](http://x.png)',
        '<https://x>',
        '<b>x</b>',
        '<script>alert(1)</script>',
      ]) {
        expect(_line(s), [ChatText(s)], reason: s);
      }
    });
  });

  group('stream', () {
    const fixture =
        'Intro with **bold** and `code`.\r\nSecond line\r\n\r\n'
        '1. one\r\n2. two\r\n   more two\r\n\r\n3. three\r\n'
        '[[t:42]]\r\n- a\n- b\n\nTail *it* [x](http://y)\n[[t:9]]';

    test('streamed equals full parse for random splits', () {
      final expected = parseBlocks(fixture);
      for (var seed = 0; seed < 200; seed++) {
        final rnd = Random(seed);
        final stream = ChatMarkdownStream();
        var i = 0;
        while (i < fixture.length) {
          final n = 1 + rnd.nextInt(7);
          stream.add(fixture.substring(i, min(fixture.length, i + n)));
          i += n;
        }
        stream.finish();
        expect(stream.closedBlocks, expected, reason: 'seed $seed');
      }
    });

    test('a closed block is the same object after later deltas', () {
      final stream = ChatMarkdownStream()..add('first\n\nsecond\n\n');
      final first = stream.closedBlocks.first;
      stream.add('third\n\nfourth');
      expect(identical(stream.closedBlocks.first, first), isTrue);
    });

    test('open blocks show the partial line', () {
      final stream = ChatMarkdownStream()..add('done\n\npart');
      expect(stream.closedBlocks, [
        _para(['done']),
      ]);
      expect(stream.openBlocks, [
        _para(['part']),
      ]);
    });

    test('each completed line is parsed once', () {
      final lines = [for (var i = 0; i < 4000; i++) 'line $i with **bold** x'];
      final text = lines.join('\n');
      final stream = ChatMarkdownStream();
      for (var i = 0; i < text.length; i += 50) {
        stream.add(text.substring(i, min(text.length, i + 50)));
        stream.openBlocks;
      }
      stream.finish();
      expect(stream.linesClassified, lines.length);
    });
  });
}
