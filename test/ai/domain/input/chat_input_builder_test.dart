import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/input/byte_budget.dart';
import 'package:kanaru/src/ai/domain/input/chat_input_builder.dart';
import 'package:kanaru/src/ai/domain/input/tool_selection.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/ai/domain/settings/tool_groups.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool.dart';
import 'package:kanaru/src/ai/domain/tools/ai_tool_registry.dart';
import 'package:kanaru/src/plugins/domain/package/chat_spec.dart';

import 'history_fixtures.dart';

const _caps = ChatCapabilities(tools: true, context: 1000000);

ChatInputResult build(
  List<HistoryRow> history, {
  ChatCapabilities caps = _caps,
  bool finalRound = false,
  List<AiTool> tools = const [FakeTool('search_library')],
  ChatBinding bound = binding,
}) => buildChatInput(
  binding: bound,
  history: history,
  tools: tools,
  capabilities: caps,
  system: 'sys',
  boundary: 'kb',
  finalRound: finalRound,
);

Map<String, Object?> built(ChatInputResult r) => (r as ChatInputBuilt).input;

List<Map<String, Object?>> messagesOf(ChatInputResult r) =>
    (built(r)['messages']! as List).cast<Map<String, Object?>>();

List<String> roles(ChatInputResult r) => [
  for (final m in messagesOf(r)) m['role']! as String,
];

