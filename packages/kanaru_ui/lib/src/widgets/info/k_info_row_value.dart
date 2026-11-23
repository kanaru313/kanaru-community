import 'package:material_ui/material_ui.dart';

import '../../tokens/k_space.dart';

/// The value part of a `KInfoRow`: [valueWidget] as is (links), else [shown]
/// (selectable on the desktop shell; in `error`, struck through when
/// [missing]), else [unknownText] in italic `onSurfaceVariant`.
Widget buildInfoRowValue(
  BuildContext context, {
  required Widget? valueWidget,
  required String? shown,
  required String? unknownText,
  required bool missing,
  required bool selectable,
}) {
  if (valueWidget != null) return valueWidget;
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  var style = theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500);
  if (missing) {
    style = style?.copyWith(
      color: scheme.error,
      decoration: TextDecoration.lineThrough,
    );
  }
  if (shown != null) {
    return selectable
        ? SelectableText(shown, style: style)
        : Text(shown, style: style);
  }
  return Text(
    unknownText!,
    style: style?.copyWith(
      fontStyle: FontStyle.italic,
      color: scheme.onSurfaceVariant,
    ),
  );
}

/// Label and [value] side by side (label column [labelWidth]) or, when
/// [stacked] (200 % text), the label above the value.
Widget buildInfoRowContent(
  BuildContext context, {
  required String label,
  required Widget value,
  required bool stacked,
  required double labelWidth,
}) {
  final theme = Theme.of(context);
  final text = Text(
    label,
    style: theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
  if (stacked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        text,
        const SizedBox(height: KSpace.x1),
        value,
      ],
    );
  }
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: labelWidth, child: text),
      const SizedBox(width: KSpace.x3),
      Expanded(child: value),
    ],
  );
}
