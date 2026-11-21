import 'package:logging/logging.dart';

import '../../../foundation/result.dart';
import '../../../platform/domain/document_picker.dart';
import '../../domain/install/held_package.dart';
import '../../domain/install/install_result.dart';
import '../../domain/install/prepare_result.dart';
import '../repos/catalog_cache.dart';
import '../store/plugin_repo_rows.dart';
import '../store/plugin_row_types.dart';
import '../store/plugin_rows.dart';
import 'held_packages.dart';
import 'installer.dart';
import 'plugin_activity.dart';

final _log = Logger('plugin_repair');

/// Brings a plugin's package folder back (repair, and the restore re-install
/// that uses it). A repository or link plugin is downloaded again with every
/// check. The same version is written again only when the zip hash equals
/// the stored one (silently); a newer version goes through the update rules
/// (silent when its hosts are consented, else "Cần xem"); the same version
/// with another hash is refused as `sameVersion`. A file plugin can only be
/// repaired by picking a file ([repairFromFile]).
class PluginRepairer {
  PluginRepairer({
    required this._rows,
    required this._repoRows,
    required this._catalogs,
    required this._held,
    required this._installer,
    required this._activity,
  });

  final PluginRows _rows;
  final PluginRepoRows _repoRows;
  final CatalogCache _catalogs;
  final HeldPackages _held;
  final PluginInstaller _installer;
  final PluginActivity _activity;

  /// Repairs [installId]. With [restore] a package needing review is
  /// dropped and flagged, not held (the user is not looking at it). Never
  /// throws.
  Future<InstallResult> repair(String installId, {bool restore = false}) async {
    try {
      final row = await _rows.liveById(installId);
      if (row == null) return const InstallRefused(InstallFailure.pluginGone);
      final PrepareOperation op;
      switch (row.originKind) {
        case PluginOrigin.file || null:
          return const InstallRefused(InstallFailure.needsFile);
        case PluginOrigin.link:
          op = _held.prepareFromLink(row.originLabel ?? '');
        case PluginOrigin.repo:
          final repo = await _repoRows.byUrl(row.repoUrl ?? '');
          if (repo == null) {
            return const InstallRefused(InstallFailure.repoRemoved);
          }
          final entry = _catalogs.entryOf(repo, row.repoSlug ?? '');
          if (entry == null) {
            return const InstallRefused(InstallFailure.entryGone);
          }
          if (entry.needsNewerApp) {
            return const InstallRefused(InstallFailure.needsNewerApp);
          }
          op = _held.prepareFromRepo(repo.id, entry.slug);
      }
      return await _finish(op, installId, restore: restore);
    } on Object catch (error) {
      _log.warning('Repair failed: ${error.runtimeType}');
      return const InstallRefused(InstallFailure.unexpected);
    }
  }

  /// The user picked [doc] to bring back the file plugin [installId]: the
  /// update rules (same origin; same version only with an equal hash). A
  /// package that needs review stays held for the screen. Never throws.
  Future<InstallResult> repairFromFile(
    String installId,
    PickedDocument doc,
  ) async {
    try {
      return await _finish(_held.prepareFromFile(doc), installId);
    } on Object catch (error) {
      _log.warning('Repair from file failed: ${error.runtimeType}');
      return const InstallRefused(InstallFailure.unexpected);
    }
  }

  Future<InstallResult> _finish(
    PrepareOperation op,
    String installId, {
    bool restore = false,
  }) async {
    final HeldPackage held;
    switch (await op.result) {
      case Err(:final error):
        return InstallPrepareFailed(error);
      case Ok(:final value):
        held = value;
    }
    if (held.review is ProblemsReview) {
      _held.discard(held.token);
      return InstallRefused(
        (held.review as ProblemsReview).hasOtherOrigin
            ? InstallFailure.otherOrigin
            : InstallFailure.hasProblems,
      );
    }
    final result = await _installer.install(
      held.token,
      options: InstallOptions(
        silentOnly: true,
        allowRepair: true,
        expectId: installId,
      ),
    );
    final keep = !restore && result is InstallNeedsReview;
    if (result is InstallNeedsReview) _activity.flagReview(installId);
    if (!keep && _held.peek(held.token) != null) _held.discard(held.token);
    return result;
  }
}
