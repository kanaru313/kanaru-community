import 'package:flutter/painting.dart';

/// Corner radii by role (xs 8 ... xl 28, full = stadium).
abstract final class KRadius {
  static const BorderRadius xs = BorderRadius.all(Radius.circular(8));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(12));
  static const BorderRadius md = BorderRadius.all(Radius.circular(16));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(20));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(28));

  /// Large enough to read as a stadium on any control height.
  static const BorderRadius full = BorderRadius.all(Radius.circular(999));
}

/// Builds shapes from [KRadius] values so widgets never write radius literals.
abstract final class KShape {
  /// Rounded rectangle; [continuous] gives the squircle corner of large
  /// surfaces such as dialogs.
  static ShapeBorder of(BorderRadius radius, {bool continuous = false}) =>
      continuous
          ? RoundedSuperellipseBorder(borderRadius: radius)
          : RoundedRectangleBorder(borderRadius: radius);
}
