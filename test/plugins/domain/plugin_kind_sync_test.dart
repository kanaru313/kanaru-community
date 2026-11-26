import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';

void main() {
  test('PluginKindValues equals PluginKind wire names', () {
    expect(PluginKindValues.values, {
      for (final k in PluginKind.values) k.wire,
    });
  });
}
