import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/translation/translation_status.dart';
import '../../../state/translation/translation_providers.dart';
import '../../../state/translation/translation_services_provider.dart';
import '../../../state/translation/translation_tune_provider.dart';
import 'translate_frame.dart';

/// The bar under the pages, only when there is work: the saved translation is
/// another plugin's ("Bản có sẵn của …" · "Dịch lại bằng …"), or the plugin's
/// settings differ from the ones it was made with. [Dịch lại] runs in the
/// background.
class TranslateBottomBar extends ConsumerWidget {
  const TranslateBottomBar({
    super.key,
    required this.control,
    required this.service,
    required this.onRetranslate,
  });

  final TranslateModalControl control;

  /// The chosen service; without one nothing can be translated again.
  final TranslateService? service;
  final VoidCallback onRetranslate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chosen = service;
    if (chosen == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(trackTranslationProvider(control.trackId));
    final status = view.status;
    final String title;
    final String line;
    if (status is StatusOther) {
      final services = ref.watch(translateServicesProvider).value;
      final other = services?.all
          .where((s) => s.installId == status.installId)
          .firstOrNull;
      if (other == null) return const SizedBox.shrink();
      title = l10n.lyricsTranslationCreditOther(other.name);
      line = l10n.lyricsTranslateBarOtherLine(chosen.name);
    } else if (status is StatusReady && view.settingsDiffer) {
      final tune = ref.watch(translateTuneProvider(chosen.installId)).value;
      if (tune == null) return const SizedBox.shrink();
      final diff = translateSettingsDiff(view.settingsJson, tune);
      title = l10n.lyricsTranslateBarDiffTitle;
      line = [
        if (diff.model case (final from, final to)) '$from → $to',
        if (diff.style case (final from, final to)) '$from → $to',
        if (diff.note) l10n.lyricsTranslateDiffNote,
        if (diff.version) l10n.lyricsTranslateDiffVersion,
      ].join(', ');
    } else {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          KSpace.x6,
          KSpace.x3,
          KSpace.x4,
          KSpace.x4,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (line.isNotEmpty)
                    Text(
                      line,
                      style: theme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const KGap(KSpace.x2),
            KModalButton(
              label: l10n.lyricsTranslateRetranslate,
              onPressed: onRetranslate,
            ),
          ],
        ),
      ),
    );
  }
}
