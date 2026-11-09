import 'package:flutter/material.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../extension/state/registry_entries.dart';

/// Sidebar: 240 dp with labels, 72 dp rail with icons only. Footer items
/// (Settings) are pinned at the bottom.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.expanded,
    required this.onSelect,
  });

  static const double fullWidth = 240;
  static const double railWidth = 72;

  /// Every nav item in nav order; [selectedIndex] and `onSelect` index into it.
  final List<NavItem> items;
  final int selectedIndex;
  final bool expanded;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final main = [
      for (var i = 0; i < items.length; i++)
        if (!items[i].footer) i,
    ];
    final footer = [
      for (var i = 0; i < items.length; i++)
        if (items[i].footer) i,
    ];
    return AnimatedContainer(
      key: const ValueKey('sidebar'),
      duration: KMotion.fast,
      width: expanded ? fullWidth : railWidth,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerLow),
      padding: const EdgeInsets.all(KSpace.x3),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [for (final i in main) _row(context, i)],
            ),
          ),
          for (final i in footer) _row(context, i),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int branch) {
    final item = items[branch];
    return Padding(
      padding: const EdgeInsets.only(bottom: KSpace.x1),
      child: _SidebarRow(
        item: item,
        selected: branch == selectedIndex,
        expanded: expanded,
        onTap: () => onSelect(branch),
      ),
    );
  }
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = item.label(context);
    final color = selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Tooltip(
      message: expanded ? '' : label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          borderRadius: KRadius.full,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: KLayout.minTarget,
              child: Row(
                children: [
                  // Rail: the 48 dp icon cell is centred in the 48 dp content.
                  const SizedBox(width: KSpace.x3),
                  Icon(selected ? item.selectedIcon : item.icon, color: color),
                  if (expanded) ...[
                    const SizedBox(width: KSpace.x3),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
