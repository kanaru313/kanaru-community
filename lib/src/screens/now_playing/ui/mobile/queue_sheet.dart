import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../playback/state/cover_providers.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../../../playback/ui/flight_source.dart';
import '../queue_host.dart';
import '../queue_panel.dart';
import 'shared_flight.dart';

/// Pull of the sheet's head, in dp, past which letting go closes the sheet.
const double queueSheetCloseDistance = 100;

/// Opens the mobile queue sheet over the current screen. The strip at the top
/// is the player surface [from] shrunk (Now Playing or the mini player): its
/// cover, title and two buttons fly there while the sheet slides up, and fly
/// back when it closes. Back, ⌄, a tap on the strip and a pull on the head
/// all close it.
Future<void> showQueueSheet(
  BuildContext context, {
  required FlightSource from,
}) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push(QueueSheetRoute(from: from));
}

/// A route that covers the screen with the strip and the sheet. It is a
/// popup route so Back pops it before the page under it.
class QueueSheetRoute extends PopupRoute<void> {
  QueueSheetRoute({required this.from});

  final FlightSource from;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 360);

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  TickerFuture didPush() {
    // The source pieces are drawn by the flight from now on.
    from.setHidden(true);
    return super.didPush();
  }

  @override
  void dispose() {
    from.setHidden(false);
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => QueueSheetPage(route: this);
}

class QueueSheetPage extends ConsumerStatefulWidget {
  const QueueSheetPage({super.key, required this.route});

  final QueueSheetRoute route;

  @override
  ConsumerState<QueueSheetPage> createState() => _QueueSheetPageState();
}

class _QueueSheetPageState extends ConsumerState<QueueSheetPage>
    with SingleTickerProviderStateMixin {
  // Unbounded: the spring that brings an unfinished pull back may overshoot.
  late final AnimationController _drag = AnimationController.unbounded(
    vsync: this,
  );
  late final QueueFlightProgress _progress = QueueFlightProgress(
    route: widget.route.animation!,
    drag: _drag,
  );

  @override
  void dispose() {
    _progress.dispose();
    _drag.dispose();
    super.dispose();
  }

  void _close() {
    if (widget.route.isCurrent) Navigator.of(context).pop();
  }

  void _dragUpdate(DragUpdateDetails d) {
    _drag.value = (_drag.value + d.delta.dy).clamp(0, double.infinity);
  }

  void _dragEnd(DragEndDetails _) {
    if (_drag.value > queueSheetCloseDistance) {
      _close();
    } else {
      KSpring.animateTo(context, _drag, 0, KSpring.gentle);
    }
  }

  Widget _handle(Widget child) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    dragStartBehavior: DragStartBehavior.down,
    onVerticalDragUpdate: _dragUpdate,
    onVerticalDragEnd: _dragEnd,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final id = ref.watch(nowPlayingProvider.select((n) => n.value?.trackId));
    final coverKey = id == null
        ? null
        : ref.watch(trackInfoProvider(id).select((i) => i.value?.coverKey));
    final colors = coverKey == null
        ? null
        : ref.watch(coverColorsProvider(coverKey)).value;
    Color? tint(int i) => colors == null || colors.palette.length <= i
        ? null
        : Color(colors.palette[i]);
    final scheme = Theme.of(context).colorScheme;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return KFlightStage(
      builder: (context, strip, size) {
        final sheetHeight = size.height - strip.height;
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The strip's ground: the cover tint, fading in with the flight.
              AnimatedBuilder(
                animation: _progress,
                builder: (context, child) =>
                    Opacity(opacity: _progress.value, child: child),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: CoverTintBackground(
                    first: tint(0),
                    second: tint(1) ?? tint(0),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: strip.height,
                height: sheetHeight,
                child: AnimatedBuilder(
                  animation: Listenable.merge([widget.route.animation!, _drag]),
                  builder: (context, child) {
                    final open = widget.route.animation!.value.clamp(0.0, 1.0);
                    // Reduced motion: the sheet fades in place, no slide.
                    final slide = reduced ? 0.0 : (1 - open) * sheetHeight;
                    // The head follows the finger; closing carries on from
                    // there.
                    return Opacity(
                      opacity: reduced ? open : 1,
                      child: Transform.translate(
                        offset: Offset(0, _drag.value * open + slide),
                        child: child,
                      ),
                    );
                  },
                  child: _Sheet(
                    color: scheme.surfaceContainerLow,
                    handle: _handle,
                    onClose: _close,
                  ),
                ),
              ),
              KSharedFlight(
                progress: _progress,
                layers: [
                  for (final layer in queueFlightLayers(
                    widget.route.from,
                    strip,
                    onTapPiece: _close,
                  ))
                    layer,
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    required this.color,
    required this.handle,
    required this.onClose,
  });

  final Color color;
  final Widget Function(Widget child) handle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: KRadius.xl.topLeft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          handle(
            SizedBox(
              height: KSpace.x6,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: KRadius.full,
                  ),
                  child: const SizedBox(width: KSpace.x8, height: 4),
                ),
              ),
            ),
          ),
          Expanded(
            child: QueuePanel(
              host: QueueHost.sheet,
              onClose: onClose,
              onEmptied: onClose,
              beforeNavigate: onClose,
              headWrapper: handle,
            ),
          ),
        ],
      ),
    );
  }
}
