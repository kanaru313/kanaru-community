import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_shape.dart';

/// Deterministic 32-bit FNV-1a hash over the UTF-16 code units of [seed].
/// Unlike `String.hashCode` it is the same on every run and platform, so a
/// placeholder keeps its colour. It is a local copy because kanaru_ui cannot
/// import the app's stable hash (the app depends on this package, not the
/// other way round). Not part of the package API.
@visibleForTesting
int coverSeedHash(String seed) {
  var h = 0x811c9dc5;
  for (final unit in seed.codeUnits) {
    h = ((h ^ unit) * 0x01000193) & 0xffffffff;
  }
  return h;
}

/// Colours of the cover placeholder for a seed, so other surfaces (a colour
/// tile, a genre chip) can match the placeholder a [KCover] would draw.
class KCoverPlaceholderColors {
  const KCoverPlaceholderColors._(this.fill, this.ink);

  /// Colours for [seed] in [brightness]: the hue comes from the seed's stable
  /// hash, so the same seed always gets the same colour.
  factory KCoverPlaceholderColors.of(String seed, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final hue = (coverSeedHash(seed) % 360).toDouble();
    return KCoverPlaceholderColors._(
      HSLColor.fromAHSL(1, hue, 0.35, dark ? 0.28 : 0.82).toColor(),
      HSLColor.fromAHSL(1, hue, 0.35, dark ? 0.75 : 0.35).toColor(),
    );
  }

  /// Background of the placeholder.
  final Color fill;

  /// Icon colour on [fill].
  final Color ink;
}

/// Square (or round) cover art. Decodes at `size x devicePixelRatio`, fades in
/// and falls back to a placeholder (colour picked from [placeholderSeed]) when
/// [image] is null or fails to load.
class KCover extends StatelessWidget {
  const KCover({
    super.key,
    required this.image,
    required this.size,
    required this.placeholderSeed,
    this.radius,
    this.circle = false,
    this.placeholderIcon,
  });

  final ImageProvider? image;
  final double size;
  final String placeholderSeed;
  final BorderRadius? radius;
  final bool circle;
  final IconData? placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final px = (size * dpr).ceil();
    final provider = image;
    final placeholder = _Placeholder(
      seed: placeholderSeed,
      size: size,
      icon: placeholderIcon ?? KIcons.songs,
    );
    final Widget content = provider == null
        ? placeholder
        : Image(
            image: ResizeImage(
              provider,
              width: px,
              height: px,
              policy: ResizeImagePolicy.fit,
            ),
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => placeholder,
            frameBuilder: (context, child, frame, sync) {
              if (sync) return child;
              return Stack(
                fit: StackFit.passthrough,
                children: [
                  placeholder,
                  AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: KMotion.normal,
                    child: child,
                  ),
                ],
              );
            },
          );
    return circle
        ? ClipOval(child: content)
        : ClipRRect(borderRadius: radius ?? KRadius.sm, child: content);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.seed, required this.size, required this.icon});

  final String seed;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = KCoverPlaceholderColors.of(seed, Theme.of(context).brightness);
    final fill = colors.fill;
    final ink = colors.ink;
    return DecoratedBox(
      decoration: BoxDecoration(color: fill),
      child: SizedBox.square(
        dimension: size,
        child: Center(child: Icon(icon, size: size * 0.45, color: ink)),
      ),
    );
  }
}
