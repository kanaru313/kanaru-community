import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// The title of a group field (chips, list, table): `titleSmall`, a red `*`
/// when required, and its note under it. 14 dp before the content.
class FieldHeading extends StatelessWidget {
  const FieldHeading({
    super.key,
    required this.title,
    required this.required,
    this.subtitle,
    this.gap = KSpace.x3 + 2,
  });

  final String title;
  final bool required;
  final String? subtitle;

  /// Space between the heading and the content under it.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: title,
            children: [
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: scheme.error),
                ),
            ],
          ),
          style: theme.textTheme.titleSmall,
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: KSpace.x1),
            child: Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        SizedBox(height: gap),
      ],
    );
  }
}

/// A line of text under a field in the error colour.
class FieldErrorLine extends StatelessWidget {
  const FieldErrorLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: KSpace.x1),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
