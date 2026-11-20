import 'dart:async' show scheduleMicrotask;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';

/// Esc closes the route and is consumed here, so a shortcut of the shell
/// above the route never sees it.
///
/// Keeps keyboard focus inside the route: after the first frame, when nothing
/// in the route holds focus, this scope takes it (so Esc works with a content
/// that has no focusable child). It never asks for focus up front, so an
/// `autofocus` in the first content keeps winning. Content that appears later
/// (a screen swapped in) asks for focus itself with `requestFocus`, as an
/// `autofocus` is ignored while some node of the route already has focus.
class KModalEscScope extends StatefulWidget {
  const KModalEscScope({super.key, required this.child});

  final Widget child;

  @override
  State<KModalEscScope> createState() => _KModalEscScopeState();
}

class _KModalEscScopeState extends State<KModalEscScope> {
  final _node = FocusNode(debugLabel: 'KModalEscScope', skipTraversal: true);

  @override
  void initState() {
    super.initState();
    // Autofocus requests of the content are applied in a microtask after the
    // first build; look only once they have been.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scheduleMicrotask(() {
        if (!mounted) return;
        if (FocusScope.of(context).focusedChild == null) _node.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
    },
    child: Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            Navigator.of(context).maybePop();
            return null;
          },
        ),
      },
      child: Focus(focusNode: _node, child: widget.child),
    ),
  );
}
