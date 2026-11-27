import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../plugins/domain/package/manifest_parser.dart';
import 'install_problem.dart';

/// "Cần Kanaru mới hơn": the plugin uses an API (or a type) this app does not
/// know. No box of reasons.
class NewerAppDialog extends StatelessWidget {
  const NewerAppDialog({super.key, required this.problem});

  final InstallProblem problem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final version = problem.apiVersion;
    return AlertDialog(
      title: Text(l10n.pluginsProblemNewerTitle),
      content: Text(
        problem.feature == lottieFeature
            ? l10n.pluginsProblemNewerBodyLottie(problem.subject)
            : version == null
            ? l10n.pluginsProblemNewerBody(problem.subject)
            : l10n.pluginsProblemNewerBodyVersion(
                problem.subject,
                '$version',
                supportedApiVersion,
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
