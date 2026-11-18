import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/browse/selection_providers.dart';
import '../../selection/selection_back.dart' show rootModalOpen;
import '../../selection/selection_shortcuts.dart' show textFieldHasFocus;

/// Back and Esc of a playlist page or of the playlists list page: while a
/// layer of the page is open ([active]: edit mode, the filter), one Back or
/// one Esc closes the outermost one ([closeTop], true when it closed one) and
/// the page stays.
///
/// - Back: a `PopScope` whose `canPop` is false while a layer is open. Dialogs,
///   sheets and menus sit on the root navigator and take Back themselves; the
///   app-wide selection panel answers before the page (`SelectionBackScope`).
/// - Esc: a `Focus` that owns the key. The desktop shell takes Esc for
///   "history back" unless the focus tree below it handles the key, so while a
///   layer is open the page keeps focus inside this node (taking it when a
///   layer opens, and again when focus falls to nothing). It yields to a text
///   field (the filter field's own Esc closes it) and to a root modal.
///
/// The app-wide selection panel and the FAB menu close themselves on Esc
/// through global key handlers, which run in the same dispatch as this node
/// (the focus tree is asked even when they answered). An Esc that just closed
/// one of them is theirs: this node swallows it instead of closing a layer
/// too (or letting the shell go back).
class PlaylistBackScope extends ConsumerStatefulWidget {
  const PlaylistBackScope({
    super.key,
    required this.active,
    required this.closeTop,
    required this.focusNode,
    required this.child,
    this.outerMenu,
  });

  /// Whether a layer is open.
  final bool active;

  /// Closes the outermost open layer; false when none is open.
  final bool Function() closeTop;

  /// The page's own node. Owned by the caller, which may also focus it (a
  /// keyboard user whose last row is gone lands here).
  final FocusNode focusNode;

  final Widget child;

  /// Whether a menu that closes itself on Esc (the FAB menu) is open.
  final ValueListenable<bool>? outerMenu;

  @override
  ConsumerState<PlaylistBackScope> createState() => _PlaylistBackScopeState();
}

class _PlaylistBackScopeState extends ConsumerState<PlaylistBackScope> {
  FocusNode get _node => widget.focusNode;

  /// An outer layer closed during the key dispatch under way.
  bool _outerClosed = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChanged);
    widget.outerMenu?.addListener(_onOuterMenu);
    if (widget.active) _retakeLater();
  }

  @override
  void didUpdateWidget(PlaylistBackScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _retakeLater();
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChanged);
      widget.focusNode.addListener(_onFocusChanged);
    }
    if (widget.outerMenu != oldWidget.outerMenu) {
      oldWidget.outerMenu?.removeListener(_onOuterMenu);
      widget.outerMenu?.addListener(_onOuterMenu);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChanged);
    widget.outerMenu?.removeListener(_onOuterMenu);
    super.dispose();
  }

  bool _menuWasOpen = false;

  /// The page keeps focus while a layer of its own is open or its menu is:
  /// only the layers (`active`) block Back; the menu answers Back itself.
  bool get _holdsFocus => widget.active || (widget.outerMenu?.value ?? false);

  void _onOuterMenu() {
    final open = widget.outerMenu?.value ?? false;
    if (_menuWasOpen && !open) _noteOuterClosed();
    // An open menu answers Esc through a global handler while the shell's own
    // Esc asks "is focus inside the page?": hold focus here meanwhile.
    if (open && !_menuWasOpen) _retakeLater();
    _menuWasOpen = open;
  }

  /// Remembered for the rest of the synchronous key dispatch only.
  void _noteOuterClosed() {
    _outerClosed = true;
    scheduleMicrotask(() => _outerClosed = false);
  }

  void _onFocusChanged() {
    if (!_node.hasFocus && _holdsFocus) _retakeLater();
  }

  /// A layer opened, or focus left the page while one is open: once the frame
  /// is done and the focus manager has settled (a field that autofocuses, a
  /// row the rebuild removed), take focus unless something has it.
  void _retakeLater() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduleMicrotask(_retake);
    });
  }

  /// Takes focus only when nothing specific has it: the toggle, a field, a
  /// sidebar button, a dialog or another page keeps its own.
  void _retake() {
    if (!mounted || !_holdsFocus || _node.hasFocus) return;
    if (!(ModalRoute.isCurrentOf(context) ?? true) ||
        !TickerMode.valuesOf(context).enabled ||
        rootModalOpen(context)) {
      return;
    }
    final primary = FocusManager.instance.primaryFocus;
    if (primary == null || primary is FocusScopeNode) _node.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        textFieldHasFocus() ||
        rootModalOpen(context)) {
      return KeyEventResult.ignored;
    }
    // Esc that closed the panel or the FAB menu is theirs, whatever is open
    // here (and the page is not left either).
    if (_outerClosed) return KeyEventResult.handled;
    if (!widget.active) return KeyEventResult.ignored;
    return widget.closeTop() ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(librarySelectionProvider.select((s) => s.expanded), (was, now) {
      if (was == true && !now) _noteOuterClosed();
    });
    return PopScope(
      canPop: !widget.active,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.closeTop();
      },
      child: Focus(focusNode: _node, onKeyEvent: _onKey, child: widget.child),
    );
  }
}
