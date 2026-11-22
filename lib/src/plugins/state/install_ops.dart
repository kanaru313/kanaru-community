import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../foundation/result.dart';
import '../../platform/domain/document_picker.dart';
import '../data/install/held_packages.dart';
import '../data/install/plugin_actions.dart';
import '../data/install/plugin_activity.dart';
import '../data/install/remover.dart';
import '../domain/install/held_package.dart';
import '../domain/install/install_result.dart';
import '../domain/install/prepare_result.dart';
import '../domain/net/cancel_token.dart';
import '../domain/package/plugin_kind.dart';
import 'plugin_actions_provider.dart';
import 'plugin_services_provider.dart';
import 'plugin_store_providers.dart';
import 'store_items_provider.dart';
import 'updates_provider.dart';

// The screens read these data-layer result types through this file, so they
// never import `plugins/data` themselves.
export '../data/install/plugin_activity.dart'
    show UpdateAllState, UpdateOutcome;
export '../data/install/remover.dart' show RemoveResult;

/// What the remove dialog says about a plugin.
class RemovePreview {
  const RemovePreview({
    required this.installId,
    required this.name,
    required this.author,
    required this.version,
    required this.kind,
  });

  final String installId;
  final String name;

  /// Empty when the plugin names no author.
  final String author;
  final int version;

  /// Null for a kind this app does not know.
  final PluginKind? kind;
}

/// How an in-place update ended; [version] is the new version after a write.
class UpdateRun {
  const UpdateRun(this.result, {this.version});

  final InstallResult result;
  final int? version;
}

/// What the install, update and remove screens do to packages and plugins.
/// Screens read this interface only; tests replace it. No method throws.
abstract interface class InstallOps {
  /// Prepares the repository entry that is not installed yet (id of the row).
  PrepareOperation prepareInstall(String installId);

  /// Prepares the newer version of an installed repository plugin.
  PrepareOperation prepareUpdate(String installId);
  PrepareOperation prepareFile(PickedDocument doc);
  PrepareOperation prepareLink(String link);

  /// Refreshes the repository of a package that did not match its catalog
  /// entry, then prepares the entry again.
  PrepareOperation prepareAfterRefresh(HeldPackage held);

  /// Drops the held package under [token] (every exit of the screen).
  void discard(String token);

  /// Whether the Free one-music-source rule stops [held] from being written.
  Future<bool> streamingBlocked(HeldPackage held);

  /// Writes the package held under [token].
  Future<InstallResult> install(String token);

  /// Updates [installId] in place; a package that adds hosts is not written.
  Future<UpdateRun> update(String installId);

  /// Updates every plugin without new hosts, one after the other.
  Future<UpdateAllState> updateAll();

  /// Read fresh when the remove dialog opens; null when not installed.
  Future<RemovePreview?> removePreview(String installId);
  Future<RemoveResult> remove(String installId);
}

class _ServiceInstallOps implements InstallOps {
  _ServiceInstallOps(this._ref);

  final Ref _ref;

  PluginActions get _actions => _ref.read(pluginActionsProvider);
  HeldPackages get _held => _ref.read(pluginServicesProvider).held;

  @override
  PrepareOperation prepareInstall(String installId) {
    final items = _ref.read(storeItemsProvider).value ?? const <StoreItem>[];
    final item = items.where((i) => i.installId == installId).firstOrNull;
    if (item == null) return _failed(const EntryGone());
    return _held.prepareFromRepo(item.repo.id, item.entry.slug);
  }

  @override
  PrepareOperation prepareUpdate(String installId) {
    final updates = _ref.read(updatesProvider).value;
    final all = [...?updates?.silent, ...?updates?.needsReview];
    final found = all.where((u) => u.row.installId == installId).firstOrNull;
    if (found == null) return _failed(const EntryGone());
    return _held.prepareFromRepo(found.repo.id, found.entry.slug);
  }

  @override
  PrepareOperation prepareFile(PickedDocument doc) =>
      _held.prepareFromFile(doc);

  @override
  PrepareOperation prepareLink(String link) => _held.prepareFromLink(link);

  @override
  PrepareOperation prepareAfterRefresh(HeldPackage held) =>
      _held.refreshAndRetry(held);

  @override
  void discard(String token) => _held.discard(token);

  @override
  Future<bool> streamingBlocked(HeldPackage held) async {
    if (held.package.manifest.kind != PluginKind.streaming) return false;
    if (held.review is! InstallReview) return false;
    return !await _actions.gate.streamingInstallAllowed(held.installId);
  }

  @override
  Future<InstallResult> install(String token) =>
      _actions.installer.install(token);

  @override
  Future<UpdateRun> update(String installId) async {
    final result = await _actions.updater.update(
      installId,
      keepForReview: false,
    );
    if (result is! Installed) return UpdateRun(result);
    final row = await _ref.read(pluginRowsProvider).liveById(installId);
    return UpdateRun(result, version: row?.version);
  }

  @override
  Future<UpdateAllState> updateAll() => _actions.updateAll.run();

  @override
  Future<RemovePreview?> removePreview(String installId) async {
    final summary = await _actions.remover.removeSummary(installId);
    if (summary == null) return null;
    final row = await _ref.read(pluginRowsProvider).liveById(installId);
    if (row == null) return null;
    return RemovePreview(
      installId: installId,
      name: row.name,
      author: row.author ?? '',
      version: row.version,
      kind: summary.kind,
    );
  }

  @override
  Future<RemoveResult> remove(String installId) =>
      _actions.remover.remove(installId);

  PrepareOperation _failed(PrepareFailure failure) => PrepareOperation(
    CancelToken(),
    const Stream.empty(),
    Future.value(Err(failure)),
  );
}

final installOpsProvider = Provider<InstallOps>(_ServiceInstallOps.new);
