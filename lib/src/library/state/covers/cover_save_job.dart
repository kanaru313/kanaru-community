import 'dart:async';
import 'dart:io';

import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/covers/cover_choice.dart';
import '../custom_cover_providers.dart';
import 'cover_temp_files.dart';
import 'cover_texts.dart';

final _log = Logger('library.cover_save');

/// Saves one cover change and tells the user how it went. It does not belong
/// to the dialog's route: it holds the root messenger, the texts and the
/// temp files itself, so closing the dialog (drag, Back, Esc, scrim) never
/// cancels it and the snack bar still shows.
///
/// Success: a snack bar with "Undo"; undo takes the change back (a `false`
/// answer or an error shows "Couldn't undo"); when the snack bar closes
/// without Undo the change is released. Failure: a snack bar with the error
/// text, the old cover stays. The temp files are deleted when the job ends,
/// except after a failure while the dialog is still open ([dialogOpen]): the
/// user may retry with the same image, so the caller keeps them.
class CoverSaveJob {
  CoverSaveJob({
    required this.controller,
    required this.kind,
    required this.itemKey,
    required this.choice,
    required this.messenger,
    this.openMessenger = _noMessenger,
    required this.texts,
    this.ownedFiles = const [],
    this.dialogOpen = _closed,
  });

  final CustomCoverController controller;
  final CustomCoverKind kind;
  final String itemKey;

  /// Resolves what to save (it may need to read the image). Runs inside the
  /// job so its failures are reported like the import's.
  final Future<CoverChoice> Function() choice;

  /// The root messenger, captured before any await.
  final ScaffoldMessengerState messenger;

  /// The messenger inside the dialog: a failure while the dialog is open
  /// shows there (the root one would be drawn under the modal).
  final ScaffoldMessengerState? Function() openMessenger;
  final CoverTexts texts;

  /// Temp files the job deletes when it ends.
  final List<File> ownedFiles;

  /// True while the dialog that started the job is still on screen.
  final bool Function() dialogOpen;

  static bool _closed() => false;
  static ScaffoldMessengerState? _noMessenger() => null;

  /// Runs the save. Never throws. True when the cover was saved; false after
  /// a failure (already reported). When it returns false and [dialogOpen]
  /// was true, [ownedFiles] are still on disk and the caller owns them again.
  Future<bool> run() async {
    var keepFiles = false;
    try {
      final chosen = await choice();
      final change = await controller.changeCover(kind, itemKey, chosen);
      _showSaved(change, chosen is AutomaticCover);
      return true;
    } on Object catch (e, st) {
      if (e is! FormatException && e is! FileSystemException) {
        _log.warning('cover save failed', e, st);
      }
      keepFiles = dialogOpen();
      _show(texts.errorFor(e), on: keepFiles ? openMessenger() : null);
      return false;
    } finally {
      if (!keepFiles) await deleteTempFiles(ownedFiles);
    }
  }

  void _showSaved(CoverChange change, bool reset) {
    final shown = _show(
      reset ? texts.resetDone : texts.changed,
      actionLabel: texts.undo,
      onAction: () => unawaited(_undo(change)),
      onClosedWithoutAction: () => unawaited(_release(change)),
    );
    // No snack bar, so nothing will ever release the change: do it now.
    if (!shown) unawaited(_release(change));
  }

  Future<void> _undo(CoverChange change) async {
    try {
      if (await change.undo()) return;
    } on Object catch (e, st) {
      _log.warning('cover undo failed', e, st);
    }
    _show(texts.undoFailed);
  }

  Future<void> _release(CoverChange change) async {
    try {
      await change.release();
    } on Object catch (e, st) {
      _log.warning('cover release failed', e, st);
    }
  }

  bool _show(
    String message, {
    ScaffoldMessengerState? on,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onClosedWithoutAction,
  }) {
    try {
      showAppSnackBarOn(
        on ?? messenger,
        message,
        actionLabel: actionLabel,
        onAction: onAction,
        onClosedWithoutAction: onClosedWithoutAction,
      );
      return true;
    } on Object catch (e, st) {
      // The messenger is gone (app closing): nothing to show it on.
      _log.warning('cannot show cover snack bar', e, st);
      return false;
    }
  }
}
