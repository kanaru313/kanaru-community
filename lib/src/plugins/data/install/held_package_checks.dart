import 'dart:async';

import 'package:logging/logging.dart';

import '../../../database/tables.dart';
import '../../domain/install/held_package.dart';
import '../../domain/install/script_checker.dart';
import '../../domain/install/update_diff.dart';
import '../../domain/package/plugin_package.dart';
import '../../domain/install/install_rules.dart' show sameOrigin;
import '../store/plugin_row_types.dart';
import 'held_source_mapping.dart';

final _log = Logger('plugin_checks');

/// One script is given this long to compile.
const scriptCheckTimeout = Duration(seconds: 10);

/// The checker could not run (library missing, or it hung): the package is
/// refused, never accepted unchecked.
class ScriptCheckUnavailableError implements Exception {
  const ScriptCheckUnavailableError();
}

/// Compiles every `src/*.js` of [package], the ones the manifest does not map
/// included (a script may `load()` a helper such as `common.js`). Returns the
/// syntax errors found. Throws [ScriptCheckUnavailableError] when a check
/// cannot run. [onProgress] gets the number of files done and the total.
Future<List<HeldProblem>> checkScripts(
  PluginPackage package,
  ScriptChecker checker, {
  Duration timeout = scriptCheckTimeout,
  void Function(int done, int total)? onProgress,
}) async {
  final names = package.scripts.keys.toList()..sort();
  final problems = <HeldProblem>[];
  for (var i = 0; i < names.length; i++) {
    onProgress?.call(i, names.length);
    try {
      final problem = await checker
          .check(names[i], package.scripts[names[i]]!)
          .timeout(timeout);
      if (problem != null) problems.add(ScriptSyntaxError(names[i], problem));
    } on Object catch (error) {
      _log.warning('Script check could not run: ${error.runtimeType}');
      throw const ScriptCheckUnavailableError();
    }
  }
  return problems;
}

/// What installing [package] over [row] (a tombstone or null: nothing
/// installed) would be. [problems] first: a package with problems is not
/// compared with anything.
PackageReview reviewOf(
  PluginPackage package,
  PluginRow? row,
  List<HeldProblem> problems, {
  required HeldSource source,
}) {
  final all = [...problems];
  final live = row != null && row.isLive;
  // A package may only replace a plugin installed from its own source.
  if (live && !sameOrigin(heldSourceOf(row.source), source)) {
    all.add(OtherOrigin(heldSourceOf(row.source)));
  }
  if (live && row.pluginKind == null) all.add(const InstalledKindUnknown());
  if (all.isNotEmpty) return ProblemsReview(List.unmodifiable(all));
  if (row == null || !live) return const InstallReview();
  if (row.version == package.manifest.version &&
      row.packageSha256 == package.sha256) {
    return const RepairReview();
  }
  return UpdateReview(
    diffUpdate(
      consentedHosts: row.consentedHosts,
      installedVersion: row.version,
      installedKind: row.pluginKind!,
      candidate: UpdateCandidate.fromPackage(package),
    ),
  );
}
