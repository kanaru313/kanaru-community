import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/playlists/playlist_models.dart';
import '../../../state/playlists/playlist_page_controller.dart';
import 'playlist_shown_entries.dart';

final _log = Logger('library.playlists');

/// Where a move puts an entry: behind the entry [after] (null: to the top).
typedef EntryPlace = ({String? after});

/// The place for [draggedUid] when it is dropped at [newIndex].
///
/// Every index is a row index of [shown] as drawn, missing rows included (the
/// same space as the drag handles'). [newIndex] is the dragged row's final
/// index, as the reorderable list reports it: no further adjustment. The
/// entry goes behind the row above its landing place, found in [shown]
/// without it. Null: nothing to write (same place, entry not in [shown],
/// index out of range).
EntryPlace? afterEntryFor(
  List<PlaylistEntryView> shown,
  String draggedUid,
  int newIndex,
) {
  final from = shown.indexWhere((e) => e.uid == draggedUid);
  if (from < 0 || newIndex == from) return null;
  final rest = [...shown]..removeAt(from);
  if (newIndex < 0 || newIndex > rest.length) return null;
  return (after: newIndex == 0 ? null : rest[newIndex - 1].uid);
}

/// The place for [entryUid] moved one row up ([delta] -1) or down (+1) in
/// [shown]; null at the first / last row or when the entry is not there.
EntryPlace? afterEntryForStep(
  List<PlaylistEntryView> shown,
  String entryUid,
  int delta,
) {
  final from = shown.indexWhere((e) => e.uid == entryUid);
  if (from < 0) return null;
  return afterEntryFor(shown, entryUid, from + delta);
}

/// The rows as they were when a drag began, held while it lasts.
///
/// The list keeps row indexes in the drag; a saved emission that reordered
/// the rows underneath would drop the row at the wrong place. The page draws
/// [frozen] meanwhile and takes the latest data back on [release].
///
/// A drop that moves a row ends in the list's `onReorderItem`, after the drop
/// animation; one that lands where it started, and a cancelled drag, call
/// nothing. A pointer up or cancel therefore starts a grace timer
/// ([grace]: the drop animation plus a margin) that calls [onExpired] unless
/// the drop callback released the freeze first.
class ReorderFreeze {
  ReorderFreeze({required this.onExpired});

  /// The list's drop animation (250 ms) plus 100 ms.
  static const grace = Duration(milliseconds: 350);

  /// Called when the grace timer ran out with the freeze still on.
  final VoidCallback onExpired;

  ShownEntries? _frozen;
  String? _draggedUid;
  Timer? _timer;

  bool get active => _frozen != null;
  ShownEntries? get frozen => _frozen;
  String? get draggedUid => _draggedUid;

  void start(String entryUid, ShownEntries shown) {
    _timer?.cancel();
    _timer = null;
    _frozen = shown;
    _draggedUid = entryUid;
  }

  /// Pointer up or cancel: waits for the drop callback, then gives up.
  void armGrace() {
    if (!active) return;
    _timer?.cancel();
    _timer = Timer(grace, () {
      _timer = null;
      if (!active) return;
      release();
      onExpired();
    });
  }

  void release() {
    _timer?.cancel();
    _timer = null;
    _frozen = null;
    _draggedUid = null;
  }

  void dispose() => release();
}

/// Moves [entryUid] of playlist [uid] behind [after] through its open page.
///
/// Not `async`: the controller shows the new order before its first await,
/// and the caller relies on it (the list is unfrozen in the same frame).
/// A failed write says so once; the controller has reloaded the saved order.
void moveEntryOnPage(
  BuildContext context,
  String uid,
  String entryUid,
  String? after,
) {
  final container = ProviderScope.containerOf(context);
  final l10n = AppLocalizations.of(context);
  final root = Navigator.of(context, rootNavigator: true).context;
  final write = container
      .read(playlistPageProvider(uid).notifier)
      .move(entryUid, afterEntryUid: after);
  unawaited(
    write.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        if (error is PlaylistWriteFailure && error.cancelled) return;
        _log.warning('Moving a playlist entry failed', error, stack);
        if (root.mounted) showAppSnackBar(root, l10n.playlistSaveFailed);
      },
    ),
  );
}
