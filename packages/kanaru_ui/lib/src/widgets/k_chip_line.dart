import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_space.dart';

/// Chips on one line that never wraps: centred while they fit, a sideways
/// scroll when the parent is narrower. Gap 8 on touch shells, 6 on desktop. Chips are [KChip]s (usually `dense`).
class KChipLine extends StatelessWidget {
  const KChipLine({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final gap = FormFactor.of(context) == FormFactor.desktop
        ? KSpace.x1 + 2
        : KSpace.x2;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: box.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
