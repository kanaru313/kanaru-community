import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/data/store/plugin_row_types.dart';
import 'package:kanaru/src/plugins/domain/package/package_reader.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_package.dart';

import '../domain/plugin_test_support.dart';
import '../fixtures/zip_builders.dart';

/// An install id of the right shape; [n] tells ids apart.
String testInstallId([int n = 1]) =>
    'plugin-${n.toRadixString(16).padLeft(32, '0')}';

/// A package read from a real zip of [manifest] (default: the lyrics demo),
/// plus [extra] zip entries.
PluginPackage packageOf([
  Map<String, Object?>? manifest,
  Map<String, Object> extra = const {},
]) {
  final zip = validZip(manifest: manifest, extra: extra);
  return switch (readPackage(zip)) {
    Ok(:final value) => value,
    Err(:final error) => fail('package refused: $error'),
  };
}

PluginDraft draftOf(PluginPackage package, [String packageDir = 'v3-1000']) =>
    PluginDraft.fromPackage(package, packageDir: packageDir);

/// A lyrics manifest with the config [fields] (field key to its JSON).
Map<String, Object?> manifestWith(Map<String, Object?> fields) =>
    withConfig(fields);
