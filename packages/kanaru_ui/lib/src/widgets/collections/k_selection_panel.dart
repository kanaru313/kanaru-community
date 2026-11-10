import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../layout/form_factor.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';

/// Frame of the floating multi-select panel: [header] (the controls row)
/// and, when [expanded], a [body] list below it. No state, no music types.
///
/// Mobile: full width minus an 8 dp margin, radius 20. Desktop: 440 wide,
/// centred, radius 22, with a shadow. The body is a builder-based list from
/// the caller; the frame gives it [bodyHeight] (clamped to [maxBodyHeight])
/// so it scrolls inside the frame instead of laying out every row.
class KSelectionPanel extends StatelessWidget {
  const KSelectionPanel({
    super.key,
    required this.header,
    this.body,
    this.expanded = false,
    this.bodyHeight = maxBodyHeight,
    this.semanticLabel,
  });

  final Widget header;
  final Widget? body;
  final bool expanded;
  final double bodyHeight;
  final String? semanticLabel;

  static const double desktopWidth = 440;
  static const double maxBodyHeight = 460;

  /// Height of the controls row the caller puts in [header].
  static const double headerHeight = 56;

  /// Height the body gets: [bodyHeight] clamped to [maxBodyHeight] and to
  /// half the window, so the page stays reachable on a short one.
  static double bodyHeightFor(BuildContext context, double bodyHeight) =>
      math.min(
        math.min(bodyHeight, maxBodyHeight),
        MediaQuery.sizeOf(context).height * 0.5,
      );

  /// Height of the whole panel (the single source for the panel and for the
  /// room a page leaves for it).
  static double heightFor(
    BuildContext context, {
    required bool expanded,
    required double bodyHeight,
  }) => headerHeight + (expanded ? bodyHeightFor(context, bodyHeight) : 0);
  static const double _margin = KSpace.x1;

  @override
  Widget build(BuildContext context) {
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    final scheme = Theme.of(context).colorScheme;
    final radius = mobile
        ? KRadius.lg
        : const BorderRadius.all(Radius.circular(22));
    final panel = Material(
      elevation: mobile ? 3 : 8,
      shadowColor: scheme.shadow,
      color: scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: KMotion.normal,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            if (expanded && body != null)
              SizedBox(height: bodyHeightFor(context, bodyHeight), child: body),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      label: semanticLabel,
      child: mobile
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: _margin),
              child: panel,
            )
          : Center(
              heightFactor: 1,
              child: SizedBox(width: desktopWidth, child: panel),
            ),
    );
  }
}
