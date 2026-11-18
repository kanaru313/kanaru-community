import 'package:flutter/widgets.dart';

import '../../../domain/playlists/playlist_models.dart';
import 'playlist_page_actions.dart';

/// The edit-mode removal of a playlist page's rows (swipe either way, the ✕,
/// the Delete key) and where keyboard focus goes when the focused row leaves.
/// Plain object owned by the songs part. Every removal goes through
/// `removeEntryOnPage` (the page's controller and the Undo toast).
class PlaylistEntryRemoval {
  PlaylistEntryRemoval({
    required this.context,
    required this.uid,
    required this.rows,
    required this.pageFocus,
  });

  final BuildContext Function() context;
  final String Function() uid;

  /// The rows drawn by the last build, in order.
  final List<PlaylistEntryView> Function() rows;

  /// Where focus goes when no row is left to take it.
  final FocusNode pageFocus;

  /// The focus node around each built row, by entry uid (see
  /// `PlaylistRowShell`).
  final Map<String, FocusNode> rowNodes = {};

  /// Removes [entry]: true = the row leaves; false = it stays or springs back
  /// (the write failed, was cancelled behind a failure, or removed nothing;
  /// the toast says which).
  Future<bool> remove(PlaylistEntryView entry) async {
    final ctx = context();
    if (!ctx.mounted) return false;
    final heir = _heirOf(entry.uid);
    // The page's list drops the row in the same call (before any await), so
    // the focus can move with the next frame instead of waiting for the write.
    final write = removeEntryOnPage(ctx, uid(), entry);
    if (heir != null) _moveFocus(ctx, heir.uid);
    final result = await write;
    // The write failed and the saved list is back: the first failed row takes
    // focus again (a write cancelled behind it leaves it where it is).
    if (ctx.mounted &&
        heir != null &&
        (result == PageRemoval.failed || result == PageRemoval.nothing)) {
      _moveFocus(ctx, entry.uid, restore: true);
    }
    return result == PageRemoval.removed;
  }

  /// The row that takes the focus when the focused row [uid] goes: the one
  /// after it, else the one before; `(uid: null)` when it was the only row.
  /// Null when focus is not inside the row (a swipe, a touch).
  ({String? uid})? _heirOf(String uid) {
    if (!(rowNodes[uid]?.hasFocus ?? false)) return null;
    final all = rows();
    final i = all.indexWhere((e) => e.uid == uid);
    if (i < 0) return null;
    if (i + 1 < all.length) return (uid: all[i + 1].uid);
    return (uid: i > 0 ? all[i - 1].uid : null);
  }

  /// After the frame that dropped the row: focus [uid]'s row, or the page
  /// when there is none (the playlist is empty and edit mode ends).
  void _moveFocus(BuildContext ctx, String? uid, {bool restore = false}) {
    if (!ctx.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ctx.mounted) return;
      // A restore only goes to a row that is still there: a removal that
      // removed nothing must not pull focus off the row that took its place.
      if (restore && !rowNodes.containsKey(uid)) return;
      // Post-order: the row's own node (the card) comes after the buttons in
      // it, so the last one is the outermost; focusing a button would show no
      // row ring and Enter would press it.
      final inside = uid == null
          ? null
          : rowNodes[uid]?.traversalDescendants.lastOrNull;
      (inside ?? pageFocus).requestFocus();
    });
  }
}
