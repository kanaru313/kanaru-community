import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/output/ai_error_code.dart';
import 'package:kanaru/src/ai/domain/output/chat_readiness.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/package/chat_spec.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_manifest.dart';

PluginManifest manifest({List<ConfigField>? config, String? keyField}) =>
    PluginManifest(
      apiVersion: 1,
      kind: PluginKind.aiChat,
      name: 'Chat',
      version: 1,
      hosts: const ['api.example.com'],
      scripts: const {'chat': 'chat.js'},
      chat: ChatSpec(keyField: keyField),
      config:
          config ??
          const [
            InputField(key: 'apiKeys', title: 'API key', required: true),
            SelectField(key: 'model', title: 'Model', custom: true),
          ],
    );

void main() {
  const full = {'apiKeys': 'k', 'model': 'm'};

  test('ready when key and model are present', () {
    expect(
      chatReadiness(
        manifest: manifest(keyField: 'apiKeys'),
        storedConfig: full,
        conversationModel: 'm',
      ),
      isA<ChatReady>(),
    );
  });

  test('missing keyField value → needsKey', () {
    for (final empty in [null, '', '  ', <String>[]]) {
      expect(
        chatReadiness(
          manifest: manifest(keyField: 'apiKeys'),
          storedConfig: {'apiKeys': empty, 'model': 'm'},
          conversationModel: 'm',
        ),
        isA<ChatNeedsKey>(),
      );
    }
  });

  test('no model in conversation or config → needsModel', () {
    expect(
      chatReadiness(
        manifest: manifest(keyField: 'apiKeys'),
        storedConfig: const {'apiKeys': 'k'},
        conversationModel: null,
      ),
      isA<ChatNeedsModel>(),
    );
    expect(
      chatReadiness(
        manifest: manifest(keyField: 'apiKeys'),
        storedConfig: const {'apiKeys': 'k', 'model': ' '},
        conversationModel: '',
      ),
      isA<ChatNeedsModel>(),
    );
  });

  test('conversation model satisfies a missing config model', () {
    final m = manifest(
      keyField: 'apiKeys',
      config: const [
        InputField(key: 'apiKeys', title: 'API key', required: true),
        SelectField(key: 'model', title: 'Model', required: true, custom: true),
      ],
    );
    expect(
      chatReadiness(
        manifest: m,
        storedConfig: const {'apiKeys': 'k'},
        conversationModel: 'chosen',
      ),
      isA<ChatReady>(),
    );
  });

  test('other required fields → needsConfig with their titles', () {
    final m = manifest(
      keyField: 'apiKeys',
      config: const [
        InputField(key: 'apiKeys', title: 'API key', required: true),
        InputField(key: 'baseUrl', title: 'Base URL', required: true),
        ToggleField(key: 'flag', title: 'Flag', required: true),
      ],
    );
    final r = chatReadiness(
      manifest: m,
      storedConfig: const {'apiKeys': 'k'},
      conversationModel: 'm',
    );
    expect((r as ChatNeedsConfig).titles, ['Base URL']);
  });

  test('a plugin without keyField never needs a key', () {
    expect(
      chatReadiness(
        manifest: manifest(config: const []),
        storedConfig: const {},
        conversationModel: 'm',
      ),
      isA<ChatReady>(),
    );
  });

  test('removed and reinstalled plugins', () {
    expect(
      chatReadiness(
        manifest: null,
        storedConfig: const {},
        conversationModel: 'm',
      ),
      isA<ChatPluginRemoved>(),
    );
    expect(
      chatReadiness(
        manifest: manifest(keyField: 'apiKeys'),
        storedConfig: full,
        conversationModel: 'm',
        reinstalled: true,
      ),
      isA<ChatPluginReinstalled>(),
    );
  });

  group('AiErrorCode.parse', () {
    test('known codes, text after the code dropped', () {
      expect(AiErrorCode.parse('ai:rate_limit'), AiErrorCode.rateLimit);
      expect(
        AiErrorCode.parse('ai:model_not_found: sk-secret leaked'),
        AiErrorCode.modelNotFound,
      );
    });

    test('unknown, no_key, no prefix and null → server', () {
      for (final m in [
        'ai:no_key',
        'ai:nope',
        'bad_request',
        'ai:',
        '',
        null,
      ]) {
        expect(AiErrorCode.parse(m), AiErrorCode.server, reason: '$m');
      }
    });
  });
}
