import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/package/manifest_parser.dart';

import 'support/config_harness.dart';
import 'support/pump_form.dart';

/// `<type>__<slug>.json` to the fields of its `config`.
Map<String, List<ConfigField>> _configs() {
  final out = <String, List<ConfigField>>{};
  for (final file in Directory(
    'test/plugins/fixtures/manifests',
  ).listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
    final name = file.uri.pathSegments.last;
    final parsed = parseManifest(file.readAsStringSync());
    final manifest = switch (parsed) {
      Ok(:final value) => value,
      Err(:final error) => fail('$name refused: $error'),
    };
    if (manifest.config.isNotEmpty) out[name] = manifest.config;
  }
  return out;
}

void main() {
  final configs = _configs();

  test('the shipped manifests cover every kind of field that has a form', () {
    final kinds = {
      for (final f in configs.values.expand((c) => c))
        switch (f) {
          InputField(:final format) => 'input:${format.name}',
          SelectField(:final format, :final custom) =>
            'select:${format.name}${custom ? ':custom' : ''}',
          ToggleField() => 'toggle',
          ListField() => 'list',
          MapField() => 'map',
        },
    };
    expect(
      kinds,
      containsAll([
        'input:text',
        'input:multiline',
        'input:number',
        'input:integer',
        'select:single',
        'select:single:custom',
        'toggle',
        'list',
      ]),
    );
  });

  for (final MapEntry(key: name, value: fields) in configs.entries) {
    for (final (shell, size) in [
      ('phone', phoneSize),
      ('desktop', desktopSize),
    ]) {
      testWidgets('$name renders every field on the $shell', (tester) async {
        final h = ConfigHarness(fields);
        await pumpConfigForm(tester, h, size: size);
        expect(tester.takeException(), isNull);
        for (final field in fields) {
          final title = field.title.isEmpty ? field.key : field.title;
          expect(
            find.textContaining(title),
            findsWidgets,
            reason: '${field.key} of $name',
          );
        }
        expect(h.calls, isEmpty, reason: 'showing the form saves nothing');
      });
    }
  }
}
