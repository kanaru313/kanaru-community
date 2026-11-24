import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../state/translation/translation_commands.dart';
import '../../../state/translation/translation_services_provider.dart';
import 'translate_frame.dart';
import 'translate_links.dart';
import 'translate_page_parts.dart';
import 'translate_scope_segmented.dart';
import 'translate_service_row.dart';

/// "Dịch vụ dịch": what is sent (behind the ⓘ of the title), "Áp dụng cho", the
/// installed translate plugins as icon rows (one choice, tint only) and
/// "Tải thêm tiện ích dịch". Choosing a service closes the page.
class TranslateServicePage extends ConsumerWidget {
  const TranslateServicePage({super.key, required this.control});

  final TranslateModalControl control;

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    TranslateService service,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).lyricsTranslateWriteFailed;
    try {
      await ref.read(translationCommandsProvider).setService(service.installId);
    } on Object {
      // The choice was not saved: the page stays so the user can try again.
      messenger.showSnackBar(SnackBar(content: Text(failed)));
      return;
    }
    if (navigator.mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final services = ref.watch(translateServicesProvider).value;
    final current = services?.current;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TranslatePageHeader(
          title: l10n.lyricsTranslateServicePageTitle,
          hint: l10n.lyricsTranslateServiceSent,
          onClose: () => Navigator.of(context).pop(),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TranslateScopeSegmented(),
                TranslateSectionTitle(l10n.lyricsTranslateServiceSection),
                for (final service
                    in services?.all ?? const <TranslateService>[])
                  SelectionRow(
                    leading: TranslateServiceIcon(service: service),
                    title: TranslateServiceName(
                      service,
                      selected: service.installId == current?.installId,
                    ),
                    selected: service.installId == current?.installId,
                    onTap: () => _pick(context, ref, service),
                  ),
                KListRow(
                  leading: const Icon(KIcons.add),
                  title: Text(l10n.lyricsTranslateMoreServices),
                  subtitle: Text(l10n.lyricsTranslateMoreServicesSub),
                  onTap: () => openTranslateStore(context, ref, control),
                ),
                const KGap(KSpace.x2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
