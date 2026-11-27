import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';

/// The sticky footer of the editor: [Huỷ] [Lưu], right aligned, as wide as the
/// page content. [onSave] null dims Lưu.
class PromptEditorFooter extends StatelessWidget {
  const PromptEditorFooter({
    super.key,
    required this.onCancel,
    required this.onSave,
  });

  final VoidCallback onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final gutter = desktop ? KLayout.gutterDesktop : KLayout.gutterMobile;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: KLayout.settings),
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, KSpace.x3, gutter, KSpace.x4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 96),
                  child: KModalButton(
                    label: l10n.aiSetEdCancel,
                    emphasis: KModalEmphasis.text,
                    onPressed: onCancel,
                  ),
                ),
                const KGap(KSpace.x2),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 96),
                  child: KModalButton(
                    label: l10n.aiSetEdSave,
                    onPressed: onSave,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
