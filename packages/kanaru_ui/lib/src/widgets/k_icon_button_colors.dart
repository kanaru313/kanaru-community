import 'package:material_ui/material_ui.dart';

/// Icon colours a surface gives to the [KIconButton]s inside it, for surfaces
/// whose background makes the theme colours unreadable (a row tinted by its
/// cover). A button with its own `color` ignores [rest].
///
/// [rest] is the colour at rest; [hover] is the colour under the mouse. A
/// null value leaves that state to the theme (`onSurfaceVariant` at rest,
/// `onSurface` on hover).
class KIconButtonColors extends InheritedWidget {
  const KIconButtonColors({
    super.key,
    this.rest,
    this.hover,
    required super.child,
  });

  final Color? rest;
  final Color? hover;

  /// The nearest colours above [context], or null. Registers a dependency, so
  /// the button rebuilds when they change.
  static KIconButtonColors? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KIconButtonColors>();

  @override
  bool updateShouldNotify(KIconButtonColors oldWidget) =>
      rest != oldWidget.rest || hover != oldWidget.hover;
}

/// Glyph colour of a `KIconButton` for its current state. [pressed] (0..1)
/// dims the colour by up to half through its alpha: press feedback needs no
/// Opacity layer.
Color resolveKIconButtonColor({
  required ColorScheme scheme,
  required KIconButtonColors? colors,
  required Color? color,
  required Color? selectedColor,
  required bool selected,
  required bool hovered,
  required bool enabled,
  required double pressed,
}) {
  if (!enabled) return scheme.onSurface.withValues(alpha: 0.38);
  final base = selected
      ? selectedColor ?? scheme.primary
      : hovered
      ? colors?.hover ?? scheme.onSurface
      : color ?? colors?.rest ?? scheme.onSurfaceVariant;
  return base.withValues(alpha: base.a * (1 - 0.5 * pressed));
}
