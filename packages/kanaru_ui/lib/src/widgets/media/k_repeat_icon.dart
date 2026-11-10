import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';

/// Which glyph [KRepeatIcon] draws. The app maps its repeat mode to one of
/// these; this package knows nothing about the player.
enum KRepeatGlyph {
  /// Stops at the end of the queue.
  off,

  /// The current entry again, endlessly.
  one,

  /// The whole queue.
  all,

  /// The whole queue, in a new random order every pass: the repeat arrows
  /// with a small shuffle badge.
  allShuffled,

  /// The current entry a number of times more: the remaining count in a
  /// circle.
  counted,
}

/// Icon of a repeat mode, in the surrounding icon colour. [glyph] picks the
/// drawing; [count] is the number [KRepeatGlyph.counted] shows. [menu] picks
/// the glyph for [KRepeatGlyph.off]: a list that ends in the menu, the plain
/// (unlit) repeat arrows on the button.
class KRepeatIcon extends StatelessWidget {
  const KRepeatIcon({
    super.key,
    required this.glyph,
    this.count = 0,
    this.size,
    this.menu = false,
  });

  final KRepeatGlyph glyph;
  final int count;
  final double? size;
  final bool menu;

  @override
  Widget build(BuildContext context) {
    final size = this.size ?? IconTheme.of(context).size ?? 24;
    return switch (glyph) {
      KRepeatGlyph.off => Icon(
        menu ? KIcons.flatList : KIcons.repeat,
        size: size,
      ),
      KRepeatGlyph.one => Icon(KIcons.repeatOne, size: size),
      KRepeatGlyph.all => Icon(KIcons.repeat, size: size),
      KRepeatGlyph.allShuffled => SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(KIcons.repeat, size: size),
            Positioned(
              right: -size * 0.12,
              bottom: -size * 0.12,
              child: Icon(KIcons.shuffle, size: size * 0.5),
            ),
          ],
        ),
      ),
      KRepeatGlyph.counted => _CountCircle(count: count, size: size),
    };
  }
}

/// A number in a circle outline, sized like an icon. The number is also in
/// the label next to it, so screen readers skip this.
class _CountCircle extends StatelessWidget {
  const _CountCircle({required this.count, required this.size});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color =
        IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color;
    final circle = size * 21 / 24;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Container(
            width: circle,
            height: circle,
            alignment: Alignment.center,
            padding: EdgeInsets.all(circle * 0.05),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color ?? const Color(0xFF000000),
                width: 1.5,
              ),
            ),
            child: FittedBox(
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
