import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/ai_message.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/conversation/parts_codec.dart';
import 'package:kanaru/src/ai/domain/conversation/track_ref_snapshot.dart';
import 'package:kanaru/src/ai/domain/permission.dart';
import 'package:kanaru/src/database/tables/ai_tables.dart';

const _song = TrackRefSnapshot(
  trackId: 7,
  title: 'Đừng | quên',
  artist: 'Ai đó',
  album: 'Album',
);

final _allParts = <AiPart>[
  const TextPart('xin chào'),
  const DataPart(source: DataSource.nowPlaying, text: 'a <data b'),
  const ToolCallPart.parsed(
    id: 't1-r1-0',
    providerId: 'call_abc',
    name: 'search_library',
    args: {
      'query': 'đừng',
      'limit': 5,
      'nested': [1, 2, null],
    },
  ),
  const ToolCallPart.raw(id: 't1-r1-1', name: 'play_tracks', rawArgs: '{"a":'),
  const ToolResultPart(
    id: 't1-r1-0',
    providerId: 'call_abc',
    name: 'search_library',
    content: [
      TextPart('1|a|b|c|2020'),
      DataPart(source: DataSource.track, text: 'x'),
    ],
  ),
  const ToolResultPart(
    id: 't1-r1-1',
    name: 'play_tracks',
    content: [TextPart('lỗi')],
    isError: true,
  ),
  for (final s in ConfirmStatus.values)
    ConfirmPart(
      callId: 't1-r1-1',
      status: s,
      reason: s == ConfirmStatus.denied ? 'user' : null,
      approvalHash: s == ConfirmStatus.allowed ? 'abc123' : null,
    ),
  const DonePart(callId: 't1-r1-1'),
  const DonePart(
    callId: 't1-r1-2',
    added: [_song],
    removed: [_song],
    absent: [9, 10],
    replacedQueue: ReplacedQueueSnapshot(
      tracks: [3, 2, 1],
      userOrder: [1, 2, 3],
      shuffled: true,
      previousIndex: 1,
    ),
  ),
  const ErrorPart(code: 'server', kind: 'server'),
  ErrorPart(
    code: 'rate_limit',
    kind: 'rateLimited',
    retryAt: DateTime.fromMillisecondsSinceEpoch(1764000000000),
  ),
  const EventPart.pluginSwitch(fromName: 'Gemini', toName: 'OpenAI'),
  for (final k in ChipKind.values)
    ChipPart(
      kind: k,
      ref: k == ChipKind.playlist ? '4' : null,
      label: 'nhãn',
      tracks: k == ChipKind.song || k == ChipKind.songs ? [_song] : const [],
    ),
];

void main() {
  group('parts codec', () {
    test('every part round-trips through JSON', () {
      final back = decodeParts(encodeParts(_allParts));
      expect(back, hasLength(_allParts.length));
      for (var i = 0; i < _allParts.length; i++) {
        expect(back[i], _allParts[i], reason: 'part $i');
        expect(back[i], isNot(isA<UnknownPart>()), reason: 'part $i');
      }
    });

    test('the text carries the format version', () {
      final json = jsonDecode(encodeParts(const [TextPart('a')]));
      expect(json, {
        'v': 1,
        'parts': [
          {'t': 'text', 'text': 'a'},
        ],
      });
    });

    test('unknown part type kept as unknown and written back unchanged', () {
      const stored =
          '{"v":1,"parts":[{"t":"text","text":"a"},'
          '{"t":"hologram","depth":3,"tags":["x"]}]}';
      final parts = decodeParts(stored);
      expect(parts[0], const TextPart('a'));
      final unknown = parts[1] as UnknownPart;
      expect(unknown.type, 'hologram');
      expect(unknown.json['depth'], 3);
      expect(jsonDecode(encodeParts(parts)), jsonDecode(stored));
    });

    test('a known type with a damaged shape is kept as unknown', () {
      const stored =
          '{"v":1,"parts":[{"t":"text","text":5},'
          '{"t":"data","source":"mystery","text":"x"},'
          '{"t":"tool_call","id":"a","name":"n"},'
          '{"t":"confirm","callId":"a","status":"maybe"},'
          '{"t":"done","callId":"a","added":[{"trackId":"x"}]},'
          '7]}';
      final parts = decodeParts(stored);
      expect(parts, hasLength(6));
      expect(parts, everyElement(isA<UnknownPart>()));
      expect(jsonDecode(encodeParts(parts.take(5).toList())), {
        'v': 1,
        'parts': [
          {'t': 'text', 'text': 5},
          {'t': 'data', 'source': 'mystery', 'text': 'x'},
          {'t': 'tool_call', 'id': 'a', 'name': 'n'},
          {'t': 'confirm', 'callId': 'a', 'status': 'maybe'},
          {
            't': 'done',
            'callId': 'a',
            'added': [
              {'trackId': 'x'},
            ],
          },
        ],
      });
    });

    test('v2 JSON refused with a typed error', () {
      expect(
        () => decodeParts('{"v":2,"parts":[]}'),
        throwsA(
          isA<UnsupportedPartsVersion>().having((e) => e.version, 'v', 2),
        ),
      );
      expect(
        () => decodeParts('{"parts":[]}'),
        throwsA(isA<UnsupportedPartsVersion>()),
      );
    });

    test('text that is not the parts shape is refused', () {
      for (final bad in ['not json', '[]', '{"v":1}', '{"v":1,"parts":{}}']) {
        expect(
          () => decodeParts(bad),
          throwsA(isA<MalformedParts>()),
          reason: bad,
        );
      }
    });

    test('a track snapshot with a wrong field type is refused', () {
      expect(
        () => TrackRefSnapshot.fromJson({'trackId': 1, 'title': 3}),
        throwsFormatException,
      );
      expect(() => TrackRefSnapshot.fromJson('x'), throwsFormatException);
    });
  });

  group('wire values match the stored value sets', () {
    test('permission, role and state', () {
      expect({
        for (final p in AiPermission.values) p.wire,
      }, AiPermissionValues.values);
      expect({
        for (final r in AiMessageRole.values) r.wire,
      }, AiMessageRoleValues.values);
      expect({
        for (final s in AiMessageState.values) s.wire,
      }, AiMessageStateValues.values);
    });

    test('unknown stored values are refused', () {
      expect(() => AiPermission.parse('god'), throwsFormatException);
      expect(() => AiMessageRole.parse(null), throwsFormatException);
      expect(() => AiMessageState.parse('weird'), throwsFormatException);
    });

    test('tool exec state maps to a stored message state and back', () {
      for (final s in ToolExecState.values) {
        expect(ToolExecState.fromMessageState(s.messageState), s);
      }
      expect(ToolExecState.failed.messageState, AiMessageState.error);
      expect(ToolExecState.fromMessageState(AiMessageState.complete), isNull);
    });
  });
}
