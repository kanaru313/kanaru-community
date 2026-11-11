import 'package:flutter/foundation.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../playback/ui/flight_source.dart';
import 'queue_strip.dart';

/// Flight progress of the queue sheet: 1 when it is open, 0 when it is closed.
/// It follows the route's own animation, and a drag on the sheet's head pulls
/// it down: `route * (1 - drag)`. Releasing the drag past the limit closes the
/// route, which carries on from where the finger left it.
class QueueFlightProgress extends ChangeNotifier
    implements ValueListenable<double> {
  QueueFlightProgress({required this.route, required this.drag}) {
    route.addListener(_changed);
    drag.addListener(_changed);
  }

  final ValueListenable<double> route;

  /// How far the sheet's head has been pulled down, in dp.
  final ValueListenable<double> drag;

  /// How far (0..1) the head has been pulled, from the drag in dp.
  static double pulled(double dragDp) => (dragDp / dragRange).clamp(0.0, 1.0);

  /// Drag distance that stands for a full flight back.
  static const double dragRange = 240;

  @override
  double get value => route.value.clamp(0.0, 1.0) * (1 - pulled(drag.value));

  void _changed() => notifyListeners();

  @override
  void dispose() {
    route.removeListener(_changed);
    drag.removeListener(_changed);
    super.dispose();
  }
}

/// The four flying layers between [source] and the strip. A piece whose
/// source rect cannot be read flies from nowhere and fades in instead.
List<KFlightLayer> queueFlightLayers(
  FlightSource source,
  KQueueStripGeometry strip, {
  VoidCallback? onTapPiece,
}) => [
  KFlightLayer(
    from: source.rectOf(FlightPiece.cover),
    to: strip.cover,
    builder: (context, rect, t) => GestureDetector(
      onTap: onTapPiece,
      child: StripCover(rect: rect, t: t),
    ),
  ),
  KFlightLayer(
    from: source.rectOf(FlightPiece.text),
    to: strip.text,
    builder: (context, rect, t) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTapPiece,
      child: StripText(t: t),
    ),
  ),
  KFlightLayer(
    from: source.rectOf(FlightPiece.play),
    to: strip.play,
    builder: (context, rect, t) => StripPlay(rect: rect, t: t),
  ),
  KFlightLayer(
    from: source.rectOf(FlightPiece.next),
    to: strip.next,
    builder: (context, rect, t) => StripNext(t: t),
  ),
];
