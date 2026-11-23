import 'package:material_ui/material_ui.dart';

/// The lyrics area's one spinner: a ring of [size], a still arc instead of
/// the running one when animations are off. [label] is what a screen reader
/// says for it ("Đang tìm lời…") and what a test finds it by; without a label
/// the spinner is decoration next to text that already says it.
class LyricsSpinner extends StatelessWidget {
  const LyricsSpinner({
    super.key,
    required this.size,
    required this.color,
    this.label,
    this.strokeWidth = 2,
  });

  final double size;
  final Color color;
  final String? label;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final ring = SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        value: MediaQuery.disableAnimationsOf(context) ? 0.3 : null,
        color: color,
      ),
    );
    final text = label;
    return text == null
        ? ExcludeSemantics(child: ring)
        : Semantics(label: text, child: ring);
  }
}
