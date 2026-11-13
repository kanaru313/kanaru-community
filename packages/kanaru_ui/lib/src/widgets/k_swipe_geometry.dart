import 'dart:math' as math;

/// Distances of a swipe for a row of a given width: how far the finger must
/// travel and how far the row follows it.
class KSwipeGeometry {
  const KSwipeGeometry({required this.width, required this.isRemove});

  final double width;
  final bool isRemove;

  /// Share of the row width the capped kind may travel, and its hard limit.
  static const double _cappedShare = 0.3;
  static const double _cappedMax = 140;

  /// Trigger distance as a share of the cap (~20 % of the width when the cap
  /// is 30 %).
  static const double _triggerOfCap = 2 / 3;

  /// Share of the row width a drag must cover (from the pointer-down point)
  /// to remove the row.
  static const double _removeShare = 0.7;

  double get cap => (width * _cappedShare).clamp(0.0, _cappedMax);
  double get trigger => cap * _triggerOfCap;

  /// Finger travel that removes the row.
  double get removeTravel => width * _removeShare;

  /// Finger travel at which a release acts (the remove distance, or the
  /// capped trigger when the side has an action).
  bool reached(double travel, {required bool hasAction}) =>
      isRemove ? travel >= removeTravel : hasAction && travel >= trigger;

  /// Row offset (unsigned) for a finger travel: the capped kind follows the
  /// finger up to the trigger, then a rubber band that tends to [cap].
  double offsetFor(double travel, {required bool hasAction}) {
    if (isRemove) return travel.clamp(0.0, width);
    if (!hasAction) return 0;
    if (travel <= trigger) return travel;
    final room = cap - trigger;
    if (room <= 0) return trigger;
    return trigger + room * (1 - math.exp(-(travel - trigger) / room));
  }

  /// Inverse of [offsetFor]: the travel that puts the row at [offset], so a
  /// row grabbed mid-animation continues from where it is.
  double travelFor(double offset, {required bool hasAction}) {
    if (isRemove || !hasAction || offset <= trigger) return offset;
    final room = cap - trigger;
    if (room <= 0) return offset;
    final share = ((offset - trigger) / room).clamp(0.0, 0.999);
    return trigger - room * math.log(1 - share);
  }
}
