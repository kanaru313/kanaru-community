import 'package:logging/logging.dart';

import '../../../database/tables.dart';
import '../../domain/install/held_package.dart';
import '../../domain/install/install_result.dart';
import '../../domain/install/install_rules.dart';
import '../../domain/package/plugin_kind.dart';
import '../store/plugin_row_types.dart';
import '../store/plugin_rows.dart';
import 'held_packages.dart';
import 'held_source_mapping.dart';
import 'package_writer.dart';
import 'plugin_activity.dart';
import 'streaming_gate.dart';
import 'write_queue.dart';

final _log = Logger('plugin_install');

/// How an install is allowed to go; the plain screen path uses the defaults.
class InstallOptions {
  const InstallOptions({
    this.silentOnly = false,
    this.allowRepair = false,
    this.expectId,
  });

  /// Update all, repair and restore: a package that adds hosts is not
  /// installed but handed back as [InstallNeedsReview].
  final bool silentOnly;

  /// The same version and zip hash may be written again.
  final bool allowRepair;

  /// The package must be for this install id (a repair picks one plugin).
  final String? expectId;
}

/// Installs and updates the held package: every rule is checked inside the
/// queue job, against the row as it is then, so what the user reviewed and
/// what gets written cannot drift apart.
class PluginInstaller {
  PluginInstaller({
    required this._queue,
    required this._rows,
    required this._held,
    required this._writer,
    required this._gate,
    required this._activity,
  });

  final PluginWriteQueue _queue;
  final PluginRows _rows;
  final HeldPackages _held;
  final PackageWriter _writer;
  final StreamingGate _gate;
  final PluginActivity _activity;

  /// Installs the package held under [token]. A second call for one plugin
  /// while the first is queued or running shares its result. Never throws.
  Future<InstallResult> install(
    String token, {
    InstallOptions options = const InstallOptions(),
  }) async {
    final peeked = _held.peek(token);
    if (peeked == null) {
      return const InstallRefused(InstallFailure.tokenExpired);
    }
    if (options.expectId != null && peeked.installId != options.expectId) {
      return const InstallRefused(InstallFailure.wrongPlugin);
    }
    if (options.silentOnly) {
      switch (peeked.review) {
        case UpdateReview(:final diff) when diff.needsReview:
          return InstallNeedsReview(peeked);
        case InstallReview():
          // A silent path only touches a plugin that is installed.
          return const InstallRefused(InstallFailure.pluginGone);
        default:
      }
    }
    final held = _held.take(token);
    if (held == null) return const InstallRefused(InstallFailure.tokenExpired);
    // No shared key: two packages for one plugin run one after the other, and
    // the second is judged against the row the first left.
    return _activity.track(
      held.installId,
      () => _queue.run<InstallResult>(
        () => _install(held, options),
        onError: (error, _) {
          _log.warning('Install failed: ${error.runtimeType}');
          return const InstallRefused(InstallFailure.unexpected);
        },
      ),
    );
  }

  Future<InstallResult> _install(HeldPackage held, InstallOptions o) async {
    if (held.review is ProblemsReview) {
      return InstallRefused(failureOfProblems(held.review as ProblemsReview));
    }
    final row = await _rows.byId(held.installId);
    final live = row != null && row.isLive ? row : null;
    final current = live == null ? null : snapshotOfRow(live);
    final seen = held.snapshot;
    if (seen == null ? current != null : !seen.sameAs(current)) {
      return const InstallRefused(InstallFailure.reviewStale);
    }
    final decision = decideInstall(
      source: held.source,
      package: held.package,
      installed: live == null ? null : _installedOf(live),
      allowRepair: o.allowRepair,
    );
    final mode = decision.mode;
    if (mode == null) return InstallRefused(decision.failure!);
    if (o.silentOnly && (decision.diff?.needsReview ?? false)) {
      // The token is spent; the caller prepares the package again to review.
      return const InstallRefused(InstallFailure.needsReview);
    }
    if (held.package.manifest.kind == PluginKind.streaming &&
        !await _gate.streamingInstallAllowed(held.installId)) {
      return const InstallRefused(InstallFailure.proRequired);
    }
    final result = await _writer.write(
      installId: held.installId,
      package: held.package,
      source: pluginSourceOf(held.source),
      mode: mode,
    );
    if (result is Installed) _activity.clearFor(held.installId);
    return result;
  }

  InstalledPlugin _installedOf(PluginRow row) => InstalledPlugin(
    version: row.version,
    kind: row.pluginKind,
    packageSha256: row.packageSha256,
    source: heldSourceOf(row.source),
    consentedHosts: row.consentedHosts,
  );
}
