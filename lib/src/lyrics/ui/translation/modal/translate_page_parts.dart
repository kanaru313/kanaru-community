import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';

/// Header of a page of the modal: bold title, an optional ⚙ and the ✕.
/// [onClose] closes this page only (the modal's own page closes the modal).
class TranslatePageHeader extends StatelessWidget {
  const TranslatePageHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.onSettings,
    this.hint,
  });

  final String title;

  /// A note about the whole page, behind an ⓘ right after the title.
  final String? hint;
  final VoidCallback onClose;

  /// The ⚙ that opens Cài đặt › Lời bài; null leaves it out.
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x6,
        KSpace.x2,
        KSpace.x2,
        KSpace.x2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (hint != null)
                  KHelpIcon(
                    message: hint!,
                    tooltip: l10n.settingsSectionHintTooltip(title),
                    title: title,
                    closeLabel: l10n.lyricsModalClose,
                  ),
              ],
            ),
          ),
          if (onSettings != null)
            KIconButton(
              icon: KIcons.settings,
              tooltip: l10n.lyricsTranslateSettings,
              padding: const EdgeInsets.all(KSpace.x3),
              onPressed: onSettings,
            ),
          KIconButton(
            icon: KIcons.close,
            tooltip: l10n.lyricsModalClose,
            padding: const EdgeInsets.all(KSpace.x3),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

/// A section title of a page ("Bản dịch", "Áp dụng cho"): `primary`, bold.
class TranslateSectionTitle extends StatelessWidget {
  const TranslateSectionTitle(this.text, {super.key, this.count});

  final String text;

  /// How many entries follow (the "10" after "Model").
  final int? count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.titleSmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x6,
        KSpace.x3,
        KSpace.x6,
        KSpace.x1,
      ),
      child: Semantics(
        header: true,
        child: Text.rich(
          TextSpan(
            text: text,
            style: style?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
            children: [
              if (count != null)
                TextSpan(
                  text: '  $count',
                  style: style?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The visible caption under a title or a control: `bodySmall`, dim.
class TranslateCaption extends StatelessWidget {
  const TranslateCaption(
    this.text, {
    super.key,
    this.trailing,
    this.error = false,
  });

  final String text;

  /// Something that follows the text on the same line (the PRO tag).
  final Widget? trailing;

  /// Drawn in the error colour (a refused write).
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: error ? scheme.error : scheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x6,
        KSpace.x1 / 2,
        KSpace.x6,
        KSpace.x2,
      ),
      child: trailing == null
          ? Text(text, style: style)
          : Text.rich(
              TextSpan(
                text: '$text ',
                style: style,
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: trailing!,
                  ),
                ],
              ),
            ),
    );
  }
}
