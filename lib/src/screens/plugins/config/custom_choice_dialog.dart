import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Longest name and note the store accepts (code points).
const _maxName = 200;
const _maxNote = 300;

/// The "Thêm model" box: a name (required) and a note, hints only. Resolves to
/// what the user typed, or null when they cancel.
Future<({String name, String? note})?> showAddChoiceDialog(
  BuildContext context,
) => showKDialog<({String name, String? note})>(
  context,
  builder: (context) => const _AddChoiceDialog(),
);

class _AddChoiceDialog extends StatefulWidget {
  const _AddChoiceDialog();

  @override
  State<_AddChoiceDialog> createState() => _AddChoiceDialogState();
}

class _AddChoiceDialogState extends State<_AddChoiceDialog> {
  final _name = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  bool get _canAdd => _name.text.trim().isNotEmpty;

  /// Keeps a box within its limit (a paste past it is cut).
  void _limit(TextEditingController box, int max) {
    if (box.text.runes.length > max) {
      final cut = String.fromCharCodes(box.text.runes.take(max));
      box.value = TextEditingValue(
        text: cut,
        selection: TextSelection.collapsed(offset: cut.length),
      );
    }
    setState(() {});
  }

  void _submit() {
    if (!_canAdd) return;
    final note = _note.text.trim();
    Navigator.of(context)
        .pop((name: _name.text.trim(), note: note.isEmpty ? null : note));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.pluginsCfgAddModelTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KTextFieldRow(
            controller: _name,
            hint: l10n.pluginsCfgModelNameHint,
            autofocus: true,
            onChanged: (_) => _limit(_name, _maxName),
            onSubmitted: (_) => _submit(),
          ),
          const KGap(KSpace.x3),
          KTextFieldRow(
            controller: _note,
            hint: l10n.pluginsCfgModelNoteHint,
            onChanged: (_) => _limit(_note, _maxNote),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.pluginsCancel),
        ),
        FilledButton(
          onPressed: _canAdd ? _submit : null,
          child: Text(l10n.pluginsCfgAddAndChoose),
        ),
      ],
    );
  }
}
