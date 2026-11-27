import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../common/reason_box.dart';
import 'install_problem.dart';
import 'mismatch_dialog.dart';
import 'newer_app_dialog.dart';
import 'problem_texts.dart';

/// Shows the dialog for [problem]. True only when a mismatch dialog asked to
/// refresh the repository and try again.
Future<bool> showInstallProblem(
  BuildContext context,
  InstallProblem problem,
) async {
  final result = await showKDialog<bool>(
    context,
    builder: (_) => switch (problem.kind) {
      InstallProblemKind.invalid => InstallProblemDialog(problem: problem),
      InstallProblemKind.newerApp => NewerAppDialog(problem: problem),
      InstallProblemKind.mismatch => MismatchDialog(problem: problem),
    },
  );
  return result ?? false;
}

/// "Không cài được": the subject and the red box of reasons.
class InstallProblemDialog extends StatelessWidget {
  const InstallProblemDialog({super.key, required this.problem});

  final InstallProblem problem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final note = hasHostReason(problem);
    final imageNote = hasImageReason(problem);
    return AlertDialog(
      title: Text(l10n.pluginsProblemTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KSpace.x3,
          children: [
            Text(
              problem.subjectIsFile
                  ? l10n.pluginsProblemFileBody(problem.subject)
                  : l10n.pluginsProblemPluginBody(problem.subject),
            ),
            ReasonBox(
              error: true,
              title: l10n.pluginsProblemReasons,
              lines: [for (final r in problem.reasons) reasonText(l10n, r)],
            ),
            if (note)
              Text(
                l10n.pluginsProblemHostsNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (imageNote)
              Text(
                l10n.pluginsReasonAssetNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.pluginsPkgClose),
        ),
      ],
    );
  }
}
