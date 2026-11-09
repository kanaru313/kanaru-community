/// Page and container sizes.
abstract final class KLayout {
  static const double gutterMobile = 16;
  static const double gutterDesktop = 24;

  /// Max width of reading content and of settings pages.
  static const double readable = 720;
  static const double settings = 720;
  static const double dialog = 440;
  static const double sheet = 640;

  /// Minimum touch target: 48 on touch, 40 with a mouse.
  static const double minTarget = 48;
  static const double minTargetDesktop = 40;
}

/// Width thresholds. The only place width literals live.
abstract final class KBreakpoints {
  /// At or above: desktop form factor.
  static const double desktop = 1200;

  /// Below: modals render as a bottom sheet, from here up as a dialog.
  static const double compactSheet = 600;
}
