import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import 'edit_playlist_fields.dart';
import 'playlist_dialog_actions.dart';
import 'playlist_form_model.dart';

final _log = Logger('library.playlists');

/// Centred dialog with one Name field, shared by Create and Duplicate: a
/// prefilled, fully selected name, a counter, validation on the cleaned
/// value, Enter submits, one submit at a time.
///
/// [submit] gets the cleaned name. Returning normally closes the dialog (the
/// caller keeps what it needs from the call); throwing keeps it open with a
/// "could not save" toast, so the user can retry. Esc, Back and the scrim
/// close it without submitting, except while a submit runs.
class PlaylistNameDialog extends StatefulWidget {
  const PlaylistNameDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    required this.initialName,
    required this.submit,
    this.extra,
  });

  final String title;
  final String confirmLabel;
  final String initialName;
  final Future<void> Function(String name) submit;

  /// Content under the name field (the duplicate dialog's cover switch).
  final Widget? extra;

  @override
  State<PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<PlaylistNameDialog> {
  late final PlaylistFormModel _form = PlaylistFormModel(
    name: widget.initialName,
  );
  bool _busy = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.valid.value) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).playlistSaveFailed;
    setState(() => _busy = true);
    try {
      await widget.submit(_form.cleanName);
    } on Object catch (error, stack) {
      _log.warning('Saving the "${widget.title}" dialog failed', error, stack);
      showAppSnackBarOn(messenger, failed);
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        scrollable: true,
        title: Text(widget.title),
        // Full width: the dialog sizes to its content, which would otherwise
        // shrink to the text field's intrinsic width.
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PlaylistNameField(
                controller: _form.nameController,
                autofocus: true,
                enabled: !_busy,
                onSubmitted: () => unawaited(_submit()),
              ),
              ?widget.extra,
            ],
          ),
        ),
        actions: playlistDialogActions(
          context,
          confirmLabel: widget.confirmLabel,
          enabled: _form.valid,
          busy: _busy,
          onConfirm: () => unawaited(_submit()),
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
