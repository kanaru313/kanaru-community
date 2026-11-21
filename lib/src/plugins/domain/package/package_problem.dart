import 'text_clean.dart';

/// Why a plugin package was refused. The domain holds no UI text: the screens
/// map a variant (plus [detail]) to a localized "Lý do" line.
///
/// Every variant here is about `plugin.json`; the zip and catalog problems
/// join this hierarchy where they are read.
sealed class PackageProblem {
  const PackageProblem(this._raw);

  final String _raw;

  /// Manifest field, host or type that is to blame. It can echo attacker
  /// text, so control characters are replaced and it is cut to 200 code
  /// points.
  String get detail => limitText(_raw, 200);

  @override
  String toString() => '$runtimeType($detail)';
}

/// `plugin.json` is unreadable or breaks a rule; the detail is the dotted
/// field path (`metadata.name`, `config.key.default`).
final class InvalidManifest extends PackageProblem {
  const InvalidManifest(super.field);
}

/// A config field uses a `format` the app does not know (`secret` included,
/// the app stores no secrets); the detail is `config.<key>.format`.
final class UnknownConfigFormat extends PackageProblem {
  const UnknownConfigFormat(super.path);
}

/// `metadata.apiVersion` is newer than this app understands.
final class NeedsNewerApp extends PackageProblem {
  const NeedsNewerApp(super.apiVersion);
}

/// `metadata.type` is not one this app runs; the detail is the type when it
/// is a string, else empty.
final class UnsupportedKind extends PackageProblem {
  const UnsupportedKind(super.type);
}

/// A host that is not a public DNS name; the detail is the host.
final class InvalidHost extends PackageProblem {
  const InvalidHost(super.host);
}

/// A `*` that is not one leading `*.` label over a public name.
final class InvalidWildcardHost extends PackageProblem {
  const InvalidWildcardHost(super.host);
}

/// A wildcard host in a plugin that is not a streaming plugin.
final class WildcardHostNotAllowed extends PackageProblem {
  const WildcardHostNotAllowed(super.host);
}

/// A wildcard over a shared-hosting suffix (anyone can register a name
/// under it).
final class SharedHostingWildcard extends PackageProblem {
  const SharedHostingWildcard(super.host);
}

/// More wildcard hosts than allowed; the detail is the first one over.
final class TooManyWildcardHosts extends PackageProblem {
  const TooManyWildcardHosts(super.host);
}

/// Thrown inside the parsers to stop at the first problem; the public entry
/// points catch it and return the problem as a value.
final class PackageProblemError implements Exception {
  const PackageProblemError(this.problem);

  final PackageProblem problem;

  @override
  String toString() => 'PackageProblemError($problem)';
}
