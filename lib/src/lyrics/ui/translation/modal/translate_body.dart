import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../state/translation/translation_providers.dart';
import '../../../state/translation/translation_services_provider.dart';
import '../../../state/translation/translation_settings.dart';
import 'translate_ai_tune_page.dart';
import 'translate_bottom_bar.dart';
import 'translate_frame.dart';
import 'translate_language_row.dart';
import 'translate_links.dart';
import 'translate_no_plugin_card.dart';
import 'translate_page_parts.dart';
import 'translate_phonetic_row.dart';
import 'translate_preview.dart';
import 'translate_retranslate.dart';
import 'translate_service_page.dart';
import 'translate_service_row.dart';
import 'translate_status_line.dart';
import 'translate_target_page.dart';

/// The content of "Dịch lời": header, preview, the translation row, the
/// service rows and status line (or the "no plugin" card) while translation
/// is on, "Phiên âm", and the bar with [Dịch lại] when there is work.
class TranslateBody extends ConsumerWidget {
  const TranslateBody({super.key, required this.control});

  final TranslateModalControl control;

  void _open(BuildContext context, WidgetBuilder page) =>
      unawaited(showTranslateFrame(context, control, page));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final on = ref.watch(translationOnProvider);
    final services = ref.watch(translateServicesProvider).value;
    // Asking for the translation is what the lyrics views do too; the modal
    // keeps it watched while it is open.
    ref.watch(
      trackTranslationProvider(control.trackId).select((v) => v.status),
    );
    void openService() =>
        _open(context, (_) => TranslateServicePage(control: control));
    void retranslate() => retranslateInBackground(context, control);
    final current = services?.current;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslatePageHeader(
          title: l10n.lyricsTranslateTitle,
          onClose: control.closeAll,
          onSettings: () => openTranslateSettings(context, ref, control),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TranslatePreview(
                  control: control,
                  canChoose: services != null && !services.none,
                  onRetranslate: retranslate,
                ),
                TranslateSectionTitle(l10n.lyricsTranslateSection),
                TranslateLanguageRow(
                  control: control,
                  onOpenTarget: () => _open(
                    context,
                    (_) => TranslateTargetPage(control: control),
                  ),
                ),
                if (on && services != null)
                  if (services.none)
                    TranslateNoPluginCard(
                      onOpenStore: () =>
                          openTranslateStore(context, ref, control),
                    )
                  else ...[
                    TranslateServiceRow(services: services, onTap: openService),
                    if (current != null && current.ai)
                      TranslateTuneRow(
                        service: current,
                        onTap: () => _open(
                          context,
                          (_) => TranslateAiTunePage(
                            control: control,
                            installId: current.installId,
                          ),
                        ),
                      ),
                    TranslateStatusLine(
                      control: control,
                      services: services,
                      onChooseService: openService,
                      onConfigure: (installId) =>
                          openTranslatePlugin(context, ref, control, installId),
                    ),
                  ],
                TranslatePhoneticRow(trackId: control.trackId),
                const KGap(KSpace.x2),
              ],
            ),
          ),
        ),
        if (on)
          TranslateBottomBar(
            control: control,
            service: current,
            onRetranslate: retranslate,
          ),
      ],
    );
  }
}
