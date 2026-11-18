import 'package:flutter/services.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/playlists/playlist_text_rules.dart';

/// Asks for the name of a playlist that is only created when the picker's
/// confirm button runs. Resolves to the cleaned name, or null on Cancel, Esc,
/// Back or a tap outside. [initialName] is prefilled and fully selected.
Future<String?> showPendingPlaylistNameDialog(
  BuildContext context, {
  required String initialName,
}) => showKDialog<String>(
  context,
  builder: (_) => _PendingNameDialog(initialName: initialName),
);

class _PendingNameDialog extends StatefulWidget {
  const _PendingNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_PendingNameDialog> createState() => _PendingNameDialogState();
}

class _PendingNameDialogState extends State<_PendingNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initialName.length,
        );

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  PlaylistNameProblem? get _problem => checkPlaylistName(_controller.text);

  void _submit() {
    if (_problem != null) return;
    Navigator.of(context).pop(cleanPlaylistName(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final problem = _problem;
    final error = switch (problem) {
      PlaylistNameProblem.empty => l10n.playlistNameEmpty,
      PlaylistNameProblem.tooLong => l10n.playlistNameTooLong,
      null => null,
    };
    return AlertDialog(
      title: Text(l10n.playlistCreateTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              inputFormatters: [
                // Control characters never reach the field.
                FilteringTextInputFormatter.deny(RegExp(r'[\x00-\x1F\x7F]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.playlistNameLabel,
                errorText: error,
                counterText:
                    '${graphemeLength(_controller.text)} / $playlistNameMaxLength',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.playlistCancel),
        ),
        FilledButton(
          onPressed: problem == null ? _submit : null,
          child: Text(l10n.playlistPickerNewConfirm),
        ),
      ],
    );
  }
}
