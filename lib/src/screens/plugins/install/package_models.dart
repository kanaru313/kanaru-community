/// Where the install / update screen is in its life.
enum PackagePhase { loading, ready, working, failed }

/// A short note above the package: why the screen looked at it again.
enum PackageNotice { stale, expired }

/// What the file or link the screen was opened for is called, for the
/// problem dialogs.
class PackageSubject {
  const PackageSubject(this.name, {this.isFile = false, this.named = true});

  final String name;
  final bool isFile;

  /// False when [name] is a file name or an address, not a plugin name.
  final bool named;
}
