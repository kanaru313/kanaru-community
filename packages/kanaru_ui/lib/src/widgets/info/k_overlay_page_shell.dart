import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../tokens/k_layout.dart';
import 'k_overlay_page_frames.dart';
import 'k_overlay_page_scope.dart';

/// Body of the route `showKOverlayPage` opens: picks page or box from the
/// width it is given (so a resize while open changes it at once) and keeps
/// [builder]'s subtree alive across the change with a global key.
class KOverlayPageShell extends StatefulWidget {
  const KOverlayPageShell({
    super.key,
    required this.title,
    required this.builder,
    required this.actions,
    required this.boxHeader,
    required this.maxWidth,
    required this.closeTooltip,
    required this.backTooltip,
    required this.viaKeyboard,
  });

  final String title;
  final WidgetBuilder builder;
  final List<Widget> actions;
  final WidgetBuilder? boxHeader;
  final double maxWidth;
  final String closeTooltip;
  final String backTooltip;
  final bool viaKeyboard;

  @override
  State<KOverlayPageShell> createState() => _KOverlayPageShellState();
}

class _KOverlayPageShellState extends State<KOverlayPageShell> {
  /// Keeps the body's state when the shell switches between page and box.
  final GlobalKey _bodyKey = GlobalKey(debugLabel: 'KOverlayPage body');

  // One node per kind: only one header is built at a time, but both exist in
  // the frame where the window crosses the breakpoint.
  final FocusNode _pageHeader = FocusNode(debugLabel: 'KOverlayPage bar');
  final FocusNode _boxHeader = FocusNode(debugLabel: 'KOverlayPage header');

  @override
  void initState() {
    super.initState();
    if (widget.viaKeyboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final node = _pageHeader.context != null ? _pageHeader : _boxHeader;
        for (final d in node.descendants) {
          if (d.canRequestFocus && !d.skipTraversal) {
            d.requestFocus();
            return;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _pageHeader.dispose();
    _boxHeader.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final body = KeyedSubtree(
      key: _bodyKey,
      child: Builder(builder: widget.builder),
    );
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      // A scope, not a plain Focus: when the focused child disappears, focus
      // falls back here (below the shortcuts) and Esc still closes the layer.
      child: FocusScope(
        autofocus: !widget.viaKeyboard,
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: widget.title,
          // One messenger and a see-through Scaffold for the whole route,
          // for both kinds: snack bars draw above the page or the box.
          child: ScaffoldMessenger(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: FocusTraversalGroup(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final page = c.maxWidth < KBreakpoints.compactSheet;
                    return KOverlayPageScope(
                      kind: page ? KOverlayKind.page : KOverlayKind.box,
                      child: page
                          ? KOverlayPageFrame(
                              headerNode: _pageHeader,
                              title: widget.title,
                              actions: widget.actions,
                              backTooltip: widget.backTooltip,
                              onClose: _close,
                              body: body,
                            )
                          : KOverlayBoxFrame(
                              headerNode: _boxHeader,
                              title: widget.title,
                              header: widget.boxHeader?.call(context),
                              actions: widget.actions,
                              closeTooltip: widget.closeTooltip,
                              onClose: _close,
                              maxWidth: widget.maxWidth,
                              // 85 % of the window; under 760 high, all but 48.
                              maxHeight: c.maxHeight < 760
                                  ? c.maxHeight - 48
                                  : c.maxHeight * 0.85,
                              body: body,
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
