import 'text_clean.dart';

/// Why a plugin package was refused. The domain holds no UI text: the screens
/// map a variant (plus [detail]) to a localized "Lý do" line.
///
/// The first variants are about `plugin.json`; the zip variants (from
/// [NotAZip] on) are about the package file around it.
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

/// The package uses a feature of the format this app cannot handle yet
/// (`seekbar.thumb.lottie`); the detail is the feature name.
final class UnsupportedFeature extends PackageProblem {
  const UnsupportedFeature(super.feature);
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

/// Not a readable zip, or an entry cannot be read as one. The detail is a
/// short English reason for logs (`zip64`, `encrypted: src/a.js`); screens
/// show one generic line.
final class NotAZip extends PackageProblem {
  const NotAZip(super.reason);
}

/// The file, an entry or the unpacked total is over its cap; the detail is
/// the entry to blame, or empty for the file itself or the total.
final class PackageTooLarge extends PackageProblem {
  const PackageTooLarge([super.entry = '']);
}

/// An entry name or kind that must never be unpacked (path traversal,
/// absolute path, symlink, duplicate name); the detail is the entry name.
final class UnsafeEntry extends PackageProblem {
  const UnsafeEntry(super.entry);
}

/// A seek bar package carries `src/*.js`; seek bar plugins are data only.
/// The detail is the first script entry (`src/<name>.js`).
final class CodeNotAllowed extends PackageProblem {
  const CodeNotAllowed(super.entry);
}

/// More zip entries than allowed.
final class TooManyEntries extends PackageProblem {
  const TooManyEntries() : super('');
}

/// No `plugin.json` at the top of the package.
final class MissingManifest extends PackageProblem {
  const MissingManifest() : super('');
}

/// The `script` map names a file that is not in `src/`; the detail is the
/// file name.
final class MissingScript extends PackageProblem {
  const MissingScript(super.file);
}

/// A script is not valid UTF-8; the detail is the file name.
final class ScriptNotUtf8 extends PackageProblem {
  const ScriptNotUtf8(super.file);
}

/// A file the seekbar block names (`thumb.image`, `emitter.image`) is not in
/// `assets/`; the detail is the path the block gives.
final class MissingAsset extends PackageProblem {
  const MissingAsset(super.path);
}

/// An asset a seekbar plugin names cannot be used; the detail is its path and
/// [reason] one of the `ImageProblem` values.
final class InvalidAsset extends PackageProblem {
  const InvalidAsset(super.path, this.reason);

  final String reason;

  @override
  String toString() => 'InvalidAsset($detail, $reason)';
}

/// Thrown inside the parsers to stop at the first problem; the public entry
/// points catch it and return the problem as a value.
final class PackageProblemError implements Exception {
  const PackageProblemError(this.problem);

  final PackageProblem problem;

  @override
  String toString() => 'PackageProblemError($problem)';
}
