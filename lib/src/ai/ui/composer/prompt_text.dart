import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/settings/prompt_template.dart';
import '../ai_builtin_texts.dart';

/// A prompt chip's label and the text it puts in the message.
typedef ResolvedPrompt = ({String label, String body});

/// The words of [template]: its own when the user wrote or edited it, else
/// the built-in text for its key. Null for a key this build does not know.
ResolvedPrompt? resolvePrompt(AppLocalizations l10n, PromptTemplate template) {
  final label = template.label;
  final body = template.body;
  if (label != null && body != null) return (label: label, body: body);
  final key = template.key;
  return key == null ? null : builtinTemplateText(l10n, key);
}
