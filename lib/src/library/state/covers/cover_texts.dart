import '../../../../l10n/gen/app_localizations.dart';

/// The words the cover save job and the dialog's errors use, so the job needs
/// no `BuildContext`: build it from the localizations while the context is
/// still alive.
class CoverTexts {
  const CoverTexts({
    required this.changed,
    required this.resetDone,
    required this.undo,
    required this.undoFailed,
    required this.errorFormat,
    required this.errorRead,
    this.linuxDialogLabel,
  });

  factory CoverTexts.of(AppLocalizations l10n) => CoverTexts(
    changed: l10n.coverChanged,
    resetDone: l10n.coverResetDone,
    undo: l10n.coverUndo,
    undoFailed: l10n.coverUndoFailed,
    errorFormat: l10n.coverErrorFormat,
    errorRead: l10n.coverErrorRead,
    linuxDialogLabel: l10n.coverLinuxDialogLabel,
  );

  final String changed;
  final String resetDone;
  final String undo;
  final String undoFailed;
  final String errorFormat;
  final String errorRead;

  /// Name of the image filter in the Linux file dialog.
  final String? linuxDialogLabel;

  /// Text for a failed pick, read or import: a [FormatException] means the
  /// image cannot be used; every other failure reads as a file problem.
  String errorFor(Object error) =>
      error is FormatException ? errorFormat : errorRead;
}
