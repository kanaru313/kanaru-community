import '../problems/install_problem.dart';

/// How the install / update screen ended (what its route pops with).
sealed class PackageExit {
  const PackageExit();
}

/// The plugin was written.
final class PackageInstalled extends PackageExit {
  const PackageInstalled({
    required this.installId,
    required this.name,
    required this.version,
    required this.updated,
  });

  final String installId;
  final String name;
  final int version;

  /// An update of an installed plugin, not a new install.
  final bool updated;
}

/// The package cannot be installed: the flow shows [problem] after the screen
/// has closed.
final class PackageRefused extends PackageExit {
  const PackageRefused(this.problem);

  final InstallProblem problem;
}
