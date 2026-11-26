import 'package:material_ui/material_ui.dart';

import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';

/// The supporting line of a [KTextFieldRow] that has a character counter or a
/// soft warning: the helper (or warning) text on the left, "n / max" on the
/// right, same line. It replaces the framework's helper slot, so an error
/// replaces all of it, counter included. The text wraps inside its own
/// space; the counter never wraps and the line never overflows at large text.
class KTextFieldFooter extends StatelessWidget {
  const KTextFieldFooter({
    super.key,
    required this.controller,
    required this.maxLength,
    this.helper,
    this.warning,
  });

  final TextEditingController controller;
  final int? maxLength;
  final String? helper;

  /// Soft note on its own tinted line under the helper / counter line.
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final scheme = Theme.of(context).colorScheme;
    final max = maxLength;
    final text = helper;
    final warn = warning;
    final line = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: text == null || text.isEmpty
              ? const SizedBox.shrink()
              : Text(
                  text,
                  style: style?.copyWith(color: scheme.onSurfaceVariant),
                ),
        ),
        if (max != null)
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final l10n = MaterialLocalizations.of(context);
              final n = controller.text.characters.length;
              return Padding(
                padding: const EdgeInsets.only(left: KSpace.x3),
                child: Text(
                  '${l10n.formatDecimal(n)} / ${l10n.formatDecimal(max)}',
                  style: style?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              );
            },
          ),
      ],
    );
    if (warn == null || warn.isEmpty) return line;
    // The soft warning has its own full-width line under helper and counter.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line,
        Padding(
          padding: const EdgeInsets.only(top: KSpace.x1),
          child: Semantics(
            container: true,
            liveRegion: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: KRadius.xs,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KSpace.x2,
                  vertical: KSpace.x1,
                ),
                child: Text(
                  warn,
                  style: style?.copyWith(color: scheme.onTertiaryContainer),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
