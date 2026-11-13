import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../playback/ui/spring_to_rest.dart';
import '../state/mobile_sidebar_state.dart';
import 'mobile_sidebar.dart';

/// Push sidebar: the sidebar sits under the content; opening slides the
/// content right by the sidebar's width, rounds its corners and dims it.
///
/// One unbounded controller driven by the gentle spring (reduced motion
/// jumps). Closing: tap the dimmed content, drag it left more than
/// [closeDistance], or Back.
class MobilePushLayout extends ConsumerStatefulWidget {
  const MobilePushLayout({
    super.key,
    required this.sidebar,
    required this.content,
  });

  static const double closeDistance = 60;
  static const double contentRadius = 28;
  static const double scrimAlpha = 0.45;
  static const double sidebarShift = 24;

  final Widget sidebar;
  final Widget content;

  @override
  ConsumerState<MobilePushLayout> createState() => _MobilePushLayoutState();
}

class _MobilePushLayoutState extends ConsumerState<MobilePushLayout>
    with SingleTickerProviderStateMixin {
  // Unbounded: the gentle spring does not overshoot, but the bouncy ones
  // would, and the helper's contract asks for it.
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
  );
  double _dragged = 0;

  @override
  void initState() {
    super.initState();
    // The open state outlives this widget (the app swaps shells at the
    // desktop breakpoint), so start where the provider is.
    _controller.value = ref.read(mobileSidebarOpenProvider) ? 1 : 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() => ref.read(mobileSidebarOpenProvider.notifier).close();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final open = ref.watch(mobileSidebarOpenProvider);
    ref.listen(mobileSidebarOpenProvider, (_, isOpen) {
      animateSpringTo(context, _controller, isOpen ? 1 : 0, KSpring.gentle);
    });
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (!ref.read(mobileSidebarOpenProvider)) return false;
        _close();
        return true;
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value.clamp(0.0, 1.0);
          // The sidebar's colour fills the whole ground: the content's rounded
          // corners sit past the sidebar's right edge, where nothing else is
          // drawn and the window's black would show.
          return ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: Stack(
              children: [
                Offstage(
                  offstage: t == 0 && !open,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: Offset(
                        -MobilePushLayout.sidebarShift * (1 - t),
                        0,
                      ),
                      child: widget.sidebar,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(MobileSidebar.width * t, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      MobilePushLayout.contentRadius * t,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ExcludeFocus(excluding: open, child: widget.content),
                        if (open || t > 0)
                          Positioned.fill(
                            child: Semantics(
                              button: true,
                              label: l10n.playbackSidebarClose,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                dragStartBehavior: DragStartBehavior.down,
                                onTap: open ? _close : null,
                                onHorizontalDragStart: (_) => _dragged = 0,
                                onHorizontalDragUpdate: (d) =>
                                    _dragged += d.delta.dx,
                                onHorizontalDragEnd: (_) {
                                  if (open &&
                                      _dragged <
                                          -MobilePushLayout.closeDistance) {
                                    _close();
                                  }
                                },
                                child: ColoredBox(
                                  color: Colors.black.withValues(
                                    alpha: MobilePushLayout.scrimAlpha * t,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
