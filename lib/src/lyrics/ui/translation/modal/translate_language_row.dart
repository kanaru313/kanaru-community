import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/translation/translation_language.dart';
import '../../../domain/translation/translation_status.dart';
import '../../../state/translation/translation_commands.dart';
import '../../../state/translation/translation_providers.dart';
import '../../../state/translation/translation_settings.dart';
import '../translation_language_name.dart';
import 'translate_frame.dart';

/// The name of the language the plugin saw in the lyrics (a code such as
/// `ja`, `zh-CN`, `en-US`) in the app language.
String detectedLanguageName(AppLocalizations l10n, String code) {
  final exact = translationLanguageName(l10n, code);
  if (exact != code) return exact;
  final base = baseLanguage(code);
  // The plugins say `zh`; the app names the two scripts, simplified first.
  return translationLanguageName(l10n, base == 'zh' ? 'zh-Hans' : base);
}

/// `[<ngôn ngữ> · tự nhận] [switch] [<đích> ▾]`: the source language is a
/// read-only label (auto-detect), the switch turns translation on or off for
/// every song, the target opens "Dịch sang".
class TranslateLanguageRow extends ConsumerWidget {
  const TranslateLanguageRow({
    super.key,
    required this.control,
    required this.onOpenTarget,
  });

  final TranslateModalControl control;
  final VoidCallback onOpenTarget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final id = control.trackId;
    final on = ref.watch(translationOnProvider);
    final target = ref.watch(effectiveTranslationTargetProvider(id));
    final detected = ref.watch(
      trackTranslationProvider(id).select((v) {
        final s = v.status;
        final known =
            s is StatusReady ||
            s is StatusOther ||
            s is StatusSame ||
            (s is StatusFailed && v.map.isNotEmpty) ||
            (s is StatusLoading && s.background);
        return known ? v.sourceLang : null;
      }),
    );
    final label = detected == null
        ? l10n.lyricsTranslateSourceAuto
        : l10n.lyricsTranslateSourceDetected(
            detectedLanguageName(l10n, detected),
          );
    final targetName = translationLanguageName(l10n, target);
    final text = Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KSpace.x4,
        vertical: KSpace.x1,
      ),
      child: Row(
        children: [
          Expanded(
            child: Tooltip(
              message: l10n.lyricsTranslateSourceHint,
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: text?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          const KGap(KSpace.x2),
          KSwitch(
            value: on,
            semanticLabel: l10n.lyricsTranslateSwitch,
            onChanged: (_) => ref.read(translationCommandsProvider).toggle(),
          ),
          const KGap(KSpace.x2),
          Expanded(
            child: Semantics(
              label: l10n.lyricsTranslateTarget(targetName),
              excludeSemantics: true,
              button: true,
              child: TextButton(
                onPressed: onOpenTarget,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        targetName,
                        overflow: TextOverflow.ellipsis,
                        style: text,
                      ),
                    ),
                    const KGap(KSpace.x1),
                    Icon(
                      KIcons.collapse,
                      size: KIconSize.sm,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
