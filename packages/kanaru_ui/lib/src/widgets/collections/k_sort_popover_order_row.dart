import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_layout.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';

/// The two direction buttons on top of the sort dropdown. Only drawn while a
/// caller still passes `onAscendingChanged`; the new dropdown has no direction
/// row (direction lives on the bar's reverse button and in the sort dialog).
class SortPopoverOrderRow extends StatelessWidget {
  const SortPopoverOrderRow({
    super.key,
    required this.ascending,
    required this.ascendingLabel,
    required this.descendingLabel,
    required this.onChanged,
  });

  final bool ascending;
  final String ascendingLabel;
  final String descendingLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(KSpace.x2),
      child: Row(
        children: [
          Expanded(
            child: _OrderButton(
              icon: KIcons.sortAsc,
              label: ascendingLabel,
              selected: ascending,
              onTap: () => onChanged(true),
            ),
          ),
          const KGap(KSpace.x1),
          Expanded(
            child: _OrderButton(
              icon: KIcons.sortDesc,
              label: descendingLabel,
              selected: !ascending,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderButton extends StatelessWidget {
  const _OrderButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? scheme.secondaryContainer : const Color(0x00000000),
        shape: KShape.of(KRadius.full),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: KLayout.minTarget),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: KIconSize.xs, color: fg),
                  const KGap(KSpace.x1),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: fg,
                        fontWeight: selected ? FontWeight.w700 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
