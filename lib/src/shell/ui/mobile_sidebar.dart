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
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: KLayout.minTarget + KSpace.x4,
      child: Row(
        spacing: KSpace.x3,
        children: [
          const SizedBox(width: KSpace.x3),
          Icon(KIcons.appLogo, color: scheme.primary),
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
    final scheme = Theme.of(context).colorScheme;
    final label = item.label(context);
    final soon = AppLocalizations.of(context).appComingSoon;
    final enabled = !item.comingSoon;
    final color = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : selected
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: KSpace.x1),
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        label: enabled ? label : '$label, $soon',
        child: ExcludeSemantics(
          child: Material(
            color: selected ? scheme.secondaryContainer : Colors.transparent,
            borderRadius: KRadius.sm,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? () => onSelect(item) : null,
              child: SizedBox(
                height: KLayout.minTarget,
                child: Row(
                  spacing: KSpace.x3,
                  children: [
                    const SizedBox(width: KSpace.x1),
                    Icon(
                      selected ? item.selectedIcon : item.icon,
                      color: color,
                    ),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge
                            ?.copyWith(color: color),
                      ),
                    ),
                    if (!enabled)
                      Padding(
                        padding: const EdgeInsets.only(right: KSpace.x3),
                        child: Text(
                          soon,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: color),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
