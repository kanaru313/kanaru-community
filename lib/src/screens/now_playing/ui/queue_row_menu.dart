import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/state/browse/selection_providers.dart';
import '../../../library/ui/menus/menu_model.dart';
import '../../../library/ui/menus/open_menu.dart';
import '../../../media/domain/track_info.dart';
import '../../../playback/domain/queue_state.dart';
import '../../../playback/state/playback_providers.dart';
import '../../../playback/ui/queue/queue_remove_action.dart';
import '../state/queue_selection.dart';
import 'queue_host.dart';

final _log = Logger('QueueRowMenu');

/// Opens the menu of one queue row: the song menu of that entry (the library's
/// renderer and way of opening) with the queue's own rows around it:
/// [Play this, Play next] first, "Select" acting on the queue selection,
/// [Remove from queue] before "Advanced", no "Play next / Add to queue" footer
/// and none of the Now Playing rows.
///
/// Every queue action checks the entry is still queued (else a toast). A song
/// that is not in the library ([info] null) shows the "not in your library"
/// toast. [beforeNavigate] closes what covers the library before a "Go to"
/// row opens its page. Never throws: failures are logged and toasted by the
/// menu.
void openQueueRowMenu(
  BuildContext context,
  QueueItem item,
  TrackInfo? info, {
  required QueueHost host,
  VoidCallback? beforeNavigate,
  VoidCallback? onEmptied,
  bool viaKeyboard = false,
}) {
  final l10n = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final root = Navigator.of(context, rootNavigator: true).context;
  if (info == null) {
    showAppSnackBar(root, l10n.libraryNotFoundMessage);
    return;
  }
  final controller = container.read(playerControllerProvider);

  // Runs [act] unless the entry left the queue meanwhile.
  Future<void> Function(BuildContext) guarded(Future<void> Function() act) =>
      (_) async {
        if (controller.queueState.indexOfEntry(item.entryId) < 0) {
          if (root.mounted) showAppSnackBar(root, l10n.playbackQueueStale);
          return;
        }
        await act();
      };

  final selected = container.read(isSelectedProvider(item.trackId));
  unawaited(
    openSongMenu(
      context,
      info,
      viaKeyboard: viaKeyboard,
      beforeNavigate: beforeNavigate,
      queueButtons: false,
      leadingGroup: [
        MenuItemSpec(
          MenuItemId.playThis,
          icon: KIcons.play,
          title: l10n.playbackRowPlay,
          action: MenuAction.run(
            guarded(() async => controller.playEntry(item.entryId)),
          ),
        ),
        MenuItemSpec(
          MenuItemId.playNext,
          icon: KIcons.playlistPlay,
          title: l10n.playbackRowPlayNext,
          action: MenuAction.run((_) async {
            try {
              await controller.playNext([item.trackId]);
            } on Object catch (e, st) {
              _log.warning('could not queue next: $e', e, st);
              if (root.mounted) {
                showAppSnackBar(root, l10n.libraryMenuQueueFailed);
              }
              return;
            }
            if (root.mounted) {
              showAppSnackBar(root, l10n.libraryMenuPlayingNext);
            }
          }),
        ),
      ],
      selectReplacement: MenuItemSpec(
        MenuItemId.select,
        icon: selected ? KIcons.deselect : KIcons.select,
        title: selected ? l10n.libraryMenuDeselect : l10n.libraryMenuSelect,
        action: MenuAction.run(
          guarded(
            () async =>
                container.read(queueSelectionProvider.notifier).toggle(item),
          ),
        ),
      ),
      beforeAdvanced: [
        MenuItemSpec(
          MenuItemId.removeFromQueue,
          icon: KIcons.delete,
          title: l10n.playbackRemoveFromQueue,
          danger: true,
          shortcut: host == QueueHost.panel ? 'Delete' : null,
          action: MenuAction.run(
            guarded(
              () async => removeQueueEntries(
                root,
                controller,
                {item.entryId},
                title: info.title,
                onEmptied: onEmptied,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
