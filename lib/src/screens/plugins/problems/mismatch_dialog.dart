import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../common/reason_box.dart';
import 'install_problem.dart';
import 'problem_texts.dart';

/// "Gói không khớp danh sách": the differences, why it usually happens, and
/// [Làm mới rồi thử lại] (pops true).
class MismatchDialog extends StatelessWidget {
  const MismatchDialog({super.key, required this.problem});

  final InstallProblem problem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = problem.repoLabel;
    return AlertDialog(
      title: Text(l10n.pluginsMismatchTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KSpace.x3,
          children: [
            if (repo != null)
              Text(l10n.pluginsMismatchBody(problem.subject, repo))
            else
              Text(problem.subject),
            ReasonBox(
              error: true,
              title: l10n.pluginsMismatchDiffs,
              lines: [for (final r in problem.reasons) reasonText(l10n, r)],
            ),
            Text(l10n.pluginsMismatchHint),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.pluginsPkgClose),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.pluginsMismatchRetry),
        ),
      ],
    );
  }
}
