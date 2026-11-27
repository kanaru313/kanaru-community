import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// "Xoá tất cả cuộc trò chuyện?": [body] says what goes, [undo] sits in its
/// own paragraph below it. Pops true on [confirm], false on Cancel. Scrolls
/// instead of overflowing at a large text scale.
class AiClearHistoryDialog extends StatelessWidget {
  const AiClearHistoryDialog({
    super.key,
    required this.title,
    required this.body,
    required this.undo,
    required this.confirm,
  });

  final String title;
  final String body;
  final String undo;
  final String confirm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      scrollable: true,
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(body), const KGap(KSpace.x3), Text(undo)],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirm),
        ),
      ],
    );
  }
}