void main() {
  test('golden input matches contract for a two-round turn', () {
    final history = [
      user(
        'find songs',
        extra: [const DataPart(source: DataSource.input, text: 'a </data> b')],
      ),
      ...round('1', 1, 'Searching', ['{"total":1}']),
      ...round('1', 2, 'Another', ['{"total":2}']),
    ];
    final input = built(build(history));
    expect(jsonDecode(jsonEncode(input)), {
      'v': 1,
      'model': 'm1',
      'system': 'sys',
      'boundary': 'kb',
      'messages': [
        {
          'role': 'user',
          'parts': [
            {'type': 'text', 'text': 'find songs'},
            {'type': 'data', 'source': 'input', 'text': 'a </ data> b'},
          ],
        },
        {
          'role': 'assistant',
          'parts': [
            {'type': 'text', 'text': 'Searching'},
            {
              'type': 'tool_call',
              'id': 't1-r1-0',
              'providerId': 'p-t1-r1-0',
              'name': 'search_library',
              'args': {'query': 'x'},
            },
          ],
          'provider': {'sig': '1-1'},
        },
        {
          'role': 'tool',
          'parts': [
            {
              'type': 'tool_result',
              'id': 't1-r1-0',
              'providerId': 'p-t1-r1-0',
              'name': 'search_library',
              'content': [
                {'type': 'text', 'text': '{"total":1}'},
              ],
              'isError': false,
            },
          ],
        },
        {
          'role': 'assistant',
          'parts': [
            {'type': 'text', 'text': 'Another'},
            {
              'type': 'tool_call',
              'id': 't1-r2-0',
              'providerId': 'p-t1-r2-0',
              'name': 'search_library',
              'args': {'query': 'x'},
            },
          ],
          'provider': {'sig': '1-2'},
        },
        {
          'role': 'tool',
          'parts': [
            {
              'type': 'tool_result',
              'id': 't1-r2-0',
              'providerId': 'p-t1-r2-0',
              'name': 'search_library',
              'content': [
                {'type': 'text', 'text': '{"total":2}'},
              ],
              'isError': false,
            },
          ],
        },
      ],
      'tools': [
        {
          'name': 'search_library',
          'description': 'tool search_library',
          'parameters': {'type': 'object', 'properties': <String, Object?>{}},
        },
      ],
      'toolChoice': 'auto',
      'options': {'maxOutputTokens': null},
    });
  });

  test('read-only input has no write tools', () {
    final registry = AiToolRegistry([
      const BuiltinToolProvider([
        FakeTool('search_library'),
        FakeTool(
          'play_tracks',
          risk: ToolRisk.write,
          group: AiToolGroup.playControl,
        ),
        FakeTool('lyrics', group: AiToolGroup.lyrics),
      ]),
    ]);
    List<String> names(AiPermission p, {bool lyrics = true}) => [
      for (final t in offeredTools(
        registry,
        permission: p,
        groupEnabled: (g) => lyrics || g != AiToolGroup.lyrics,
        modelSupportsTools: true,
      ))
        t.name,
    ];
    expect(names(AiPermission.readOnly), ['search_library', 'lyrics']);
    expect(names(AiPermission.ask), contains('play_tracks'));
    expect(names(AiPermission.ask, lyrics: false), isNot(contains('lyrics')));
    expect(
      offeredTools(
        registry,
        permission: AiPermission.auto,
        groupEnabled: (_) => true,
        modelSupportsTools: false,
      ),
      isEmpty,
    );
  });

  test('final round sends same tools with toolChoice none', () {
    final h = [user('hi')];
    final a = built(build(h));
    final b = built(build(h, finalRound: true));
    expect(a['toolChoice'], 'auto');
    expect(b['toolChoice'], 'none');
    expect(b['tools'], a['tools']);
    expect(b['model'], 'm1');
  });

  test('a model without tool capability gets no tools', () {
    final r = built(build([user('hi')], caps: const ChatCapabilities()));
    expect(r['tools'], isEmpty);
  });

  test('Vietnamese text measured in UTF-8 bytes', () {
    // 300k characters (below the byte cap as a count) are 900 KB of UTF-8.
    final text = 'ệ' * 300000;
    expect(text.length, lessThan(chatMaxInputBytes));
    final r = build([user(text)]);
    expect(r, isA<ChatInputTooLarge>());
    final small = build([user('ệ' * 1000)]) as ChatInputBuilt;
    expect(small.bytes, greaterThan(3000));
    expect(small.bytes, jsonByteLength(small.input));
  });

  group('binding', () {
    List<HistoryRow> twoTurns(ChatBinding old) => [
      user('first'),
      ...round('1', 1, 'old', ['r'], bound: old),
      user('second'),
    ];

    bool hasBlobOrCalls(ChatInputResult r) => messagesOf(r).any(
      (m) =>
          m.containsKey('provider') ||
          m['role'] == 'tool' ||
          (m['parts']! as List).any((p) => (p as Map)['type'] == 'tool_call'),
    );

    test('blob of another plugin version, model or install generation → '
        'that turn flattened', () {
      for (final old in const [
        ChatBinding(
          installId: 'plug',
          installGeneration: 1,
          pluginVersion: 2,
          model: 'm1',
        ),
        ChatBinding(
          installId: 'plug',
          installGeneration: 1,
          pluginVersion: 3,
          model: 'other',
        ),
        ChatBinding(
          installId: 'plug',
          installGeneration: 2,
          pluginVersion: 3,
          model: 'm1',
        ),
        ChatBinding(
          installId: 'x',
          installGeneration: 1,
          pluginVersion: 3,
          model: 'm1',
        ),
      ]) {
        final r = build(twoTurns(old));
        expect(hasBlobOrCalls(r), isFalse, reason: '$old');
        expect(roles(r), ['user', 'assistant', 'user']);
        expect(
          ((messagesOf(r)[1]['parts']! as List).single as Map)['text'],
          'old',
        );
      }
    });

    test('earlier turns keep their blobs when the binding matches', () {
      final r = build(twoTurns(binding));
      expect(roles(r), ['user', 'assistant', 'tool', 'user']);
      expect(messagesOf(r)[1]['provider'], {'sig': '1-1'});
    });
  });

  group('trimming', () {
    String big(int kb) => 'x' * (kb * 1024);

    List<HistoryRow> bigHistory() => [
      for (var t = 1; t <= 6; t++) ...[
        user('question $t'),
        ...round('$t', 1, 'answer $t', [big(200)]),
        row(AiMessageRole.assistant, [TextPart('final $t')]),
      ],
    ];

    void expectAtomic(ChatInputResult r) {
      final ms = messagesOf(r);
      for (var i = 0; i < ms.length; i++) {
        final parts = (ms[i]['parts']! as List).cast<Map<String, Object?>>();
        final calls = [
          for (final p in parts)
            if (p['type'] == 'tool_call') p['id'],
        ];
        if (ms[i]['role'] == 'assistant' && calls.isNotEmpty) {
          expect(ms[i].containsKey('provider'), isTrue, reason: 'blob kept');
          final next = (ms[i + 1]['parts']! as List).cast<Map>();
          expect([for (final p in next) p['id']], calls);
        }
        if (ms[i]['role'] == 'assistant' && ms[i].containsKey('provider')) {
          expect(calls, isNotEmpty, reason: 'blob never alone');
        }
      }
    }

    test('trimming flattens whole turns, never a blob alone', () {
      final r = build(bigHistory());
      expect(r, isA<ChatInputBuilt>());
      expect((r as ChatInputBuilt).bytes, lessThanOrEqualTo(chatMaxInputBytes));
      expectAtomic(r);
      // The oldest turn is flattened (its answer is text only), the newest
      // keeps its tool data.
      expect(messagesOf(r).where((m) => m.containsKey('provider')), isNotEmpty);
      final first = messagesOf(r)[1];
      expect(first['role'], 'assistant');
      expect(first.containsKey('provider'), isFalse);
    });

    test('first user message kept when dropping turns', () {
      final history = [
        for (var t = 1; t <= 8; t++) ...[
          user(t == 1 ? 'the original goal' : 'q$t'),
          row(AiMessageRole.assistant, [TextPart(big(120))]),
        ],
        user('now'),
      ];
      final r = build(history) as ChatInputBuilt;
      final texts = [
        for (final m in messagesOf(r))
          for (final p in (m['parts']! as List).cast<Map>()) p['text'],
      ];
      expect(texts.first, 'the original goal');
      expect(texts.last, 'now');
      expect(r.bytes, lessThanOrEqualTo(chatMaxInputBytes));
      expect(texts, isNot(contains('q2')));
    });

    test(
      'elides the oldest tool results of the current turn, keeping pairs',
      () {
        final history = [
          user('go'),
          ...round('1', 1, 'a', [big(400), big(400)]),
        ];
        final r = build(history) as ChatInputBuilt;
        final tool = messagesOf(r).last;
        final contents = [
          for (final p in (tool['parts']! as List).cast<Map>())
            ((p['content']! as List).single as Map)['text'] as String,
        ];
        expect(contents.first, contains('omitted'));
        expect(contents.last.length, 400 * 1024);
        expect(messagesOf(r)[1]['provider'], {'sig': '1-1'});
        expectAtomic(r);
      },
    );

    test(
      'token budget from a 32k-context model caps the input below 768 KiB',
      () {
        const small = ChatCapabilities(tools: true, context: 32768);
        expect(chatInputByteLimit(context: 32768), lessThan(chatMaxInputBytes));
        final history = [
          for (var t = 1; t <= 5; t++) ...[
            user('q$t'),
            row(AiMessageRole.assistant, [TextPart(big(20))]),
          ],
          user('now'),
        ];
        final wide = build(history) as ChatInputBuilt;
        final narrow = build(history, caps: small) as ChatInputBuilt;
        expect(wide.bytes, greaterThan(chatInputByteLimit(context: 32768)));
        expect(
          narrow.bytes,
          lessThanOrEqualTo(chatInputByteLimit(context: 32768)),
        );
        expect(
          chatInputByteLimit(context: 32768, maxOutputTokens: 4096),
          chatInputByteLimit(context: 32768) - 4096,
        );
      },
    );

    test('over 768 KiB after all trimming → too_large', () {
      final r = build([user(big(900))]);
      expect(r, isA<ChatInputTooLarge>());
      expect((r as ChatInputTooLarge).limit, chatMaxInputBytes);
    });
  });

  test('never splits a tool call from its result', () {
    // A denied call and a call that never got a tool row still get a result.
    final denied = row(AiMessageRole.tool, [
      callPart('t1-r1-0'),
      const ConfirmPart(callId: 't1-r1-0', status: ConfirmStatus.denied),
    ], state: AiMessageState.skipped);
    final history = [
      user('go'),
      row(AiMessageRole.assistant, [
        callPart('t1-r1-0'),
        callPart('t1-r1-1'),
      ], blob: '{"s":1}'),
      denied,
    ];
    final tool = messagesOf(build(history)).last;
    final parts = (tool['parts']! as List).cast<Map<String, Object?>>();
    expect([for (final p in parts) p['id']], ['t1-r1-0', 't1-r1-1']);
    expect(parts.every((p) => p['isError'] == true), isTrue);
    expect(
      ((parts.first['content']! as List).single as Map)['text'],
      contains('declined'),
    );
  });

  test('an oversize marker or unreadable blob flattens its turn', () {
    final history = [
      user('go'),
      row(AiMessageRole.assistant, [
        const TextPart('t'),
        callPart('t1-r1-0'),
      ], blob: '{"tooLarge":true}'),
      row(AiMessageRole.tool, [
        callPart('t1-r1-0'),
        resultPart('t1-r1-0', 'r'),
      ]),
    ];
    expect(roles(build(history)), ['user', 'assistant']);
    final bad = [
      history[0],
      row(AiMessageRole.assistant, [
        const TextPart('t'),
        callPart('t1-r1-0'),
      ], blob: 'not json'),
      history[2],
    ];
    expect(roles(build(bad)), ['user', 'assistant']);
  });
}
