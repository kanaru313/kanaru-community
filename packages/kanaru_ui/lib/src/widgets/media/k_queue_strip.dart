import 'package:material_ui/material_ui.dart';

import '../../tokens/k_space.dart';

/// Where the pieces sit in the strip at the top of the mobile queue sheet:
/// cover 72, title and artist, play/pause 56, next 48. Pure numbers, in the
/// coordinates of the page that holds the strip.
class KQueueStripGeometry {
  const KQueueStripGeometry({required this.width, required this.topInset});

  static const double coverSize = 72;
  static const double playSize = 56;
  static const double nextSize = 48;
  static const double inset = KSpace.x4;
  static const double gap = KSpace.x3;
  static const double vertical = KSpace.x2;

  /// Width of the page.
  final double width;

  /// Status bar / notch height above the strip.
  final double topInset;

  double get _top => topInset + vertical;

  /// The strip, status bar inset included.
  double get height => _top + coverSize + vertical;

  Rect get cover => Rect.fromLTWH(inset, _top, coverSize, coverSize);

  Rect get next => Rect.fromLTWH(
    width - inset - nextSize,
    _top + (coverSize - nextSize) / 2,
    nextSize,
    nextSize,
  );

  Rect get play => Rect.fromLTWH(
    next.left - playSize,
    _top + (coverSize - playSize) / 2,
    playSize,
    playSize,
  );

  /// Title and artist, between the cover and the play button.
  Rect get text => Rect.fromLTRB(
    cover.right + gap,
    _top,
    play.left - KSpace.x2,
    _top + coverSize,
  );
}

/// Measures the page it stands in and hands the strip geometry and the page
/// size to [builder]. The queue sheet and its flights are laid out from these
/// numbers; width math belongs here, not in `screens/`.
class KFlightStage extends StatelessWidget {
  const KFlightStage({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    KQueueStripGeometry strip,
    Size size,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => builder(
        context,
        KQueueStripGeometry(
          width: box.maxWidth,
          topInset: MediaQuery.paddingOf(context).top,
        ),
        box.biggest,
      ),
    );
  }
}
