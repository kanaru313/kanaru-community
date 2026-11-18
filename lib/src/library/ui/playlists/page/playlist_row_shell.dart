import 'package:flutter/widgets.dart';

import 'playlist_entry_removal.dart';

/// Around each row of a playlist page, keyed by its entry (the reorderable
/// list needs the key on the top widget): gives [PlaylistEntryRemoval] the
/// focus node of the row, so the focus can move to the next row when this one
/// is removed with the keyboard.
class PlaylistRowShell extends StatefulWidget {
  const PlaylistRowShell({
    super.key,
    required this.uid,
    required this.removal,
    required this.child,
  });

  final String uid;
  final PlaylistEntryRemoval removal;
  final Widget child;

  @override
  State<PlaylistRowShell> createState() => _PlaylistRowShellState();
}

class _PlaylistRowShellState extends State<PlaylistRowShell> {
  /// Never takes focus itself; `hasFocus` tells that something inside has it.
  final FocusNode _node = FocusNode(
    debugLabel: 'PlaylistRow',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    widget.removal.rowNodes[widget.uid] = _node;
  }

  @override
  void dispose() {
    final nodes = widget.removal.rowNodes;
    if (identical(nodes[widget.uid], _node)) nodes.remove(widget.uid);
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Focus(focusNode: _node, child: widget.child);
}
