import '../../../plugins/domain/install/held_package.dart';
import '../../../plugins/domain/install/update_diff.dart';
import '../../../plugins/domain/package/package_problem.dart';

/// One reason line of the "Lý do" box. The text is chosen by the screen.
sealed class ProblemReason {
  const ProblemReason();
}

final class PackageReason extends ProblemReason {
  const PackageReason(this.problem);
  final PackageProblem problem;
}

final class ScriptReason extends ProblemReason {
  const ScriptReason(this.error);
  final ScriptSyntaxError error;
}

final class MismatchReason extends ProblemReason {
  const MismatchReason(this.field);
  final CatalogMismatch field;
}

final class SameVersionReason extends ProblemReason {
  const SameVersionReason();
}

final class OlderVersionReason extends ProblemReason {
  const OlderVersionReason();
}

final class KindChangeReason extends ProblemReason {
  const KindChangeReason();
}

/// The plugin is installed from [existing] and a package of another origin
/// cannot replace it.
final class OtherOriginReason extends ProblemReason {
  const OtherOriginReason(this.existing);
  final HeldSource? existing;
}

final class CheckUnavailableReason extends ProblemReason {
  const CheckUnavailableReason();
}

/// A refusal the install step reported without saying which rule.
final class UnknownReason extends ProblemReason {
  const UnknownReason();
}
