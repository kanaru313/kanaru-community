import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// One value line of a [DetailsInfoRow]. [soft] is the quieter line under a
/// value (a sentence, an address); [mono] the monospace of an address.
class DetailLine {
  const DetailLine(this.text, {this.mono = false, this.soft = false});

  final String text;
  final bool mono;
  final bool soft;
}

/// A small label over its value lines, which can be selected and copied, and
/// a divider under it that starts 16 dp in.
class DetailsInfoRow extends StatelessWidget {
  const DetailsInfoRow({
    super.key,
    required this.label,
    required this.lines,
    this.mono = false,
  });

  final String label;
  final List<DetailLine> lines;

  /// Every line in monospace (the hosts).
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KSpace.x4,
          vertical: KSpace.x3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            for (final line in lines)
              SelectableText(
                line.text,
                style: (line.soft ? text.bodySmall : text.bodyMedium)?.copyWith(
                  color: line.soft ? scheme.onSurfaceVariant : null,
                  fontFamily: line.mono || mono ? 'monospace' : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
