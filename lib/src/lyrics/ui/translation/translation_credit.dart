import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../state/translation/translation_credit_provider.dart';
import 'translation_language_name.dart';

/// The line after the lyrics: who translated them and into what language
/// ("Dịch bởi plugin · model · phong cách · ngôn ngữ"), "Bản có sẵn của
/// plugin" for a translation another plugin saved, and the count of lines
/// done for a run that stopped half way. Nothing while no translation is
/// shown. Watching it asks for the translation like any lyrics view.
class TranslationCreditLine extends ConsumerWidget {
  const TranslationCreditLine({
    super.key,
    required this.trackId,
    required this.centered,
  });

  final TrackId trackId;
  final bool centered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credit = ref.watch(translationCreditProvider(trackId));
    if (credit == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final language = translationLanguageName(l10n, credit.target);
    final by = [credit.plugin, credit.model, credit.style].nonNulls.join(' · ');
    final text = credit.other
        ? l10n.lyricsTranslationCreditOther(credit.plugin)
        : credit.partial
        ? l10n.lyricsTranslationCreditPartial(
            by,
            language,
            credit.linesDone,
            credit.linesTotal,
          )
        : l10n.lyricsTranslationCredit(by, language);
    return Padding(
      padding: const EdgeInsets.only(top: KSpace.x4),
      child: Text(
        text,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
