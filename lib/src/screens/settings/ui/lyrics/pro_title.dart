import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// A row title followed by the Pro badge. A [Wrap], not a `Row`: beside the
/// "Sắp có" label at 200 % text the title leaves less room than the badge
/// needs, and a `Row` would overflow.
class ProTitle extends StatelessWidget {
  const ProTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: KSpace.x2,
    children: [Text(title), const ProBadge()],
  );
}
