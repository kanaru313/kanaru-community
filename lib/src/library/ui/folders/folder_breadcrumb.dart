import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import 'folder_locations.dart';
import 'folder_place.dart';
import 'folder_tile.dart';

/// The levels from the top of the tab down to [place], each with a tap that
/// jumps back to it ([jump]); the last is the open level and has no tap.
///
/// - Several music folders: `All folders › <music folder> › … › <level>`.
/// - One music folder: it starts with where it lives (desktop `~/Music`;
///   mobile `Internal storage › Music`).
/// - A folder opened from the flat list: `All folders › <folder>`.
///
/// A music folder whose name another one shares is told apart by its location.
List<KBreadcrumbSegment> folderSegments(
  AppLocalizations l10n,
  FolderPlace place, {
  required bool mobile,
  required void Function(FolderLocation) jump,
}) {
  KBreadcrumbSegment seg(String label, FolderLocation? to) =>
      KBreadcrumbSegment(
        label: label,
        onTap: to == null ? null : () => jump(to),
      );
  switch (place) {
    case NoFoldersPlace() || FlatListPlace():
      return const [];
    case RootsPlace():
      return [seg(l10n.libraryFoldersAll, null)];
    case FlatOpenPlace(:final root, :final node):
      return [
        seg(l10n.libraryFoldersAll, FolderLocation.flatList),
        seg(node.key.isEmpty ? root.node.name : node.name, null),
      ];
    case LevelPlace(:final root, :final node, :final multiRoot):
      final uid = root.folder.sourceUid;
      FolderLocation at(String key) => FolderLocation(sourceUid: uid, key: key);
      final parts = node.key.isEmpty ? <String>[] : node.key.split('/');
      final segments = <KBreadcrumbSegment>[];
      final atRoot = parts.isEmpty;
      final location = folderLocationLabel(l10n, root.folder, mobile: mobile);
      if (multiRoot) {
        segments.add(seg(l10n.libraryFoldersAll, FolderLocation.top));
        final label = root.ambiguous
            ? (mobile ? '$location · ${root.node.name}' : location)
            : root.node.name;
        segments.add(seg(label, atRoot ? null : at('')));
      } else if (mobile) {
        segments
          ..add(seg(location, atRoot ? null : at('')))
          ..add(seg(root.node.name, atRoot ? null : at('')));
      } else {
        segments.add(seg(location, atRoot ? null : at('')));
      }
      for (var i = 0; i < parts.length; i++) {
        final key = parts.sublist(0, i + 1).join('/');
        final name = root.nodeAt(key)?.name ?? parts[i];
        segments.add(seg(name, i == parts.length - 1 ? null : at(key)));
      }
      return segments;
  }
}

/// [KBreadcrumb] of the Folders bar. The "…" button opens a picker of the
/// hidden levels (a sheet on the mobile shell, a panel under the breadcrumb
/// on desktop), indented by depth, with the open level selected; choosing a
/// level jumps to it.
class FolderBreadcrumb extends StatefulWidget {
  const FolderBreadcrumb({super.key, required this.segments});

  final List<KBreadcrumbSegment> segments;

  @override
  State<FolderBreadcrumb> createState() => _FolderBreadcrumbState();
}

class _FolderBreadcrumbState extends State<FolderBreadcrumb> {
  final GlobalKey _anchor = GlobalKey();

  Future<void> _pick(List<KBreadcrumbSegment> hidden) async {
    final all = widget.segments;
    final l10n = AppLocalizations.of(context);
    final levels = [...hidden, all.last];
    final chosen = await showSelectionPicker<int>(
      context,
      anchor: _anchor,
      title: Text(l10n.libraryGoToFolder),
      selected: levels.length - 1,
      options: [
        for (var i = 0; i < levels.length; i++)
          SelectionOption(
            value: i,
            leading: const Icon(KIcons.folders),
            title: Padding(
              padding: EdgeInsetsDirectional.only(
                start: KSpace.x4 * all.indexOf(levels[i]),
              ),
              child: Text(levels[i].label),
            ),
          ),
      ],
    );
    if (chosen == null || chosen == levels.length - 1 || !mounted) return;
    levels[chosen].onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _anchor,
      child: KBreadcrumb(
        segments: widget.segments,
        hiddenTooltip: AppLocalizations.of(context).libraryFoldersHidden,
        onShowHidden: _pick,
      ),
    );
  }
}
