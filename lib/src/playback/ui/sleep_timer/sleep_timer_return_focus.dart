import 'package:material_ui/material_ui.dart';

import 'sleep_timer_modal.dart';

/// Opens the sleep timer and returns once it has closed. [returnFocus] gets
/// focus back after it. Entries take one so a screen can pin its chrome while
/// the modal is open.
typedef SleepTimerOpener = Future<void> Function(
  BuildContext context,
  FocusNode returnFocus,
);

/// The plain opener: [showSleepTimer].
Future<void> openSleepTimerModal(BuildContext context, FocusNode returnFocus) =>
    showSleepTimer(context, returnFocus: returnFocus);

/// A focus target for the modal that picks its node when focus is handed back,
/// not when the modal opens. The entry's own node can be gone by then (the
/// timer was turned off, so a ring button left the tree): focus then goes to
/// [fallback], and to nowhere when that is gone too.
///
/// It is never attached to the tree; the modal only reads [context] and calls
/// [requestFocus].
class SleepReturnFocus extends FocusNode {
  SleepReturnFocus(this._primary, this._fallback)
    : super(debugLabel: 'sleep return focus');

  FocusNode? _primary;
  final FocusNode? _fallback;

  /// The primary node is about to be disposed: never touch it again.
  void releasePrimary() => _primary = null;

  /// A node still in the focus tree. A node whose widget left the tree keeps
  /// its old `context` but has no parent any more.
  static bool _attached(FocusNode? node) =>
      node != null && node.context != null && node.parent != null;

  FocusNode? get _target {
    if (_attached(_primary)) return _primary;
    if (_attached(_fallback)) return _fallback;
    return null;
  }

  @override
  BuildContext? get context => _target?.context;

  @override
  void requestFocus([FocusNode? node]) => _target?.requestFocus(node);
}

/// The focus node of one timer entry and the modal openings that return to it.
/// Owned by the entry's `State`; [dispose] stops open modals from touching the
/// node.
class SleepEntryFocus {
  SleepEntryFocus({String debugLabel = 'sleep entry'})
    : node = FocusNode(debugLabel: debugLabel);

  /// Passed to whichever button the entry shows (icon, pill, ring).
  final FocusNode node;

  /// Where focus goes when [node] is no longer in the tree after a close.
  FocusNode? fallback;

  final _open = <SleepReturnFocus>{};

  /// Runs [opener] with a return target for this entry.
  Future<void> open(BuildContext context, SleepTimerOpener opener) async {
    final target = SleepReturnFocus(node, fallback);
    _open.add(target);
    try {
      await opener(context, target);
    } finally {
      _open.remove(target);
      // The modal asks the target for focus in a post-frame callback it
      // registered before this one runs.
      WidgetsBinding.instance.addPostFrameCallback((_) => target.dispose());
    }
  }

  void dispose() {
    for (final target in _open) {
      target.releasePrimary();
    }
    node.dispose();
  }
}
