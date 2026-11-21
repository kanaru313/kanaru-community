import 'dart:async';

import '../../../database/tables.dart';
import '../../../foundation/result.dart';
import '../../domain/net/address_rules.dart';
import '../../domain/net/fetch_failure.dart';
import '../net/pinned_http.dart';
import '../store/plugin_repo_rows.dart';

/// How long a good answer is reused (a burst of icons of one repository
/// looks the address up once).
const addressMemoTtl = Duration(seconds: 60);
const addressLookupTimeout = Duration(seconds: 10);

/// Decides which address class a package or icon fetch of a stored
/// repository must obey: the stricter of the class stored when its catalog
/// was fetched and a fresh look at the repository's own address. A repository
/// that was local and now resolves public is held to the public rules, so a
/// DNS change cannot turn an old local catalog into a way into the local
/// network. A refused or unresolvable address refuses the fetch (fails
/// closed); it never falls back to the stored class.
class RepoAddressGuard {
  RepoAddressGuard({
    this._resolver = systemHostResolver,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final HostResolver _resolver;
  final DateTime Function() _clock;
  final _memo = <String, _Memo>{};

  Future<Result<AddressKind, FetchFailure>> kindFor(PluginRepoRow repo) {
    final key = '${repo.addressKind.name}\n${repo.url}';
    final known = _memo[key];
    if (known != null && _clock().difference(known.at) < addressMemoTtl) {
      return known.result;
    }
    final result = _lookup(repo);
    _memo[key] = _Memo(result, _clock());
    // A failure is not reused: the network may be back for the next ask.
    result.then<void>((r) {
      if (r is Err) _memo.remove(key);
    });
    return result;
  }

  /// Forgets what was looked up (after a refresh of all repositories).
  void clear() => _memo.clear();

  Future<Result<AddressKind, FetchFailure>> _lookup(PluginRepoRow repo) async {
    final url = Uri.tryParse(repo.url);
    if (url == null) {
      return const Err(FetchFailure(FetchFailureKind.invalidUrl));
    }
    var verdict = judgeAddress(url);
    if (verdict.isAllowed && verdict.kind == null) {
      try {
        final found = await _resolver(url.host).timeout(addressLookupTimeout);
        verdict = judgeAddress(
          url,
          addresses: [for (final a in found) a.rawAddress],
        );
      } on Object {
        return const Err(FetchFailure(FetchFailureKind.network));
      }
    }
    final kind = effectiveAddressKind(repo.addressKind, verdict);
    if (kind != null) return Ok(kind);
    final problem = verdict.problem;
    return Err(
      problem == null
          ? const FetchFailure(FetchFailureKind.network)
          : FetchFailure.blocked(problem),
    );
  }
}

class _Memo {
  const _Memo(this.result, this.at);

  final Future<Result<AddressKind, FetchFailure>> result;
  final DateTime at;
}
