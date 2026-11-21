import 'package:flutter/services.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_ranges.dart';

/// Asks for the number of songs the list shows ("Số bài xếp hạng"). Resolves
/// to a number from 1 to 1000, or null when the dialog was dismissed (Huỷ,
/// Esc, Back, a tap outside).
Future<int?> showMostPlayedLimitDialog(
  BuildContext context, {
  required int initial,
}) => showKDialog<int>(
  context,
  builder: (_) => MostPlayedLimitDialog(initial: initial),
);

/// The number dialog: one numeric field (digits only, at most four) with the
/// range as helper text, which an out-of-range number replaces with an error
/// in place. Lưu is off until the number is valid (an empty field shows no
/// error); Enter saves a valid one.
class MostPlayedLimitDialog extends StatefulWidget {
  const MostPlayedLimitDialog({super.key, required this.initial});

  final int initial;

  @override
  State<MostPlayedLimitDialog> createState() => _MostPlayedLimitDialogState();
}

class _MostPlayedLimitDialogState extends State<MostPlayedLimitDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.initial}')
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: '${widget.initial}'.length,
        );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// A held or repeated Enter must not pop twice (the second pop would close
  /// the page under the dialog).
  bool _saved = false;

  void _save() {
    if (_saved) return;
    if (checkMostPlayedLimitText(_controller.text) !=
        MostPlayedLimitInput.valid) {
      return;
    }
    _saved = true;
    Navigator.of(context).pop(int.parse(_controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.historyMostPlayedLimitTitle),
      content: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) {
          final input = checkMostPlayedLimitText(value.text);
          return TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: l10n.historyMostPlayedLimitField,
              // The error takes the helper's place, so the field never grows.
              helperText: l10n.historyMostPlayedLimitHint,
              errorText: input == MostPlayedLimitInput.outOfRange
                  ? l10n.historyMostPlayedLimitError
                  : null,
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => FilledButton(
            onPressed:
                checkMostPlayedLimitText(value.text) ==
                    MostPlayedLimitInput.valid
                ? _save
                : null,
            child: Text(l10n.historyRangeSave),
          ),
        ),
      ],
    );
  }
}
