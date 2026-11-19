import 'package:material_ui/material_ui.dart';

/// The Kanaru app icon (dark squircle, white stem, coral wedge) in fixed
/// colours, so it is never theme-tinted (a tinted one-colour glyph looked
/// poor). Mirrors the scalable app icon
/// `packaging/linux/icons/hicolor/scalable/apps/io.github.kanaru313.kanaru_community.svg`
/// (viewBox 128); change both together (`packaging/branding/README.md`).
class KanaruLogo extends StatelessWidget {
  const KanaruLogo({super.key, required this.size, this.semanticLabel});

  /// Side of the square. Pass a token (`KIconSize`, `KSpace`).
  final double size;

  /// Announced to screen readers; the logo is decorative (excluded) when null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final logo = SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: KanaruLogoPainter()),
    );
    final label = semanticLabel;
    return label == null
        ? ExcludeSemantics(child: logo)
        : Semantics(label: label, image: true, child: logo);
  }
}

/// Fixed logo colours (`packaging/branding/README.md`).
@visibleForTesting
abstract final class KanaruLogoColors {
  static const background = Color(0xFF1B1F2A);
  static const stem = Color(0xFFFFFFFF);
  static const wedge = Color(0xFFFFB4A2);
}

/// Side of the icon's source viewBox.
const _viewBox = 128.0;

/// Squircle background for a [size] square.
@visibleForTesting
Path kanaruLogoBackground(double size) => _scaled(
  Path()..addRRect(
    RRect.fromLTRBR(0, 0, _viewBox, _viewBox, const Radius.circular(30)),
  ),
  size,
);

/// White stem for a [size] square.
@visibleForTesting
Path kanaruLogoStem(double size) => _scaled(
  Path()..addRRect(RRect.fromLTRBR(30, 28, 46, 100, const Radius.circular(8))),
  size,
);

/// Rounded wedge for a [size] square.
@visibleForTesting
Path kanaruLogoWedge(double size) {
  const corner = Radius.circular(6);
  return _scaled(
    Path()
      ..moveTo(52.441, 59.169)
      ..lineTo(90.441, 31.169)
      ..arcToPoint(const Offset(100, 36), radius: corner)
      ..lineTo(100, 92)
      ..arcToPoint(const Offset(90.441, 96.831), radius: corner)
      ..lineTo(52.441, 68.831)
      ..arcToPoint(const Offset(52.441, 59.169), radius: corner)
      ..close(),
    size,
  );
}

Path _scaled(Path path, double size) {
  final scale = size / _viewBox;
  return path.transform(
    (Matrix4.identity()..scaleByDouble(scale, scale, 1, 1)).storage,
  );
}

/// Paints the icon scaled to the shortest side. Paths and paints are built
/// once in viewBox space and reused; each paint only scales the canvas.
@visibleForTesting
class KanaruLogoPainter extends CustomPainter {
  const KanaruLogoPainter();

  static final _background = kanaruLogoBackground(_viewBox);
  static final _stem = kanaruLogoStem(_viewBox);
  static final _wedge = kanaruLogoWedge(_viewBox);
  static final _backgroundPaint = Paint()..color = KanaruLogoColors.background;
  static final _stemPaint = Paint()..color = KanaruLogoColors.stem;
  static final _wedgePaint = Paint()..color = KanaruLogoColors.wedge;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _viewBox;
    canvas
      ..save()
      ..scale(scale)
      ..drawPath(_background, _backgroundPaint)
      ..drawPath(_stem, _stemPaint)
      ..drawPath(_wedge, _wedgePaint)
      ..restore();
  }

  @override
  bool shouldRepaint(KanaruLogoPainter oldDelegate) => false;
}
