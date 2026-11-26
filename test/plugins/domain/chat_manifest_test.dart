import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';

import 'chat_test_support.dart';

void main() {
  test('ai-chat manifest parses with chat spec', () {
    final manifest = parseOk(chatManifest());
    expect(manifest.kind, PluginKind.aiChat);
    expect(manifest.chat, isNotNull);
    expect(manifest.translate, isNull);
    expect(PluginKind.aiChat.isTranslation, isFalse);
    expect(PluginKind.aiChat.allowsWildcardHosts, isFalse);
  });

  test('chat block on a lyrics plugin refused', () {
    expectInvalid(withMeta((_) {})..['chat'] = {'models': []}, 'chat');
  });

  test('chat block on a translate plugin refused', () {
    expectInvalid(aiManifest((_) {}, 'translate')..['chat'] = {}, 'chat');
  });

  test('ai-chat without chat block refused', () {
    expectInvalid(chatManifest((j) => j.remove('chat')), 'chat');
  });

  test('ai-chat without the chat script refused', () {
    expectInvalid(
      chatManifest((j) => j['script'] = {'translate': 'translate.js'}),
      'script.chat',
    );
  });

  test('wildcard hosts refused on ai-chat', () {
    final problem = problemOf(
      chatManifest((j) => (j['metadata']! as Map)['hosts'] = ['*.example.com']),
    );
    expect(problem, isA<WildcardHostNotAllowed>());
    expect(problem.detail, '*.example.com');
  });

  test('model field missing refused as config.model', () {
    expectInvalid(
      chatManifest((j) => chatConfig(j).remove('model')),
      'config.model',
    );
  });

  test('multiple select model refused as config.model', () {
    expectInvalid(
      chatManifest((j) {
        final model = chatConfig(j)['model']! as Map<String, Object?>;
        model.remove('custom');
        model['format'] = 'multiple';
      }),
      'config.model',
    );
  });

  test('model as an input refused as config.model', () {
    expectInvalid(
      chatManifest(
        (j) => chatConfig(j)['model'] = {'title': 'Model', 'mode': 'input'},
      ),
      'config.model',
    );
  });

  test('custom model without options accepted', () {
    parseOk(
      chatManifest((j) {
        final model = chatConfig(j)['model']! as Map<String, Object?>;
        model['options'] = <Object?>[];
        model['custom'] = true;
      }),
    );
  });

  test('non-required model accepted', () {
    final model = parseOk(chatManifest()).config.first;
    expect(model.key, 'model');
    expect(model.required, isFalse);
  });

  test('required model accepted', () {
    parseOk(
      chatManifest((j) => (chatConfig(j)['model']! as Map)['required'] = true),
    );
  });
}
