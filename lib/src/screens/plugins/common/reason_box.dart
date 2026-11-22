import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// A titled box with a bullet list inside a dialog: [error] tints it as a
/// reason or a loss (`errorContainer`), the plain one lists what stays.
class ReasonBox extends StatelessWidget {
  const ReasonBox({
    super.key,
    required this.title,
    required this.lines,
    this.error = false,
  });

  final String title;
  final List<String> lines;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = error ? scheme.onErrorContainer : scheme.onSurface;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: error ? scheme.errorContainer : scheme.surfaceContainerHigh,
          borderRadius: KRadius.sm,
        ),
        child: Padding(
          padding: const EdgeInsets.all(KSpace.x3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KSpace.x1,
            children: [
              Text(
                title,
                style: text.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              for (final line in lines)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: KSpace.x2,
                  children: [
                    Text('•', style: text.bodyMedium?.copyWith(color: color)),
                    Expanded(
                      child: Text(
                        line,
                        style: text.bodyMedium?.copyWith(color: color),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
