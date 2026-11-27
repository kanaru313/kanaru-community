import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/package/manifest_parser.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_manifest.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';

import 'chat_test_support.dart';
import 'config_test_support.dart';
import 'plugin_test_support.dart';
import 'seekbar_manifest_test.dart' show seekbarManifest;

const _int64Min = -9223372036854775808;
const _unsafe = 9007199254740992;

void main() {
  group('integers outside the range a script reads exactly', () {
    for (final attr in ['min', 'max', 'step']) {
      cfgBad(
        'integer $attr int64 min',
        cfgInput('integer', {attr: _int64Min}),
        attr,
      );
    }

    cfgBad(
      'integer default int64 min',
      cfgInput('integer', {'default': _int64Min}),
      'default',
    );
    cfgBad(
      'integer list item int64 min',
      cfgField('list', {
        'format': 'integer',
        'default': [_int64Min],
      }),
      'default',
    );
    cfgBad(
      'integer list item 2^53',
      cfgField('list', {
        'format': 'integer',
        'default': [_unsafe],
      }),
      'default',
    );

    test('an int64 min written in JSON text is refused too', () {
      final text = jsonEncode(
        withConfig({
          'k': {'title': 'T', 'mode': 'input', 'format': 'integer', 'min': 0},
        }),
      ).replaceFirst('"min":0', '"min":-9223372036854775808');
      expect(text, contains('-9223372036854775808'));
      final problem = switch (parseManifest(text)) {
        Ok() => fail('expected a problem'),
        Err(:final error) => error.single,
      };
      expect(problem.detail, 'config.k.min');
    });

    test('values at the safe limit are accepted, one past is not', () {
      expect(isSafeInt(configSafeInt), isTrue);
      expect(isSafeInt(-configSafeInt), isTrue);
      expect(isSafeInt(_unsafe), isFalse);
      expect(isSafeInt(-_unsafe), isFalse);
      expect(isSafeInt(_int64Min), isFalse);
    });
  });

  group('a double where an integer is required', () {
    cfgBad(
      'minItems 1.0',
      cfgField('list', {'format': 'text', 'minItems': 1.0}),
      'minItems',
    );
    cfgBad('rows 2.0', cfgInput('multiline', {'rows': 2.0}), 'rows');

    test('maxLines 60.0 is refused', () {
      expectInvalid(
        translateManifest((j) => (j['translate']! as Map)['maxLines'] = 60.0),
        'translate.maxLines',
      );
    });
  });

  group('hostile structure', () {
    test('a 10 000 deep value under an ignored key is accepted', () {
      final deep = '${'[' * 10000}${']' * 10000}';
      final text = jsonEncode(validManifest())
          .replaceFirst('{"metadata"', '{"future":$deep,"metadata"');
      final result = parseManifest(text);
      expect(result, isA<Ok<PluginManifest, List<PackageProblem>>>());
    });

    test('an option that is not an object is refused', () {
      for (final option in ['a', 1, null, [], true]) {
        final problem = configProblem({
          'k': {
            'title': 'T',
            'mode': 'select',
            'options': [option],
          },
        });
        expect(problem, isA<InvalidManifest>(), reason: '$option');
      }
    });
  });

  group('every plugin kind parses from a manifest', () {
    final manifests = {
      PluginKind.lyrics: validManifest(),
      PluginKind.translate: translateManifest(),
      PluginKind.aiTranslate: aiManifest(),
      PluginKind.streaming: streamingManifest(),
      PluginKind.aiChat: chatManifest(),
      PluginKind.seekbar: seekbarManifest(),
    };
    for (final MapEntry(key: kind, value: json) in manifests.entries) {
      test(kind.wire, () => expect(parseOk(json).kind, kind));
    }
    test('the table covers every kind', () {
      expect(manifests.keys.toSet(), PluginKind.values.toSet());
    });
  });
}
