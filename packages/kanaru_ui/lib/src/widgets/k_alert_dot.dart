import 'package:material_ui/material_ui.dart';

/// Red dot that flags something wrong. Colour `error`, no animation, hidden
/// from screen readers: the row that carries it says what is wrong.
///
/// [KAlertDot.new] is the 8 dp dot that follows a text (no ring);
/// [KAlertDot.corner] pins a 12 dp dot with a 2 dp ring in the card colour
/// on the top-right corner of [child] (top-left in right-to-left text), its
/// centre 3 dp outside the corner.
class KAlertDot extends StatelessWidget {
  const KAlertDot({super.key}) : child = null;

  const KAlertDot.corner({super.key, required Widget this.child});

  final Widget? child;

  static const double _inlineSize = 8;
  static const double _cornerSize = 12;
  static const double _ring = 2;
  static const double _outside = 3;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final host = child;
    if (host == null) {
      return ExcludeSemantics(
        child: SizedBox.square(
          dimension: _inlineSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    const total = _cornerSize + 2 * _ring;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        host,
        // Dot centre = corner shifted 3 dp out on both axes.
        PositionedDirectional(
          top: -_outside - total / 2,
          end: -_outside - total / 2,
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surfaceContainerLow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(_ring),
                child: SizedBox.square(
                  dimension: _cornerSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
