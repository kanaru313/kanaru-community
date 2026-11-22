import 'package:flutter/services.dart';

/// What makes a [KTextFieldRow] a number field: the accepted characters, the
/// numeric keyboard and the in-field − / + buttons (also bound to ↑ / ↓),
/// which move the value by [step] inside [min]…[max].
///
/// Every step, from a tap or a key, writes the new text into the field and
/// calls [onStepped] with it at once, so the caller can save per step. A
/// button is disabled when the value already sits at its bound. The text is
/// plain: no grouping, a whole value has no decimal point.
class KNumberSpec {
  const KNumberSpec({
    required this.decreaseTooltip,
    required this.increaseTooltip,
    required this.onStepped,
    this.integer = false,
    this.min,
    this.max,
    this.step = 1,
  }) : assert(step > 0, 'step must be positive');

  /// Accepts `-+0-9` only; otherwise also `.eE`.
  final bool integer;
  final double? min;
  final double? max;
  final double step;

  /// Tooltip and accessible name of the − and + buttons.
  final String decreaseTooltip;
  final String increaseTooltip;

  /// Called with the new text after a step.
  final ValueChanged<String> onStepped;

  TextInputType get keyboard =>
      TextInputType.numberWithOptions(signed: true, decimal: !integer);

  List<TextInputFormatter> get formatters => [
    FilteringTextInputFormatter.allow(
      RegExp(integer ? r'[-+0-9]' : r'[-+0-9.eE]'),
    ),
  ];

  /// The number in [text], or null when it is empty, not a number or not
  /// finite.
  double? parse(String text) {
    final value = double.tryParse(text.trim());
    return value != null && value.isFinite ? value : null;
  }

  /// Whether a step in direction [dir] (-1 or 1) can still change [text].
  /// Text that is not a number can always step: it jumps to a valid value.
  bool canStep(String text, int dir) {
    final value = parse(text);
    if (value == null) return true;
    return dir < 0
        ? (min == null || value > min!)
        : (max == null || value < max!);
  }

  /// The text after one step in direction [dir], or null when it would not
  /// change.
  String? stepped(String text, int dir) {
    final current = parse(text);
    var next = (current ?? min ?? 0) + dir * step;
    if (min != null && next < min!) next = min!;
    if (max != null && next > max!) next = max!;
    if (integer) next = next.roundToDouble();
    if (next == current) return null;
    return format(next);
  }

  /// [value] as field text: rounded to 10 decimals (no `0.30000000000000004`),
  /// without a decimal point when whole.
  String format(double value) {
    final rounded = (value * 1e10).round() / 1e10;
    return rounded == rounded.truncateToDouble() && rounded.abs() < 1e15
        ? rounded.toInt().toString()
        : rounded.toString();
  }
}
