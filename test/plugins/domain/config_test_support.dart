import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/plugins/domain/config/config_field.dart';
import 'package:kanaru/src/plugins/domain/package/package_problem.dart';

import 'plugin_test_support.dart';

Map<String, Object?> cfgField(String mode, [Map<String, Object?>? more]) => {
  'title': 'T',
  'mode': mode,
  ...?more,
};

Map<String, Object?> cfgInput(String format, [Map<String, Object?>? more]) =>
    cfgField('input', {'format': format, ...?more});

T cfgOne<T extends ConfigField>(Map<String, Object?> field) =>
    configOk({'k': field}).single as T;

/// The field [field] is refused with `InvalidManifest('config.k.<attr>')`.
void cfgBad(String name, Map<String, Object?> field, String attr) {
  test(name, () {
    final problem = configProblem({'k': field});
    expect(problem, isA<InvalidManifest>(), reason: '$problem');
    expect(problem.detail, 'config.k.$attr');
  });
}

/// The field [field] is refused with `UnknownConfigFormat`.
void cfgBadFormat(String name, Map<String, Object?> field) {
  test(name, () {
    final problem = configProblem({'k': field});
    expect(problem, isA<UnknownConfigFormat>(), reason: '$problem');
    expect(problem.detail, 'config.k.format');
  });
}

final cfgOpts = [
  {'value': 'a', 'title': 'A', 'subtitle': 'first'},
  {'value': 'b', 'title': 'B'},
  {'value': 'c', 'title': 'C'},
];
