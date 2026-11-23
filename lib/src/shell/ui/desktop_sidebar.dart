import 'package:material_ui/material_ui.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/registry_entries.dart';
import 'nav_groups.dart';

/// Sidebar: 240 dp with labels, 72 dp rail with icons only. Footer items
/// (Settings) are pinned at the bottom. A divider separates neighbouring items
/// whose `order ~/ 100` differs (the order bands in ARCHITECTURE.md).
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.items,
    required this.selectedId,
    required this.expanded,
    required this.onSelect,
  });

  static const double fullWidth = 240;
  static const double railWidth = 72;

  /// Items to list, in nav order (callers drop those with `sidebar == false`).
  final List<NavItem> items;

  /// Id of the item marked selected; null marks none.
  final String? selectedId;
  final bool expanded;
  final ValueChanged<NavItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final (:main, :footer) = splitNavItems(items);
    return AnimatedContainer(
      key: const ValueKey('sidebar'),
      duration: KMotion.fast,
      width: expanded ? fullWidth : railWidth,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      padding: const EdgeInsets.all(KSpace.x3),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                for (var i = 0; i < main.length; i++) ...[
                  if (startsNavGroup(main, i)) const _BandDivider(),
                  _row(context, main[i]),
                ],
              ],
            ),
          ),
          for (final item in footer) _row(context, item),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, NavItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: KSpace.x1),
      child: _SidebarRow(
        item: item,
        selected: item.id == selectedId,
        expanded: expanded,
        onTap: item.comingSoon ? null : () => onSelect(item),
      ),
    );
  }
}

class _BandDivider extends StatelessWidget {
  const _BandDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: KSpace.x1, horizontal: KSpace.x3),
    child: Divider(height: 1),
  );
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

  /// Null for a coming-soon item: shown dimmed, does nothing.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = item.label(context);
    final soon = AppLocalizations.of(context).appComingSoon;
    final tooltip = item.comingSoon
        ? (expanded ? soon : '$label · $soon')
        : (expanded ? '' : label);
    return Tooltip(
      message: tooltip,
      child: KNavRow(
        icon: item.icon,
        selectedIcon: item.selectedIcon,
        label: label,
        semanticLabel: item.comingSoon ? '$label, $soon' : null,
        selected: selected,
        expanded: expanded,
        onTap: onTap,
      ),
    );
  }
}
