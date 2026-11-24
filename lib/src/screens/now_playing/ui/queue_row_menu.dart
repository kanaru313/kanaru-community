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
import 'queue_row_menu_header.dart';
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
      builder: (sheet) =>
          _SheetMenu(groups: groups, info: info, viaKeyboard: viaKeyboard),
    );
  } else {
    _showPopup(context, at, groups, info: info, viaKeyboard: viaKeyboard);
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
  required TrackInfo? info,
  required bool viaKeyboard,
}) {
  final box = context.findRenderObject()! as RenderBox;
  final point = at ?? box.localToGlobal(box.size.center(Offset.zero));
  final scheme = Theme.of(context).colorScheme;
  final soon = AppLocalizations.of(context).appComingSoon;
  final focused = _firstEnabled(groups, viaKeyboard);
  final items = <PopupMenuEntry<void>>[
    if (info != null) ...[_HeaderEntry(info), const PopupMenuDivider()],
  ];
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
                Icon(e.icon, size: KIconSize.sm, color: color),
                Expanded(
                  child: Text(e.label, style: TextStyle(color: color)),
                ),
                // Trailing texts keep their natural width (the label takes
                // all the rest) but never more than 40 % of the popup, so a
                // large text scale cannot push the row into overflow.
                if (e.soon) _trailing(soon),
                if (e.hint != null) _trailing(e.hint!),
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
    constraints: const BoxConstraints.tightFor(width: _popupWidth),
  );
}

/// A trailing text of a popup item: natural width, capped (see [_showPopup]).
Widget _trailing(String text) => ConstrainedBox(
  constraints: BoxConstraints(maxWidth: _popupWidth * 0.4),
  child: Text(text),
);

/// Width of the desktop popup (the header needs room for its three lines).
const double _popupWidth = 320;

/// The song's row at the top of the popup: not selectable.
class _HeaderEntry extends PopupMenuEntry<void> {
  const _HeaderEntry(this.info);

  final TrackInfo info;

  @override
  double get height => queueRowMenuCoverSide + 2 * KSpace.x2;

  @override
  bool represents(void value) => false;

  @override
  State<_HeaderEntry> createState() => _HeaderEntryState();
}

class _HeaderEntryState extends State<_HeaderEntry> {
  @override
  // A minimum, not a fixed height: three lines at a large text scale grow it.
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: widget.height),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KSpace.x4,
        vertical: KSpace.x2,
      ),
      child: QueueRowMenuHeader(info: widget.info),
    ),
  );
}

class _SheetMenu extends StatelessWidget {
  const _SheetMenu({
    required this.groups,
    required this.info,
    required this.viaKeyboard,
  });

  final List<List<_Entry>> groups;
  final TrackInfo? info;
  final bool viaKeyboard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final soon = AppLocalizations.of(context).appComingSoon;
    final focused = _firstEnabled(groups, viaKeyboard);
    return ListView(
      shrinkWrap: true,
      // Rows follow the host (full-bleed in the sheet): no side padding here.
      padding: const EdgeInsets.symmetric(vertical: KSpace.x4),
      children: [
        if (info != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x4,
              0,
              KSpace.x4,
              KSpace.x3,
            ),
            child: QueueRowMenuHeader(info: info!),
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
