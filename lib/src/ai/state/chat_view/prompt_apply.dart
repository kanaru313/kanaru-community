import 'package:flutter/widgets.dart' show TextEditingValue, TextSelection;

/// What tapping a prompt chip does.
sealed class PromptAction {
  const PromptAction();
}

/// The field is empty and the prompt has nothing to fill in: send [text] now.
final class PromptSendNow extends PromptAction {
  const PromptSendNow(this.text);

  final String text;
}

/// Put [value] in the field (the user finishes the message).
final class PromptFill extends PromptAction {
  const PromptFill(this.value);

  final TextEditingValue value;
}

final _input = RegExp(r'\{\{\s*input\s*\}\}');

/// The rules of a prompt chip tap: an empty field sends the prompt at once; a
/// field with text gets the prompt on top and its own text on the next line;
/// a prompt with `{{input}}` is only filled in, with that blank selected so
/// typing replaces it.
PromptAction applyPrompt(String body, TextEditingValue current) {
  final typed = current.text;
  final empty = typed.trim().isEmpty;
  final hasInput = _input.hasMatch(body);
  if (empty && !hasInput) return PromptSendNow(body);
  final text = empty ? body : '$body\n$typed';
  final blank = _input.firstMatch(text);
  return PromptFill(
    TextEditingValue(
      text: text,
      selection: blank == null
          ? TextSelection.collapsed(offset: text.length)
          : TextSelection(baseOffset: blank.start, extentOffset: blank.end),
    ),
  );
}
