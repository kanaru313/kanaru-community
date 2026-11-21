import 'dart:async';
import 'dart:typed_data';

import '../../../foundation/result.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/install/held_package.dart';
import '../../domain/install/install_id.dart';
import '../../domain/install/prepare_result.dart';
import '../../domain/install/script_checker.dart';
import '../../domain/install/update_diff.dart';
import '../../domain/net/cancel_token.dart';
import '../../domain/package/package_problem.dart';
import '../../domain/package/plugin_package.dart';
import '../store/plugin_row_types.dart';
import '../store/plugin_rows.dart';
import 'held_package_checks.dart';
import 'held_source_mapping.dart';
import 'held_token_store.dart';

/// Turns downloaded bytes into a held package: reads the zip, checks every
/// script, compares with the catalog entry, reviews it against the installed
/// plugin and holds it under a new token.
class HeldPackageBuilder {
  HeldPackageBuilder({
    required this._checker,
    required this._rows,
    required this._tokens,
    required this._reader,
    required this._scriptTimeout,
  });

  final ScriptChecker _checker;
  final PluginRows _rows;
  final HeldTokenStore _tokens;
  final Future<Result<PluginPackage, PackageProblem>> Function(Uint8List)
  _reader;
  final Duration _scriptTimeout;

  /// Everything after the bytes arrived: read, script check, catalog match,
  /// review against the installed row, then hold under a token.
  Future<Result<HeldPackage, PrepareFailure>> build(
    Result<Uint8List, PrepareFailure> got,
    HeldSource source,
    CatalogEntry? entry,
    CancelToken cancel,
    void Function(PrepareProgress) emit,
  ) async {
    if (got case Err(:final error)) return Err(error);
    final bytes = (got as Ok<Uint8List, PrepareFailure>).value;
    emit(const PrepareProgress(PrepareStage.reading));
    final read = await _reader(bytes);
    if (read case Err(:final error)) return Err(PackageUnreadable(error));
    final package = (read as Ok<PluginPackage, PackageProblem>).value;
    if (cancel.isCancelled) return const Err(PrepareCancelled());

    final problems = <HeldProblem>[];
    try {
      problems.addAll(
        await checkScripts(
          package,
          _checker,
          timeout: _scriptTimeout,
          onProgress: (done, total) => emit(
            PrepareProgress(
              PrepareStage.checkingScripts,
              done: done,
              total: total,
            ),
          ),
        ),
      );
    } on ScriptCheckUnavailableError {
      return const Err(ScriptCheckUnavailable());
    }
    if (entry != null) {
      final differences = catalogMatches(entry, package);
      if (differences.isNotEmpty) problems.add(CatalogDiffers(differences));
    }
    if (cancel.isCancelled) return const Err(PrepareCancelled());

    final installId = switch (source) {
      RepoHeldSource(:final repoUrl, :final slug) => repoInstallId(
        repoUrl,
        slug,
      ),
      _ => fileInstallId(
        package.manifest.name,
        package.manifest.author.isEmpty ? null : package.manifest.author,
      ),
    };
    final row = await _rows.byId(installId);
    final held = HeldPackage(
      token: _tokens.newToken(),
      package: package,
      installId: installId,
      source: source,
      review: reviewOf(package, row, problems, source: source),
      snapshot: row != null && row.isLive ? snapshotOfRow(row) : null,
    );
    _tokens.put(held);
    return Ok(held);
  }
}
