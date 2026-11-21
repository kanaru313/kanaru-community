import 'dart:async';
import 'dart:typed_data';

import 'package:logging/logging.dart';

import '../../../database/tables.dart';
import '../../../foundation/result.dart';
import '../../../platform/domain/document_picker.dart';
import '../../domain/catalog/catalog.dart';
import '../../domain/install/prepare_result.dart';
import '../../domain/net/address_rules.dart';
import '../../domain/net/cancel_token.dart';
import '../../domain/net/fetch_failure.dart';
import '../../domain/net/net_policy.dart';
import '../../domain/package/package_limits.dart';
import '../net/fetcher.dart';
import '../repos/repo_address_guard.dart';

final _log = Logger('plugin_sources');

/// A picked file is given this long to be read (a cloud provider can hang).
const fileReadTimeout = Duration(seconds: 10);

typedef ProgressCallback = void Function(int received, int? total);

/// The three ways package bytes arrive: from a repository entry, from a file
/// the user picked, from a link the user typed. Each returns the bytes or a
/// typed failure; none writes anything and none throws.
class PackageSources {
  PackageSources({
    required this._fetcher,
    required this._guard,
    required this._picker,
    this._fileTimeout = fileReadTimeout,
  });

  final HttpFetcher _fetcher;
  final RepoAddressGuard _guard;
  final DocumentPicker _picker;
  final Duration _fileTimeout;

  /// The zip of [entry], fetched under the `package` policy with the address
  /// class narrowed against the repository's current address.
  Future<Result<Uint8List, PrepareFailure>> fromRepo(
    PluginRepoRow repo,
    CatalogEntry entry, {
    CancelToken? cancel,
    ProgressCallback? onProgress,
  }) async {
    try {
      final kind = switch (await _guard.kindFor(repo)) {
        Ok(:final value) => value,
        Err(:final error) => throw error,
      };
      return await _download(
        entry.path,
        NetPolicy.package,
        catalogKind: kind,
        expectedSize: entry.size,
        cancel: cancel,
        onProgress: onProgress,
      );
    } on FetchFailure catch (failure) {
      return Err(_failed(failure));
    } on Object catch (error) {
      _log.warning('Repository download failed: ${error.runtimeType}');
      return const Err(PrepareUnexpected());
    }
  }

  /// The zip at the link [url], fetched under the `link` policy (the address
  /// is the user's own choice, so a local one is allowed over `http`).
  Future<Result<Uint8List, PrepareFailure>> fromLink(
    Uri url, {
    CancelToken? cancel,
    ProgressCallback? onProgress,
  }) async {
    try {
      return await _download(
        url,
        NetPolicy.link,
        cancel: cancel,
        onProgress: onProgress,
      );
    } on Object catch (error) {
      _log.warning('Link download failed: ${error.runtimeType}');
      return const Err(PrepareUnexpected());
    }
  }

  /// The bytes of the picked [doc]: a `.zip` of at most 5 MiB, read within
  /// [fileReadTimeout]. A read that finishes after the timeout is dropped
  /// (and its error swallowed), never applied.
  Future<Result<Uint8List, PrepareFailure>> fromFile(PickedDocument doc) async {
    if (!doc.name.toLowerCase().endsWith('.zip')) {
      return const Err(FileUnreadable(DocumentError.notAFile));
    }
    final done = Completer<Result<Uint8List, PrepareFailure>>();
    final timer = Timer(_fileTimeout, () {
      if (!done.isCompleted) done.complete(const Err(FileTimedOut()));
    });
    // The extra byte tells "exactly at the cap" from "over it".
    _picker
        .read(doc, maxBytes: maxPackageBytes + 1)
        .then(
          (read) {
            if (done.isCompleted) return;
            done.complete(switch (read) {
              Ok(:final value) when value.length > maxPackageBytes => const Err(
                FileUnreadable(DocumentError.tooLarge),
              ),
              Ok(:final value) => Ok(value),
              Err(:final error) => Err(FileUnreadable(error)),
            });
          },
          onError: (Object error) {
            _log.warning('File read failed: ${error.runtimeType}');
            if (!done.isCompleted) {
              done.complete(
                const Err(FileUnreadable(DocumentError.unreadable)),
              );
            }
          },
        );
    return done.future.whenComplete(timer.cancel);
  }

  Future<Result<Uint8List, PrepareFailure>> _download(
    Uri url,
    NetPolicy policy, {
    AddressKind? catalogKind,
    int? expectedSize,
    CancelToken? cancel,
    ProgressCallback? onProgress,
  }) async {
    final got = await _fetcher.get(
      url,
      policy,
      catalogKind: catalogKind,
      expectedSize: expectedSize,
      cancel: cancel,
      onProgress: onProgress,
    );
    return switch (got) {
      Ok(:final value) => Ok(value.bytes),
      Err(:final error) => Err(_failed(error)),
    };
  }

  PrepareFailure _failed(FetchFailure failure) =>
      failure.kind == FetchFailureKind.cancelled
      ? const PrepareCancelled()
      : DownloadFailed(failure);
}
