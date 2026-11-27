import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/settings/builtin_templates.dart';
import '../../domain/settings/prompt_template.dart';
import '../../domain/variables/variable_catalog.dart';

final _np = '{{${AiVariable.nowPlaying.name}}}';
final _lyrics = '{{${AiVariable.lyrics.name}}}';
final _input = '{{${AiVariable.input.name}}}';

/// A prompt chip's label and the text it puts in the message.
typedef ResolvedPrompt = ({String label, String body});

/// The words of [template]: its own when the user wrote or edited it, else
/// the built-in text for its key. Null for a key this build does not know.
///
/// The built-in strings are the chat's own copy until the AI settings strings
/// land; both read the same stable keys.
ResolvedPrompt? resolvePrompt(AppLocalizations l10n, PromptTemplate template) {
  final label = template.label;
  final body = template.body;
  if (label != null && body != null) return (label: label, body: body);
  return switch (template.key) {
    BuiltinTemplateKeys.explainLyrics => (
      label: l10n.aiChatPromptExplainLyricsLabel,
      body: l10n.aiChatPromptExplainLyricsBody(_np, _lyrics),
    ),
    BuiltinTemplateKeys.similarSongs => (
      label: l10n.aiChatPromptSimilarSongsLabel,
      body: l10n.aiChatPromptSimilarSongsBody(_np),
    ),
    BuiltinTemplateKeys.moodPlaylist => (
      label: l10n.aiChatPromptMoodPlaylistLabel,
      body: l10n.aiChatPromptMoodPlaylistBody(_input),
    ),
    BuiltinTemplateKeys.songStory => (
      label: l10n.aiChatPromptSongStoryLabel,
      body: l10n.aiChatPromptSongStoryBody(_np),
    ),
    BuiltinTemplateKeys.translateLyrics => (
      label: l10n.aiChatPromptTranslateLyricsLabel,
      body: l10n.aiChatPromptTranslateLyricsBody(_np, _lyrics),
    ),
    BuiltinTemplateKeys.tasteSummary => (
      label: l10n.aiChatPromptTasteSummaryLabel,
      body: l10n.aiChatPromptTasteSummaryBody,
    ),
    _ => null,
  };
}
