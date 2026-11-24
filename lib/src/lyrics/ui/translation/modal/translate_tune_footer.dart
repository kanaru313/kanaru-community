import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../plugins/data/store/plugin_config_store.dart'
    show ConfigWrite;

/// The line for a write the plugin store refused.
String configWriteMessage(AppLocalizations l10n, ConfigWrite result) =>
    switch (result) {
      ConfigWrite.written => '',
      ConfigWrite.unknownKey => l10n.lyricsTranslateWriteUnknown,
      ConfigWrite.invalidValue => l10n.lyricsTranslateWriteInvalid,
      ConfigWrite.tooLarge => l10n.lyricsTranslateWriteTooLarge,
      ConfigWrite.failed => l10n.lyricsTranslateWriteFailed,
    };

/// Footer of "Tinh chỉnh AI": [Để sau] [Dịch lại] when the settings differ
/// from the translation shown, else [Xong].
class TranslateTuneFooter extends StatelessWidget {
  const TranslateTuneFooter({
    super.key,
    required this.differ,
    required this.onLater,
    required this.onTranslate,
  });

  final bool differ;

  /// [Để sau] and [Xong]: close the page.
  final VoidCallback onLater;

  /// [Dịch lại].
  final VoidCallback onTranslate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KSpace.x5,
        vertical: KSpace.x2,
      ),
      // A wrap: two buttons with long labels do not fit a narrow sheet.
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: KSpace.x2,
        runSpacing: KSpace.x2,
        children: differ
            ? [
                KModalButton(
                  label: l10n.lyricsTranslateLater,
                  emphasis: KModalEmphasis.text,
                  onPressed: onLater,
                ),
                KModalButton(
                  label: l10n.lyricsTranslateRetranslate,
                  onPressed: onTranslate,
                ),
              ]
            : [
                KModalButton(
                  label: l10n.lyricsTranslateDone,
                  onPressed: onLater,
                ),
              ],
      ),
    );
  }
}
