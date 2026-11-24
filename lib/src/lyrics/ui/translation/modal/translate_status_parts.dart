import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import 'translate_failure_labels.dart';

String _label(AppLocalizations l10n, TranslateAction action) =>
    switch (action) {
      TranslateAction.configure => l10n.lyricsTranslateConfigure,
      TranslateAction.retry => l10n.lyricsTranslateRetry,
      TranslateAction.changeService => l10n.lyricsTranslateChangeService,
      TranslateAction.choose => l10n.lyricsTranslateChoose,
      TranslateAction.cancel => l10n.lyricsTranslateCancel,
    };

/// A quiet line: [leading], text and an optional text button.
class TranslateQuietLine extends StatelessWidget {
  const TranslateQuietLine({
    super.key,
    required this.leading,
    required this.text,
    this.action,
    this.onAction,
  });

  final Widget leading;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(KSpace.x6, 0, KSpace.x4, KSpace.x1),
      child: Row(
        children: [
          leading,
          const KGap(KSpace.x3),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (action != null)
            KModalButton(
              label: action!,
              emphasis: KModalEmphasis.text,
              onPressed: onAction,
            ),
        ],
      ),
    );
  }
}

/// The failure strip: `errorContainer`, icon, bold title, one line and the
/// buttons. On the mobile shell two buttons go on their own row under the
/// text, right-aligned (the sheet is narrow).
class TranslateFailureStrip extends StatelessWidget {
  const TranslateFailureStrip({
    super.key,
    required this.text,
    required this.onAction,
  });

  final TranslateStatusText text;
  final void Function(TranslateAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    final stacked =
        text.actions.length > 1 && FormFactor.of(context) == FormFactor.mobile;
    final buttons = [
      for (var i = 0; i < text.actions.length; i++)
        KModalButton(
          label: _label(l10n, text.actions[i]),
          // The first button is the main one, the others stay text.
          emphasis: i == 0 && text.actions[i] != TranslateAction.configure
              ? KModalEmphasis.tonal
              : KModalEmphasis.text,
          onPressed: () => onAction(text.actions[i]),
        ),
    ];
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text.title,
          style: theme.titleSmall?.copyWith(
            color: scheme.onErrorContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (text.line != null)
          Text(
            text.line!,
            style: theme.bodySmall?.copyWith(color: scheme.onErrorContainer),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x2,
        KSpace.x2,
        KSpace.x2,
        KSpace.x1,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: scheme.errorContainer,
          shape: KShape.of(KRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KSpace.x4,
            vertical: KSpace.x3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(text.icon, size: KIconSize.md, color: scheme.error),
                  const KGap(KSpace.x3),
                  Expanded(child: words),
                  if (!stacked) ...[
                    const KGap(KSpace.x2),
                    Flexible(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        children: buttons,
                      ),
                    ),
                  ],
                ],
              ),
              if (stacked)
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(children: buttons),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
