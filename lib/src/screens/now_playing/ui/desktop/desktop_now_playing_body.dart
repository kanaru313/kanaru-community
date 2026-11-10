import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../now_playing_seek_slot.dart';
import 'desktop_now_playing_header.dart';
import 'desktop_side_pane.dart';
import 'desktop_track_column.dart';
import 'now_playing_auto_hide.dart';

/// How long a switch between split and pane-only takes to cross-fade.
const Duration desktopBodyFadeDuration = Duration(milliseconds: 300);

/// The auto-hiding header over the body: the split (track column + side pane)
/// or the side pane alone. A switch cross-fades (at once under reduced
/// motion); the outgoing body ignores pointer and focus while it fades.
class DesktopNowPlayingBody extends StatelessWidget {
  const DesktopNowPlayingBody({
    super.key,
    required this.chrome,
    required this.floatingOpen,
    required this.columnShown,
    required this.onToggleColumn,
    required this.onClose,
  });

  final AutoHideController chrome;
  final ValueNotifier<bool> floatingOpen;
  final bool columnShown;
  final VoidCallback onToggleColumn;
  final VoidCallback onClose;

  Widget _body(BuildContext context) {
    if (!columnShown) {
      return const DesktopSidePane(key: ValueKey('pane only'));
    }
    return NowPlayingSplitLayout(
      key: const ValueKey('split'),
      titleStyle: desktopTitleStyle(context),
      lineStyle: desktopLineStyle(context),
      seekHeight: nowPlayingSeekSlotHeight,
      columnBuilder: (context, metrics) =>
          DesktopTrackColumn(chrome: chrome, metrics: metrics),
      pane: const DesktopSidePane(),
    );
  }

  /// Fades the body; the outgoing one cannot be reached while it goes.
  Widget _transition(Widget child, Animation<double> animation) =>
      FadeTransition(
        opacity: animation,
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, child) {
            final leaving = animation.status == AnimationStatus.reverse;
            return IgnorePointer(
              ignoring: leaving,
              child: ExcludeFocus(excluding: leaving, child: child!),
            );
          },
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : desktopBodyFadeDuration;
    return AutoHideRegion(
      controller: chrome,
      child: Column(
        children: [
          AutoHide(
            controller: chrome,
            child: DesktopNowPlayingHeader(
              onClose: onClose,
              columnShown: columnShown,
              onToggleColumn: onToggleColumn,
              floatingOpen: floatingOpen,
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              key: ValueKey(duration),
              duration: duration,
              transitionBuilder: _transition,
              layoutBuilder: (current, previous) => Stack(
                fit: StackFit.expand,
                children: [...previous, ?current],
              ),
              child: _body(context),
            ),
          ),
        ],
      ),
    );
  }
}
