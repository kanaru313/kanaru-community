import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/state/install_ops.dart';
import '../common/reason_box.dart';

/// "Xoá {tên}?": who wrote it and which version, then what goes. Pops true
/// on [Xoá]. Only what is true now is listed; nothing else is promised.
class RemovePluginDialog extends StatelessWidget {
  const RemovePluginDialog({super.key, required this.preview});

  final RemovePreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final author = preview.author.isEmpty
        ? l10n.pluginsAuthorUnknown
        : preview.author;
    return AlertDialog(
      title: Text(l10n.pluginsRemoveTitle(preview.name)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KSpace.x3,
          children: [
            Text(l10n.pluginsRemoveBy(author, preview.version)),
            ReasonBox(
              error: true,
              title: l10n.pluginsRemoveWillDelete,
              lines: [l10n.pluginsRemoveCode, l10n.pluginsRemoveSettings],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.pluginsCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.pluginsRemoveConfirm),
        ),
      ],
    );
  }
}
