import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';

/// "Xoá prompt": a block with a red outline and no fill, one destructive row.
/// A builtin adds the line that "Khôi phục prompt mặc định" brings it back.
class PromptDeleteBlock extends StatelessWidget {
  const PromptDeleteBlock({
    super.key,
    required this.builtin,
    required this.onDelete,
  });

  final bool builtin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: KRadius.lg,
        side: BorderSide(color: scheme.error.withValues(alpha: 0.3)),
      ),
      child: SetupRowFrame(
        leading: Icon(KIcons.delete, color: scheme.error),
        title: Text(l10n.aiSetEdDeleteRow),
        titleStyle: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: scheme.error),
        subtitle: builtin
            ? Text(l10n.aiSetEdDeleteBuiltinDesc(l10n.aiSetPromptRestore))
            : null,
        onTap: onDelete,
      ),
    );
  }
}
