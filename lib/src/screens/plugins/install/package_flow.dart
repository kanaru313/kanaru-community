import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../platform/domain/document_picker.dart';
import '../../../plugins/domain/install/prepare_result.dart';
import '../../../plugins/state/install_ops.dart';
import '../problems/install_problem_dialog.dart';
import 'package_controller.dart';
import 'package_exit.dart';
import 'plugin_package_screen.dart';

/// Opens the install / update screen over [start] and follows what it says:
/// a SnackBar when the plugin was written, the problem dialog when the
/// package cannot be installed (a mismatch can refresh the repository and run
/// the screen again). Nothing is written before the user presses the button.
Future<void> runPackageFlow(
  BuildContext context, {
  required InstallOps ops,
  required PrepareOperation Function() start,
  required PackageSubject subject,
  bool expectUpdate = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  var starter = start;
  while (true) {
    final exit = await _showPackageScreen(
      context,
      start: starter,
      subject: subject,
      expectUpdate: expectUpdate,
    );
    switch (exit) {
      case null:
        return;
      case PackageInstalled(:final name, :final version, :final updated):
        showAppSnackBarOn(
          messenger,
          updated
              ? l10n.pluginsPkgUpdated(name, version)
              : l10n.pluginsPkgInstalled(name),
        );
        return;
      case PackageRefused(:final problem):
        if (!context.mounted) return;
        final retry = await showInstallProblem(context, problem);
        final held = problem.held;
        if (!retry || held == null || !context.mounted) return;
        starter = () => ops.prepareAfterRefresh(held);
    }
  }
}

Future<PackageExit?> _showPackageScreen(
  BuildContext context, {
  required PrepareOperation Function() start,
  required PackageSubject subject,
  required bool expectUpdate,
}) {
  final full = FormFactor.of(context) == FormFactor.mobile;
  Widget screen() => PluginPackageScreen(
    start: start,
    subject: subject,
    fullScreen: full,
    expectUpdate: expectUpdate,
  );
  if (full) {
    return Navigator.of(context, rootNavigator: true).push<PackageExit>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => screen()),
    );
  }
  return showKDialog<PackageExit>(
    context,
    maxWidth: 600,
    builder: (_) => screen(),
  );
}

/// [Cài] of a not-installed row of a repository.
Future<void> installFromRepository(
  BuildContext context,
  InstallOps ops, {
  required String installId,
  required String name,
}) => runPackageFlow(
  context,
  ops: ops,
  start: () => ops.prepareInstall(installId),
  subject: PackageSubject(name),
);

/// [Xem] of an update row: the update screen for the new version.
Future<void> reviewPluginUpdate(
  BuildContext context,
  InstallOps ops, {
  required String installId,
  required String name,
}) => runPackageFlow(
  context,
  ops: ops,
  start: () => ops.prepareUpdate(installId),
  subject: PackageSubject(name),
  expectUpdate: true,
);

const _zipFilter = DocumentFilter(
  label: 'Plugin (.zip)',
  extensions: ['zip'],
  mimeTypes: ['application/zip', 'application/x-zip-compressed'],
);

/// "Cài từ tệp…": the system file dialog, then the screen for the picked
/// `.zip` (the file is read there: at most 5 MiB, 10 s).
Future<void> installFromFile(
  BuildContext context,
  InstallOps ops,
  DocumentPicker picker,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final PickedDocument? doc;
  try {
    doc = await picker.openDocument(_zipFilter);
  } on DocumentPickerException {
    showAppSnackBarOn(messenger, l10n.pluginsPkgFilePickerFailed);
    return;
  }
  if (doc == null || !context.mounted) return;
  final picked = doc;
  await runPackageFlow(
    context,
    ops: ops,
    start: () => ops.prepareFile(picked),
    subject: PackageSubject(picked.name, isFile: true, named: false),
  );
}
