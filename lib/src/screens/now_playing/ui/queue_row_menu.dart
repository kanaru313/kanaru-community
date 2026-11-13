import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/state/browse/selection_providers.dart';
import '../../../media/domain/track_info.dart';
import '../../../playback/domain/queue_state.dart';
import '../../../playback/state/playback_providers.dart';
import '../../../playback/ui/queue/queue_remove_action.dart';
import '../state/queue_selection.dart';
import 'queue_host.dart';
import 'track_navigation.dart';

final _log = Logger('QueueRowMenu');

/// One entry of the row menu.
class _Entry {
  const _Entry(
    this.label,
    this.icon, {
    this.onTap,
    this.soon = false,
    this.danger = false,
    this.hint,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  /// Not built yet: dimmed with "Soon".
  final bool soon;
  final bool danger;
  final String? hint;

  bool get enabled => onTap != null && !soon;
}

/// Opens the menu of one queue row: a popup at the pointer on the desktop tab,
/// a bottom sheet on the mobile sheet. Matches `QueueRowMenu`.
///
/// Entries: play this, play next (a copy) | go to album, go to artist, select
/// / deselect, ask AI (soon) | remove. Every action checks the entry is still queued.
void openQueueRowMenu(
  BuildContext context,
  QueueItem item,
  TrackInfo? info,
  Offset? at, {
  required QueueHost host,
  VoidCallback? beforeNavigate,
  VoidCallback? onEmptied,
  bool viaKeyboard = false,
}) {
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context);
  final controller = container.read(playerControllerProvider);
  final root = Navigator.of(context, rootNavigator: true).context;

  // Runs [act] unless the entry left the queue meanwhile.
  VoidCallback guarded(void Function() act) => () {
    if (controller.queueState.indexOfEntry(item.entryId) < 0) {
      if (root.mounted) showAppSnackBar(root, l10n.playbackQueueStale);
      return;
    }
    act();
  };

  final selected = container.read(isSelectedProvider(item.trackId));
  final groups = <List<_Entry>>[
    [
      _Entry(
        l10n.playbackRowPlay,
        KIcons.play,
        onTap: guarded(() => controller.playEntry(item.entryId)),
      ),
      _Entry(
        l10n.playbackRowPlayNext,
        KIcons.playlistPlay,
        onTap: () async {
          try {
            await controller.playNext([item.trackId]);
          } on Object catch (e, st) {
            _log.warning('could not queue next: $e', e, st);
            if (root.mounted) {
              showAppSnackBar(root, l10n.libraryMenuQueueFailed);
            }
            return;
          }
          if (root.mounted) showAppSnackBar(root, l10n.libraryMenuPlayingNext);
        },
      ),
    ],
    [
      _Entry(
        l10n.playbackGoAlbum,
        KIcons.album,
        onTap: canGoToAlbum(info)
            ? () => goToAlbum(context, info!, beforeNavigate: beforeNavigate)
            : null,
      ),
      _Entry(
        l10n.playbackGoArtist,
        KIcons.artists,
        onTap: canGoToArtist(info)
            ? () => goToArtist(context, info!, beforeNavigate: beforeNavigate)
            : null,
      ),
      _Entry(
        selected ? l10n.libraryMenuDeselect : l10n.libraryMenuSelect,
        selected ? KIcons.deselect : KIcons.select,
        onTap: () =>
            container.read(queueSelectionProvider.notifier).toggle(item),
      ),
      _Entry(l10n.playbackAskAi, KIcons.ai, soon: true),
    ],
    [
      _Entry(
        l10n.playbackRemoveFromQueue,
        KIcons.delete,
        danger: true,
        hint: host == QueueHost.panel ? 'Delete' : null,
        onTap: guarded(
          () => removeQueueEntries(
            root,
            controller,
            {item.entryId},
            title: info?.title,
            onEmptied: onEmptied,
          ),
        ),
      ),
    ],
  ];
  if (host == QueueHost.sheet) {
    showKSheet<void>(
      context,
      useRootNavigator: true,
      builder: (sheet) => _SheetMenu(
        groups: groups,
        title: info?.title,
        viaKeyboard: viaKeyboard,
      ),
    );
  } else {
    _showPopup(context, at, groups, viaKeyboard: viaKeyboard);
  }
}

/// The entry a keyboard-opened menu focuses: the first enabled one (a
/// pointer-opened menu shows no ring until an arrow key is pressed).
_Entry? _firstEnabled(List<List<_Entry>> groups, bool viaKeyboard) {
  if (!viaKeyboard) return null;
  for (final g in groups) {
    for (final e in g) {
      if (e.enabled) return e;
    }
  }
  return null;
}

/// Wraps a popup item's content so it autofocuses (see [_firstEnabled]).
Widget _autofocus(bool on, Widget child) =>
    on ? Focus(autofocus: true, skipTraversal: true, child: child) : child;

void _showPopup(
  BuildContext context,
  Offset? at,
  List<List<_Entry>> groups, {
  required bool viaKeyboard,
}) {
  final box = context.findRenderObject()! as RenderBox;
  final point = at ?? box.localToGlobal(box.size.center(Offset.zero));
  final scheme = Theme.of(context).colorScheme;
  final soon = AppLocalizations.of(context).appComingSoon;
  final focused = _firstEnabled(groups, viaKeyboard);
  final items = <PopupMenuEntry<void>>[];
  for (var g = 0; g < groups.length; g++) {
    if (g > 0) items.add(const PopupMenuDivider());
    for (final e in groups[g]) {
      final color = e.danger ? scheme.error : null;
      items.add(
        PopupMenuItem<void>(
          // Flutter pops the menu first and then calls this, so a route or
          // picker pushed from here lands on the page, not on the menu.
          onTap: e.onTap,
          enabled: e.enabled,
          // The Focus sits inside the item's InkWell, so Enter still reaches
          // the item's activate action from it.
          child: _autofocus(
            identical(e, focused),
            Row(
              spacing: KSpace.x3,
              children: [
                Icon(e.icon, size: 20, color: color),
                Expanded(
                  child: Text(e.label, style: TextStyle(color: color)),
                ),
                if (e.soon) Text(soon),
                if (e.hint != null) Text(e.hint!),
              ],
            ),
          ),
        ),
      );
    }
  }
  final overlay =
      Overlay.of(context, rootOverlay: true).context.findRenderObject()!
          as RenderBox;
  showMenu<void>(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(point.dx, point.dy, 1, 1),
      Offset.zero & overlay.size,
    ),
    items: items,
  );
}

class _SheetMenu extends StatelessWidget {
  const _SheetMenu({
    required this.groups,
    required this.title,
    required this.viaKeyboard,
  });

  final List<List<_Entry>> groups;
  final String? title;
  final bool viaKeyboard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final soon = AppLocalizations.of(context).appComingSoon;
    final focused = _firstEnabled(groups, viaKeyboard);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(KSpace.x4),
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: KSpace.x3),
            child: Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        for (final g in groups)
          for (final e in g)
            Padding(
              padding: const EdgeInsets.only(bottom: KSpace.x1),
              child: KListRow(
                // The row's own InkWell takes the focus, so Enter activates.
                autofocus: identical(e, focused),
                enabled: e.enabled,
                leading: Icon(e.icon, color: e.danger ? scheme.error : null),
                title: Text(
                  e.label,
                  style: TextStyle(color: e.danger ? scheme.error : null),
                ),
                trailing: e.soon ? Text(soon) : null,
                onTap: e.enabled
                    ? () {
                        Navigator.of(context).pop();
                        e.onTap!();
                      }
                    : null,
              ),
            ),
      ],
    );
  }
}
