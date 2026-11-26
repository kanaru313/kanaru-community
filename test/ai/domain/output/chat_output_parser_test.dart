import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/output/chat_output_parser.dart';

ChatOutputResult parse(
  Object output, {
  Set<String> offered = const {'search_library', 'play_tracks'},
  bool finalRound = false,
  int soFar = 0,
  ChatItemLimitCheck? itemLimit,
}) => parseChatOutput(
  output is String ? output : jsonEncode(output),
  turn: 3,
  round: 2,
  offeredNames: offered,
  finalRound: finalRound,
  callsSoFarInTurn: soFar,
  itemLimit: itemLimit,
);

Map<String, Object?> reply({
  String text = 'ok',
  String finish = 'stop',
  List<Object?>? calls,
}) => {
  'finish': finish,
  'text': text,
  'toolCalls': ?calls,
  'usage': {'input': 10, 'output': 5},
  'provider': {'sig': 'abc'},
};

ChatRoundOutput ok(ChatOutputResult r) => (r as ChatOutputOk).output;

void main() {
  test('app assigns call ids, provider ids kept', () {
    final r = ok(
      parse(
        reply(
          finish: 'tool_calls',
          calls: [
            {
              'providerId': 'call_abc',
              'name': 'search_library',
              'args': {'query': 'x'},
            },
            {'name': 'play_tracks', 'args': <String, Object?>{}},
          ],
        ),
      ),
    );
    expect(r.calls.map((c) => c.part.id), ['t3-r2-0', 't3-r2-1']);
    expect(r.calls[0].part.providerId, 'call_abc');
    expect(r.calls[1].part.providerId, isNull);
    expect(r.calls[0].part.args, {'query': 'x'});
    expect(r.calls.every((c) => c.refusal == null), isTrue);
    expect(r.finish, ChatFinish.toolCalls);
    expect(jsonDecode(r.providerJson!), {'sig': 'abc'});
    expect((r.inputTokens, r.outputTokens), (10, 5));
  });

  test('provider id over 64 chars dropped', () {
    final r = ok(
      parse(
        reply(
          calls: [
            {'providerId': 'a' * 65, 'name': 'search_library'},
            {'providerId': 'bad id!', 'name': 'search_library'},
          ],
        ),
      ),
    );
    expect(r.calls.map((c) => c.part.providerId), [null, null]);
  });

  test('nine calls in one round → bad_request', () {
    final calls = [
      for (var i = 0; i < 9; i++) {'name': 'search_library'},
    ];
    expect(parse(reply(calls: calls)), isA<ChatOutputRejected>());
    expect(parse(reply(calls: calls.take(8).toList())), isA<ChatOutputOk>());
  });

  test('more than 24 calls in one turn → limit card', () {
    final r = parse(
      reply(
        calls: [
          for (var i = 0; i < 3; i++) {'name': 'search_library'},
        ],
      ),
      soFar: 22,
    );
    expect(r, isA<ChatOutputLimit>());
    expect((r as ChatOutputLimit).limit.kind, ChatLimitKind.callsPerTurn);
    expect(
      parse(
        reply(
          calls: [
            {'name': 'search_library'},
          ],
        ),
        soFar: 23,
      ),
      isA<ChatOutputOk>(),
    );
  });

  test('item cap exceeded → limit card', () {
    List<ToolCallPart>? seen;
    final r = parse(
      reply(
        calls: [
          {
            'name': 'play_tracks',
            'args': {
              'trackIds': [1],
            },
          },
          {'name': 'unknown_tool'},
        ],
      ),
      itemLimit: (calls) {
        seen = calls;
        return const ChatLimitExceeded(ChatLimitKind.itemsAdded);
      },
    );
    expect((r as ChatOutputLimit).limit.kind, ChatLimitKind.itemsAdded);
    // Refused calls never count toward the item cap.
    expect(seen!.map((c) => c.name), ['play_tracks']);
    expect(
      parse(
        reply(
          calls: [
            {'name': 'play_tracks'},
          ],
        ),
        itemLimit: (_) => null,
      ),
      isA<ChatOutputOk>(),
    );
  });

  test('unknown tool → error result', () {
    final r = ok(
      parse(
        reply(
          calls: [
            {
              'name': 'x' * 100,
              'args': {'a': 1},
            },
            {
              'name': 'delete_everything',
              'args': {'a': 1},
            },
          ],
        ),
      ),
    );
    expect(r.calls.map((c) => c.refusal), [
      ChatCallRefusal.unknownTool,
      ChatCallRefusal.unknownTool,
    ]);
    expect(r.calls[0].part.name.length, 64);
    // A refused call is stored without arguments.
    expect(r.calls[1].part.args, isEmpty);
  });

  test('raw args → error result', () {
    final r = ok(
      parse(
        reply(
          calls: [
            {'name': 'search_library', 'args': '{"query": '},
            {
              'name': 'search_library',
              'args': [1, 2],
            },
          ],
        ),
      ),
    );
    expect(r.calls.map((c) => c.refusal), [
      ChatCallRefusal.rawArguments,
      ChatCallRefusal.rawArguments,
    ]);
    expect(r.calls[0].part.rawArgs, '{"query": ');
    expect(r.calls[0].part.args, isNull);
    expect(r.calls[1].part.rawArgs, '[1,2]');
  });

  test('call in a none round → error result', () {
    final r = ok(
      parse(
        reply(
          calls: [
            {'name': 'search_library', 'args': <String, Object?>{}},
          ],
        ),
        finalRound: true,
      ),
    );
    expect(r.calls.single.refusal, ChatCallRefusal.noToolsInThisRound);
  });

  test('blocked is a normal result, even with no text', () {
    final r = ok(parse(reply(text: '', finish: 'blocked')));
    expect(r.finish, ChatFinish.blocked);
  });

  test('shapes that are not a reply are rejected', () {
    for (final bad in <Object>[
      'not json',
      '[]',
      {'finish': 'stop'},
      {'text': 'x'},
      {'finish': 'weird', 'text': 'x'},
      reply(text: '  ', calls: []),
      {'finish': 'stop', 'text': 'x', 'toolCalls': 'no'},
      reply(calls: [5]),
      reply(calls: [<String, Object?>{}]),
    ]) {
      expect(parse(bad), isA<ChatOutputRejected>(), reason: '$bad');
    }
  });

  test('assistant text is cleaned of control and bidi characters', () {
    final r = ok(
      parse(
        reply(
          text: 'a${String.fromCharCode(0x202E)}b${String.fromCharCode(0)}c\nd',
        ),
      ),
    );
    expect(r.text, 'abc\nd');
  });
}
