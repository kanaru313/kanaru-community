import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

final _log = Logger('library.songTile');

/// Playlist edit mode of a `SongTile`: the row gets a drag handle and a way to
/// remove it, and loses every other action.
class SongTileEdit {
  const SongTileEdit({
    required this.handle,
    required this.removeLabel,
    required this.onRemove,
  });

  /// The drag handle of the page's reorderable list, shown before the row end.
  final Widget handle;

  /// Name of the remove action: the swipe's semantics and the desktop ✕ tooltip.
  final String removeLabel;

  /// Removes the entry. False or a throw: the row springs back.
  final Future<bool> Function() onRemove;
}

/// One removal at a time per row: the swipe, the ✕ and the Delete key share
/// it, so a double tap or a held key removes the entry once.
class SongTileRemoval {
  bool _pending = false;

  /// Runs [SongTileEdit.onRemove]; false at once while an earlier one is
  /// still running (the swipe springs back).
  Future<bool> run(SongTileEdit edit) async {
    if (_pending) return false;
    _pending = true;
    try {
      return await edit.onRemove();
    } finally {
      _pending = false;
    }
  }

  /// The ✕ and the Delete key: nothing to spring back; a failure is logged
  /// (the page reports it to the user).
  void fire(SongTileEdit edit) {
    unawaited(
      run(edit).then<void>(
        (_) {},
        onError: (Object e, StackTrace s) =>
            _log.warning('removing a playlist entry failed', e, s),
      ),
    );
  }
}

/// Owns the row's [SongTileRemoval]. Part of every row's tree, edit mode or
/// not, so turning edit mode on or off remounts nothing.
class SongTileRemovalScope extends StatefulWidget {
  const SongTileRemovalScope({super.key, required this.builder});

  final Widget Function(BuildContext context, SongTileRemoval removal) builder;

  @override
  State<SongTileRemovalScope> createState() => _SongTileRemovalScopeState();
}

class _SongTileRemovalScopeState extends State<SongTileRemovalScope> {
  final _removal = SongTileRemoval();

  @override
  Widget build(BuildContext context) => widget.builder(context, _removal);
}

/// The handle of an edit row, with the desktop ✕ before it when [showRemove].
Widget songTileEditAccessory(
  SongTileEdit edit, {
  required bool showRemove,
  required VoidCallback onRemove,
}) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    if (showRemove)
      KIconButton(
        icon: KIcons.close,
        size: KIconSize.sm,
        emphasis: KIconEmphasis.destructive,
        tooltip: edit.removeLabel,
        onPressed: onRemove,
      ),
    edit.handle,
  ],
);
