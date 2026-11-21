import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../../../foundation/result.dart';
import '../../../platform/domain/document_picker.dart';
import '../../domain/install/held_package.dart';
import '../../domain/install/prepare_result.dart';
import '../../domain/install/script_checker.dart';
import '../../domain/net/cancel_token.dart';
import '../../domain/net/fetch_failure.dart';
import '../../domain/package/package_problem.dart';
import '../../domain/package/package_reader.dart';
import '../../domain/package/plugin_package.dart';
import '../repos/catalog_cache.dart';
import '../store/plugin_repo_rows.dart';
import '../store/plugin_rows.dart';
import 'held_package_builder.dart';
import 'held_package_checks.dart' show scriptCheckTimeout;
import 'held_token_store.dart';
import 'package_sources.dart';

final _log = Logger('plugin_held');

/// Reads a zip off the UI isolate (up to 5 MiB of inflating).
Future<Result<PluginPackage, PackageProblem>> readPackageInIsolate(
  Uint8List bytes,
) => Isolate.run(() => readPackage(bytes));

typedef _Emit = void Function(PrepareProgress progress);

/// Gets a package from a repository, a file or a link, checks it completely
/// and holds it in memory under a token until the user installs or discards
/// it. Nothing is written to the database or the disk here; installing
/// (`take(token)`, then the install job of the write queue) is separate.
///
/// Checks, in order: download or read, `readPackage` (in an isolate), the
/// syntax of every script, and for a repository entry the match with the
/// catalog (`catalogMatches`, which also compares `sha256` and `size` when
/// the catalog gives them). A package that reads but cannot be installed is
/// still returned, with a `ProblemsReview`. Every error is a typed failure.
class HeldPackages {
  HeldPackages({
    required this._sources,
    required ScriptChecker checker,
    required PluginRows rows,
    required this._repoRows,
    required this._catalogs,
    this.refreshRepo,
    HeldTokenStore? tokens,
    Future<Result<PluginPackage, PackageProblem>> Function(Uint8List)? reader,
    Duration scriptTimeout = scriptCheckTimeout,
  }) : _tokens = tokens ?? HeldTokenStore() {
    _builder = HeldPackageBuilder(
      checker: checker,
      rows: rows,
      tokens: _tokens,
      reader: reader ?? readPackageInIsolate,
      scriptTimeout: scriptTimeout,
    );
  }

  final PackageSources _sources;
  final PluginRepoRows _repoRows;
  final CatalogCache _catalogs;
  final HeldTokenStore _tokens;
  late final HeldPackageBuilder _builder;

  /// Refreshes one repository's catalog (for [refreshAndRetry]).
  final Future<Object?> Function(int repoId)? refreshRepo;

  /// The held package under [token], released: null when it is unknown,
  /// expired (10 minutes) or evicted (at most two are held).
  HeldPackage? take(String token) => _tokens.take(token);

  HeldPackage? peek(String token) => _tokens.peek(token);

  /// Drops the package under [token]; the screen calls it when it closes.
  void discard(String token) => _tokens.discard(token);

  PrepareOperation prepareFromRepo(int repoId, String slug) =>
      _operation((cancel, emit) => _fromRepo(repoId, slug, cancel, emit));

  PrepareOperation prepareFromFile(PickedDocument doc) => _operation((
    cancel,
    emit,
  ) async {
    final bytes = await _sources.fromFile(doc);
    return _builder.build(bytes, FileHeldSource(doc.name), null, cancel, emit);
  });

  PrepareOperation prepareFromLink(String link) =>
      _operation((cancel, emit) async {
        final url = Uri.tryParse(link.trim());
        if (url == null) {
          return const Err(
            DownloadFailed(FetchFailure(FetchFailureKind.invalidUrl)),
          );
        }
        final bytes = await _sources.fromLink(
          url,
          cancel: cancel,
          onProgress: _downloading(emit),
        );
        return _builder.build(
          bytes,
          LinkHeldSource(url.toString()),
          null,
          cancel,
          emit,
        );
      });

  /// After a "package does not match the list" result: refreshes the
  /// repository's catalog, then prepares the entry again from the fresh
  /// version of it. [held] must come from a repository.
  PrepareOperation refreshAndRetry(HeldPackage held) {
    final source = held.source;
    if (source is! RepoHeldSource) {
      return _operation((_, _) async => const Err(EntryGone()));
    }
    return _operation((cancel, emit) async {
      final repoId = source.repoId;
      if (repoId == null) return const Err(EntryGone());
      _tokens.discard(held.token);
      try {
        await refreshRepo?.call(repoId);
      } on Object catch (error) {
        _log.warning('Refresh before retry failed: ${error.runtimeType}');
      }
      return _fromRepo(repoId, source.slug, cancel, emit);
    });
  }

  PrepareOperation _operation(
    Future<Result<HeldPackage, PrepareFailure>> Function(
      CancelToken cancel,
      _Emit emit,
    )
    body,
  ) {
    final cancel = CancelToken();
    final progress = StreamController<PrepareProgress>.broadcast();
    void emit(PrepareProgress p) {
      if (!progress.isClosed) progress.add(p);
    }

    final result = () async {
      try {
        return await body(cancel, emit);
      } on Object catch (error) {
        _log.warning('Preparing a package failed: ${error.runtimeType}');
        return const Err<HeldPackage, PrepareFailure>(PrepareUnexpected());
      }
    }().whenComplete(progress.close);
    return PrepareOperation(cancel, progress.stream, result);
  }

  ProgressCallback _downloading(_Emit emit) =>
      (received, total) => emit(
        PrepareProgress(PrepareStage.downloading, done: received, total: total),
      );

  Future<Result<HeldPackage, PrepareFailure>> _fromRepo(
    int repoId,
    String slug,
    CancelToken cancel,
    _Emit emit,
  ) async {
    final repo = await _repoRows.byId(repoId);
    if (repo == null) return const Err(EntryGone());
    final entry = _catalogs.entryOf(repo, slug);
    if (entry == null) return const Err(EntryGone());
    if (entry.needsNewerApp) return const Err(EntryNeedsNewerApp());
    final bytes = await _sources.fromRepo(
      repo,
      entry,
      cancel: cancel,
      onProgress: _downloading(emit),
    );
    return _builder.build(
      bytes,
      RepoHeldSource(repoId: repo.id, repoUrl: repo.url, slug: slug),
      entry,
      cancel,
      emit,
    );
  }
}
