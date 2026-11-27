import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../ai/domain/variables/template_analysis.dart';
import '../../state/ai_prompt_preview.dart';
import 'ai_catalog_labels.dart';
import 'prompt_editor_text.dart';

/// "Xem trước": the prompt with each variable replaced by its sample value
/// (the song Blinding Lights, never the playing song). A value is tinted `primary`
/// with a dotted underline, `{{input}}` is dashed (the place the user types),
/// a variable of a tool group that is off is yellow, an unknown one is red
/// with a wavy underline.
class PromptPreview extends StatelessWidget {
  const PromptPreview({super.key, required this.body, required this.analysis});

  final String body;
  final TemplateAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final base = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(color: scheme.onSurface);
    final Widget content;
    if (body.trim().isEmpty) {
      content = Text(
        l10n.aiSetEdPreviewEmpty,
        style: base?.copyWith(color: scheme.onSurfaceVariant),
      );
    } else {
      final segments = buildPreview(
        body,
        analysis,
        (v) => promptSampleText(l10n, v),
      );
      content = Text.rich(
        TextSpan(
          style: base,
          children: [for (final s in segments) _span(l10n, scheme, s)],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x4,
        KSpace.x3,
        KSpace.x4,
        KSpace.x4,
      ),
      child: Semantics(liveRegion: true, child: content),
    );
  }

  InlineSpan _span(
    AppLocalizations l10n,
    ColorScheme scheme,
    PreviewSegment s,
  ) {
    final variable = s.variable;
    switch (s.kind) {
      case PreviewKind.text:
        return TextSpan(text: s.text);
      case PreviewKind.value:
        return TextSpan(
          text: s.text,
          style: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.w500,
            backgroundColor: scheme.primary.withValues(alpha: 0.14),
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: scheme.primary,
          ),
        );
      case PreviewKind.input:
        return TextSpan(
          text: s.text,
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dashed,
            decorationColor: scheme.outline,
          ),
        );
      case PreviewKind.off:
        return TextSpan(
          text: s.text,
          semanticsLabel: l10n.aiSetEdPreviewOff(
            variableToken(variable!),
            promptToolGroupName(l10n, variable.group!),
          ),
          style: TextStyle(
            color: scheme.onTertiaryContainer,
            backgroundColor: scheme.tertiaryContainer,
          ),
        );
      case PreviewKind.unknown:
        return TextSpan(
          text: s.text,
          semanticsLabel: l10n.aiSetEdPreviewUnknown,
          style: TextStyle(
            color: scheme.error,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.wavy,
            decorationColor: scheme.error,
          ),
        );
    }
  }
}
