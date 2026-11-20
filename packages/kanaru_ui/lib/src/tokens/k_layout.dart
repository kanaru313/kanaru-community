/// Page and container sizes.
abstract final class KLayout {
  static const double gutterMobile = 16;
  static const double gutterDesktop = 24;

  /// Max width of reading content and of settings pages.
  static const double readable = 720;
  static const double settings = 720;
  static const double dialog = 440;

  /// Wide dialog: playlist Edit, song info.
  static const double dialogWide = 620;
  static const double sheet = 640;

  /// Modal dialog of `showKSheet(dialog: KSheetDialog.modal)`; the large one
  /// from 200 % text.
  static const double dialogModal = 420;
  static const double dialogModalLarge = 520;

  /// Max width of the "Sắp xếp theo" box (`KSortDialog`), centred on both shells.
  static const double sortDialog = 400;

  /// Sort dropdown (`showKSortPopover`): width follows the content between
  /// these two, height stops at [dropdownMaxHeight] (or 70 % of a short screen).
  static const double dropdownMinWidth = 160;
  static const double dropdownMaxWidth = 280;
  static const double dropdownMaxHeight = 360;

  /// Anchored desktop `SelectionPicker` panel: width follows the content
  /// between these two.
  static const double anchoredPickerMinWidth = 200;
  static const double anchoredPickerMaxWidth = 360;

  /// Dropdown item row (dense `SelectionRow`), both shells: the hit area is
  /// [dropdownRowHeight] tall, the visible tint / hover / focus shape is
  /// [dropdownRowVisible] tall and centred (a transparent band above and below
  /// still takes taps). Rows grow with large text.
  static const double dropdownRowHeight = 40;
  static const double dropdownRowVisible = 36;

  /// Height of a compact text button placed inside content (e.g. "Xem thêm").
  static const double compactButton = 36;

  /// Minimum touch target of rows, text buttons, chips and headers: 48 on
  /// touch, 40 with a mouse. Icon buttons are exempt: they are the icon plus
  /// their own padding (`KIconButton`), and header heights stay on this value.
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
