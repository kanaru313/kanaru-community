import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../ai/domain/settings/builtin_templates.dart';
import '../../../../ai/domain/variables/variable_catalog.dart';

/// The text of a `{{name}}` variable as a user writes it in a prompt.
String variableToken(AiVariable variable) => '{{${variable.name}}}';

/// What a variable stands for ("Tên bài đang phát"): the description the
/// editor's insert chips and the variable help show.
String variableDescription(AppLocalizations l10n, AiVariable variable) =>
    switch (variable) {
      AiVariable.nowPlaying => l10n.aiSetVarNowPlaying,
      AiVariable.title => l10n.aiSetVarTitle,
      AiVariable.artist => l10n.aiSetVarArtist,
      AiVariable.album => l10n.aiSetVarAlbum,
      AiVariable.lyrics => l10n.aiSetVarLyrics,
      AiVariable.queue => l10n.aiSetVarQueue,
      AiVariable.input => l10n.aiSetVarInput,
    };

/// The label and text of a builtin prompt template.
typedef BuiltinTemplateText = ({String label, String body});

/// The label and body of the builtin template [key] (one of
/// [BuiltinTemplateKeys.all]); null for any other key, so a key the app does
/// not know is never shown as an empty prompt. Bodies carry the `{{variable}}`
/// text the user can edit.
BuiltinTemplateText? builtinTemplateText(AppLocalizations l10n, String key) {
  String v(AiVariable variable) => variableToken(variable);
  return switch (key) {
    BuiltinTemplateKeys.explainLyrics => (
      label: l10n.aiSetTemplateExplainLyricsLabel,
      body: l10n.aiSetTemplateExplainLyricsBody(
        v(AiVariable.lyrics),
        v(AiVariable.nowPlaying),
      ),
    ),
    BuiltinTemplateKeys.similarSongs => (
      label: l10n.aiSetTemplateSimilarSongsLabel,
      body: l10n.aiSetTemplateSimilarSongsBody(v(AiVariable.nowPlaying)),
    ),
    BuiltinTemplateKeys.moodPlaylist => (
      label: l10n.aiSetTemplateMoodPlaylistLabel,
      body: l10n.aiSetTemplateMoodPlaylistBody(v(AiVariable.input)),
    ),
    BuiltinTemplateKeys.songStory => (
      label: l10n.aiSetTemplateSongStoryLabel,
      body: l10n.aiSetTemplateSongStoryBody(v(AiVariable.nowPlaying)),
    ),
    BuiltinTemplateKeys.translateLyrics => (
      label: l10n.aiSetTemplateTranslateLyricsLabel,
      body: l10n.aiSetTemplateTranslateLyricsBody(
        v(AiVariable.lyrics),
        v(AiVariable.nowPlaying),
      ),
    ),
    BuiltinTemplateKeys.tasteSummary => (
      label: l10n.aiSetTemplateTasteSummaryLabel,
      body: l10n.aiSetTemplateTasteSummaryBody,
    ),
    _ => null,
  };
}
