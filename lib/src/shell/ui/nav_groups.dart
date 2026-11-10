import '../../extension/state/registry_entries.dart';

/// Nav items split for a sidebar: the main list and the footer (Settings).
({List<NavItem> main, List<NavItem> footer}) splitNavItems(
  List<NavItem> items,
) => (
  main: [
    for (final i in items)
      if (!i.footer) i,
  ],
  footer: [
    for (final i in items)
      if (i.footer) i,
  ],
);

/// Whether a divider goes before `main[index]`: neighbouring items whose
/// `order ~/ 100` differs belong to different groups.
bool startsNavGroup(List<NavItem> main, int index) =>
    index > 0 && main[index].order ~/ 100 != main[index - 1].order ~/ 100;

/// Id of the item whose page [location] is in: the longest matching path among
/// the items that navigate. Search and detail pages match nothing.
String? selectedNavId(List<NavItem> items, String location) {
  NavItem? best;
  for (final item in items) {
    if (!item.sidebar || item.comingSoon || item.onSelect != null) continue;
    if (!item.containsLocation(location)) continue;
    if (best == null || item.path.length > best.path.length) best = item;
  }
  return best?.id;
}
