import 'prompt_template.dart';

/// Stable keys of the builtin prompt templates. Their labels and texts are
/// l10n strings of the AI settings part, looked up by these keys; the engine
/// stores keys only. A key is never renamed or reused.
abstract final class BuiltinTemplateKeys {
  static const explainLyrics = 'explain_lyrics';
  static const similarSongs = 'similar_songs';
  static const moodPlaylist = 'mood_playlist';
  static const songStory = 'song_story';
  static const translateLyrics = 'translate_lyrics';
  static const tasteSummary = 'taste_summary';

  /// In display order.
  static const all = [
    explainLyrics,
    similarSongs,
    moodPlaylist,
    songStory,
    translateLyrics,
    tasteSummary,
  ];
}

/// The list a new install starts with: every builtin, on, unedited.
List<PromptTemplate> defaultPromptTemplates() => [
  for (final key in BuiltinTemplateKeys.all) PromptTemplate(key: key),
];
