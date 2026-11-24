import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/translation/translation_status.dart';
import '../../../state/translation/translation_commands.dart';
import '../../../state/translation/translation_providers.dart';
import '../../../state/translation/translation_services_provider.dart';
import '../../lyrics_spinner.dart';
import '../../online/online_labels.dart' show formatClock;
import '../translation_language_name.dart';
import 'translate_failure_labels.dart';
import 'translate_frame.dart';
import 'translate_status_parts.dart';

/// The one line under the service rows that says what the translation is
/// doing: running (with "Huỷ" for a forced run), same language, or the failure
/// in `errorContainer` with its buttons. Nothing when there is nothing to say.
class TranslateStatusLine extends ConsumerWidget {
  const TranslateStatusLine({
    super.key,
    required this.control,
    required this.services,
    required this.onChooseService,
    required this.onConfigure,
  });

  final TranslateModalControl control;
  final TranslateServices services;

  /// "Đổi dịch vụ" / "Chọn": opens "Dịch vụ dịch".
  final VoidCallback onChooseService;

  /// "Cấu hình": opens the page of the chosen service.
  final void Function(String installId) onConfigure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = control.trackId;
    final view = ref.watch(trackTranslationProvider(id));
    final commands = ref.read(translationCommandsProvider);
    final service = services.current;
    String language(String code) => translationLanguageName(l10n, code);
    String serviceNamed(String? installId) =>
        services.all.where((s) => s.installId == installId).firstOrNull?.name ??
        service?.name ??
        '';

    if (service == null) {
      return TranslateFailureStrip(
        text: services.gone ? goneStatusText(l10n) : unsetStatusText(l10n),
        onAction: (_) => onChooseService(),
      );
    }
    void act(TranslateAction action) => switch (action) {
      TranslateAction.configure => onConfigure(service.installId),
      TranslateAction.retry => commands.retry(id),
      TranslateAction.changeService ||
      TranslateAction.choose => onChooseService(),
      TranslateAction.cancel => commands.cancelRetranslate(id),
    };
    switch (view.status) {
      case StatusLoading(:final background):
        final counted = view.linesTotal > 0;
        final text = background
            ? (counted
                  ? l10n.lyricsTranslateWorkingAgainCount(
                      view.linesDone,
                      view.linesTotal,
                    )
                  : l10n.lyricsTranslateWorkingAgain)
            : (counted
                  ? l10n.lyricsTranslateWorkingCount(
                      view.linesDone,
                      view.linesTotal,
                    )
                  : l10n.lyricsTranslateWorking);
        return TranslateQuietLine(
          leading: LyricsSpinner(
            size: KIconSize.sm,
            color: Theme.of(context).colorScheme.primary,
          ),
          text: text,
          action: background ? l10n.lyricsTranslateCancel : null,
          onAction: () => act(TranslateAction.cancel),
        );
      case StatusSame(:final lang):
        return TranslateQuietLine(
          leading: Icon(
            KIcons.select,
            size: KIconSize.sm,
            color: Theme.of(context).colorScheme.primary,
          ),
          text: l10n.lyricsTranslateSame(
            language(lang),
            serviceNamed(view.installId),
          ),
        );
      case StatusFailed(:final failure):
        final partial = view.linesTotal > 0 && view.map.isNotEmpty;
        final text = partial
            ? TranslateStatusText(
                icon: KIcons.offline,
                title: l10n.lyricsTranslatePartialTitle(
                  view.linesDone,
                  view.linesTotal,
                ),
                line: l10n.lyricsTranslatePartialLine(
                  failureReason(
                    l10n,
                    failure,
                    service: service.name,
                    language: language,
                  ),
                ),
                actions: const [TranslateAction.retry],
              )
            : failureStatusText(
                l10n,
                failure,
                service: service.name,
                language: language,
                clock: (time) => formatClock(context, time),
              );
        return TranslateFailureStrip(text: text, onAction: act);
      case StatusIdle() || StatusReady() || StatusOther():
        return const SizedBox.shrink();
    }
  }
}
