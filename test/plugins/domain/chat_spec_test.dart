import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/chat_spec.dart';

import 'chat_test_support.dart';

List<Object?> models(Map<String, Object?> json) =>
    chatBlock(json)['models']! as List<Object?>;

void main() {
  test('valid block parses all fields', () {
    final chat = parseOk(chatManifest()).chat!;
    expect(chat.models.single.id, 'gemini-2.5-flash');
    expect(chat.models.single.title, 'Gemini 2.5 Flash');
    expect(chat.models.single.tools, isTrue);
    expect(chat.models.single.vision, isTrue);
    expect(chat.models.single.context, 1048576);
    expect(chat.custom.tools, isTrue);
    expect(chat.custom.vision, isFalse);
    expect(chat.custom.context, 65536);
    expect(chat.keyField, 'apiKeys');
    expect(chat.idleTimeoutSec, 60);
  });

  test('absent or empty models accepted', () {
    expect(
      parseOk(chatManifest((j) => chatBlock(j).remove('models'))).chat!.models,
      isEmpty,
    );
    expect(
      parseOk(chatManifest((j) => chatBlock(j)['models'] = [])).chat!.models,
      isEmpty,
    );
  });

  test('more than 50 models refused', () {
    expectInvalid(
      chatManifest(
        (j) => chatBlock(j)['models'] = [
          for (var i = 0; i < 51; i++) {'id': 'm$i'},
        ],
      ),
      'chat.models',
    );
  });

  for (final id in ['', 'has space', 'bad<id>', 'x' * 121, 5]) {
    test('bad model id refused as chat.models.id: $id', () {
      expectInvalid(
        chatManifest((j) => models(j).add({'id': id})),
        'chat.models.id',
      );
    });
  }

  test('model id with allowed punctuation accepted', () {
    parseOk(chatManifest((j) => models(j).add({'id': 'models/a.b_c:1@x-y'})));
  });

  test('duplicate model id refused', () {
    expectInvalid(
      chatManifest((j) => models(j).add({'id': 'gemini-2.5-flash'})),
      'chat.models.id',
    );
  });

  test('model title defaults to its id and is bounded', () {
    final chat = parseOk(chatManifest((j) => models(j).add({'id': 'plain'})))
        .chat!;
    expect(chat.models.last.title, 'plain');
    expect(chat.models.last.tools, isFalse);
    expect(chat.models.last.vision, isFalse);
    expect(chat.models.last.context, chatDefaultContext);
    expectInvalid(
      chatManifest((j) => models(j).add({'id': 'a', 'title': 'x' * 81})),
      'chat.models.title',
    );
    expectInvalid(
      chatManifest((j) => models(j).add({'id': 'a', 'title': ''})),
      'chat.models.title',
    );
  });

  test('model tools and vision must be booleans', () {
    expectInvalid(
      chatManifest((j) => models(j).add({'id': 'a', 'tools': 'yes'})),
      'chat.models.tools',
    );
    expectInvalid(
      chatManifest((j) => models(j).add({'id': 'a', 'vision': 1})),
      'chat.models.vision',
    );
  });

  for (final context in [1023, 10000001, 'big']) {
    test('context out of range refused: $context', () {
      expectInvalid(
        chatManifest((j) => models(j).add({'id': 'a', 'context': context})),
        'chat.models.context',
      );
    });
  }

  test('context bounds accepted', () {
    parseOk(
      chatManifest(
        (j) => models(j)
          ..add({'id': 'a', 'context': 1024})
          ..add({'id': 'b', 'context': 10000000}),
      ),
    );
  });

  test('custom defaults to tools false vision false 32768', () {
    final chat = parseOk(chatManifest((j) => chatBlock(j).remove('custom')))
        .chat!;
    expect(chat.custom.tools, isFalse);
    expect(chat.custom.vision, isFalse);
    expect(chat.custom.context, 32768);
  });

  test('custom with a bad context refused', () {
    expectInvalid(
      chatManifest((j) => chatBlock(j)['custom'] = {'context': 10}),
      'chat.custom.context',
    );
    expectInvalid(
      chatManifest((j) => chatBlock(j)['custom'] = 'x'),
      'chat.custom',
    );
  });

  test('capabilitiesOf falls back to custom', () {
    final chat = parseOk(chatManifest()).chat!;
    expect(chat.capabilitiesOf('gemini-2.5-flash').vision, isTrue);
    expect(chat.capabilitiesOf('other').context, 65536);
  });

  test('idleTimeoutSec defaults to 90 and above 90 is refused', () {
    expect(
      parseOk(chatManifest((j) => chatBlock(j).remove('idleTimeoutSec')))
          .chat!
          .idleTimeoutSec,
      90,
    );
    expectInvalid(
      chatManifest((j) => chatBlock(j)['idleTimeoutSec'] = 91),
      'chat.idleTimeoutSec',
    );
    expectInvalid(
      chatManifest((j) => chatBlock(j)['idleTimeoutSec'] = 0),
      'chat.idleTimeoutSec',
    );
  });

  test('keyField is optional', () {
    expect(
      parseOk(chatManifest((j) => chatBlock(j).remove('keyField')))
          .chat!
          .keyField,
      isNull,
    );
  });

  test('keyField naming an unknown field refused', () {
    expectInvalid(
      chatManifest((j) => chatBlock(j)['keyField'] = 'nope'),
      'chat.keyField',
    );
  });

  test('keyField naming a non-required field refused', () {
    expectInvalid(
      chatManifest(
        (j) => (chatConfig(j)['apiKeys']! as Map)['required'] = false,
      ),
      'chat.keyField',
    );
  });

  test('keyField naming a select field refused', () {
    expectInvalid(
      chatManifest((j) {
        chatBlock(j)['keyField'] = 'model';
        (chatConfig(j)['model']! as Map)['required'] = true;
      }),
      'chat.keyField',
    );
  });

  test('keyField naming a required list field accepted', () {
    parseOk(
      chatManifest((j) {
        chatConfig(j)['apiKeys'] = {
          'title': 'Keys',
          'mode': 'list',
          'format': 'text',
          'required': true,
        };
      }),
    );
  });

  test('a malformed keyField refused', () {
    expectInvalid(
      chatManifest((j) => chatBlock(j)['keyField'] = 7),
      'chat.keyField',
    );
  });
}
