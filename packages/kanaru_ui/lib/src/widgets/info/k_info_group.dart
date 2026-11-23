import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import 'k_overlay_page_scope.dart';

/// Heading icon size of the spec (between `KIconSize.xs` and `sm`).
const double _iconSize = 18;

/// A titled card of [KInfoRow]s: heading (icon 18 `primary` + `labelLarge`
/// bold `onSurfaceVariant`, a semantics header), then a 16-corner card with a
/// hairline between rows. The card is `surfaceContainerLow` on a page and
/// `surface` in a box (see [KOverlayPageScope]); `surfaceContainerLow` outside
/// an overlay page.
class KInfoGroup extends StatelessWidget {
  const KInfoGroup({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;

  /// Usually [KInfoRow]s; an empty list draws nothing.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final box = KOverlayPageScope.maybeKindOf(context) == KOverlayKind.box;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x1,
            KSpace.x3,
            KSpace.x1,
            KSpace.x2,
          ),
          child: Semantics(
            header: true,
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(icon, size: _iconSize, color: scheme.primary),
                ),
                const SizedBox(width: KSpace.x2),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Material(
          color: box ? scheme.surface : scheme.surfaceContainerLow,
          shape: KShape.of(KRadius.md),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: KSpace.x4,
                    endIndent: KSpace.x4,
                    color: scheme.outlineVariant,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
