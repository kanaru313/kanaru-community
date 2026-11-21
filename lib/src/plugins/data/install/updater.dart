import 'package:logging/logging.dart';

import '../../../foundation/result.dart';
import '../../domain/install/held_package.dart';
import '../../domain/install/install_result.dart';
import '../repos/catalog_cache.dart';
import '../store/plugin_repo_rows.dart';
import '../store/plugin_rows.dart';
import 'held_packages.dart';
import 'installer.dart';
import 'plugin_activity.dart';
import 'update_candidates.dart';

final _log = Logger('plugin_update');

/// Updates one installed repository plugin without asking, as far as the
/// rules allow: it downloads nothing for an update the catalog already shows
/// as adding hosts, and installs nothing a downloaded package would add hosts
/// to. Those come back for the user to review.
class PluginUpdater {
  PluginUpdater({
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

  final _running = <String, Future<InstallResult>>{};

  /// Updates [installId] from its repository. [keepForReview] keeps a
  /// downloaded package that needs review held (the screen opens "Cần xem"
  /// with its token); update all drops it. A call made while one runs for the
  /// same plugin shares it. Never throws.
  Future<InstallResult> update(String installId, {bool keepForReview = true}) =>
      _running[installId] ??= _activity
          .track(installId, () => _update(installId, keepForReview))
          .whenComplete(() {
            _running.remove(installId);
          });

  Future<InstallResult> _update(String installId, bool keepForReview) async {
    try {
      final row = await _rows.liveById(installId);
      if (row == null) return const InstallRefused(InstallFailure.pluginGone);
      final repo = row.repoUrl == null
          ? null
          : await _repoRows.byUrl(row.repoUrl!);
      final found = resolveUpdate(row, repo, _catalogs);
      final update = found.update;
      if (update == null) return InstallRefused(found.failure!);
      if (update.kindRefused) {
        return const InstallRefused(InstallFailure.kindChange);
      }
      // Nothing is downloaded for an update that already needs review.
      if (update.needsReview) {
        return const InstallRefused(InstallFailure.needsReview);
      }
      final prepared = await _held
          .prepareFromRepo(update.repo.id, update.entry.slug)
          .result;
      final HeldPackage held;
      switch (prepared) {
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
        options: const InstallOptions(silentOnly: true),
      );
      if (result is InstallNeedsReview) {
        _activity.flagReview(installId);
        if (!keepForReview) _held.discard(held.token);
      } else if (result case InstallRefused(
        failure: InstallFailure.needsReview,
      )) {
        _activity.flagReview(installId);
      }
      return result;
    } on Object catch (error) {
      _log.warning('Update failed: ${error.runtimeType}');
      return const InstallRefused(InstallFailure.unexpected);
    }
  }
}
