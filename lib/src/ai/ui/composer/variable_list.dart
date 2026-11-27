import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/variables/variable_catalog.dart';

/// The variables the user can insert after typing `{{`, listed above the
/// field. [selected] is the row Enter would insert.
///
/// Each row shows the name and its one-line description.
class VariableList extends StatelessWidget {
  const VariableList({
    super.key,
    required this.items,
    required this.selected,
    required this.onChoose,
  });

  final List<AiVariable> items;
  final int selected;
  final ValueChanged<AiVariable> onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: l10n.aiChatVarListLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: KRadius.md,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KSpace.x1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KSpace.x3,
                  vertical: KSpace.x1,
                ),
                child: Text(
                  l10n.aiChatVarListTitle,
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (var i = 0; i < items.length; i++)
                _VariableRow(
                  variable: items[i],
                  selected: i == selected,
                  onTap: () => onChoose(items[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a variable stands for, in one line.
String variableDescription(AppLocalizations l10n, AiVariable v) => switch (v) {
  AiVariable.nowPlaying => l10n.aiChatVarDescNowPlaying,
  AiVariable.title => l10n.aiChatVarDescTitle,
  AiVariable.artist => l10n.aiChatVarDescArtist,
  AiVariable.album => l10n.aiChatVarDescAlbum,
  AiVariable.lyrics => l10n.aiChatVarDescLyrics,
  AiVariable.queue => l10n.aiChatVarDescQueue,
  // The prompts' blank is never offered for inserting by hand.
  AiVariable.input => '',
};

class _VariableRow extends StatelessWidget {
  const _VariableRow({
    required this.variable,
    required this.selected,
    required this.onTap,
  });

  final AiVariable variable;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final label = '{{${variable.name}}}';
    final description = variableDescription(l10n, variable);
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $description',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        // Taking focus would pull the cursor out of the field.
        canRequestFocus: false,
        child: ColoredBox(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: mobile ? 48 : 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: KSpace.x3),
              child: Row(
                children: [
                  Text(
                    label,
                    style: text.bodyMedium?.copyWith(
                      fontFamily: KFont.mono,
                      fontFamilyFallback: KFont.monoFallback,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: KSpace.x3),
                  Expanded(
                    child: Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
