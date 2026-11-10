/// Error kind names of a failed native call (`NativeErrorKind.name`).
abstract final class NativeKinds {
  static const notFound = 'notFound';
  static const timeout = 'timeout';
}

/// A failed native read, as far as the scanner needs it.
class NativeFailure {
  const NativeFailure({required this.kind, required this.transient});

  /// `NativeErrorKind.name`: `io`, `notFound`, `permissionDenied`,
  /// `unsupported`, `corrupt`, `tooLarge`, `cancelled`, `timeout`, `panic`.
  /// Stored in `tracks.scan_error`.
  final String kind;

  /// A later attempt may succeed; the pass version is then left alone.
  final bool transient;

  bool get isNotFound => kind == NativeKinds.notFound;

  @override
  String toString() => 'NativeFailure($kind${transient ? ', transient' : ''})';
}
