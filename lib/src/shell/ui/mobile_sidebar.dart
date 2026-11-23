import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/registry_entries.dart';
import 'nav_groups.dart';

/// Contents of the mobile push sidebar: logo and name, the nav list with group
/// dividers, Settings pinned at the foot. 256 dp wide.
class MobileSidebar extends StatelessWidget {
  const MobileSidebar({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  static const double width = 256;

  /// Items to list, in nav order (callers drop those with `sidebar == false`).
  final List<NavItem> items;
  final String? selectedId;
  final ValueChanged<NavItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = splitNavItems(items);
    return SizedBox(
      width: width,
      child: ColoredBox(
        color: scheme.surfaceContainerLow,
        child: SafeArea(
          right: false,
          child: Padding(
            padding: const EdgeInsets.all(KSpace.x3),
            child: Column(
              children: [
                const _Head(),
                Expanded(
                  child: ListView(
                    children: [
                      for (var i = 0; i < parts.main.length; i++) ...[
                        if (startsNavGroup(parts.main, i))
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: KSpace.x1,
                              horizontal: KSpace.x3,
                            ),
                            child: Divider(height: 1),
                          ),
                        _Row(
                          item: parts.main[i],
                          selected: parts.main[i].id == selectedId,
                          onSelect: onSelect,
                        ),
                      ],
                    ],
                  ),
                ),
                for (final item in parts.footer)
                  _Row(
                    item: item,
                    selected: item.id == selectedId,
                    onSelect: onSelect,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: KLayout.minTarget + KSpace.x4,
      child: Row(
        spacing: KSpace.x3,
        children: [
          const SizedBox(width: KSpace.x3),
          const KanaruLogo(size: KIconSize.lg),
          Text('Kanaru', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.item,
    required this.selected,
    required this.onSelect,
  });

  final NavItem item;
  final bool selected;
  final ValueChanged<NavItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final label = item.label(context);
    final soon = AppLocalizations.of(context).appComingSoon;
    final enabled = !item.comingSoon;
    return Padding(
      padding: const EdgeInsets.only(bottom: KSpace.x1),
      child: KNavRow(
        icon: item.icon,
        selectedIcon: item.selectedIcon,
        label: label,
        semanticLabel: enabled ? null : '$label, $soon',
        selected: selected,
        leadingInset: KSpace.x4,
        onTap: enabled ? () => onSelect(item) : null,
        trailing: enabled
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: KSpace.x3),
                child: Text(
                  soon,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.38),
                  ),
                ),
              ),
      ),
    );
  }
}
