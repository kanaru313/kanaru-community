import '../conversation/parts.dart';
import '../settings/tool_groups.dart';

/// Tells whether the user's Settings switch of a tool group is on.
typedef ToolGroupSwitches = bool Function(AiToolGroup group);

/// A `{{name}}` the user may write in a message or a saved prompt.
enum AiVariable {
  nowPlaying(
    'now_playing',
    DataSource.nowPlaying,
    AiToolGroup.nowPlaying,
    'aiVarNowPlaying',
  ),
  title('title', DataSource.track, AiToolGroup.nowPlaying, 'aiVarTitle'),
  artist('artist', DataSource.track, AiToolGroup.nowPlaying, 'aiVarArtist'),
  album('album', DataSource.track, AiToolGroup.nowPlaying, 'aiVarAlbum'),
  lyrics('lyrics', DataSource.lyrics, AiToolGroup.lyrics, 'aiVarLyrics'),
  queue('queue', DataSource.queue, AiToolGroup.queue, 'aiVarQueue'),

  /// Placeholder the user fills in by hand; the app never fills it.
  input('input', DataSource.input, null, 'aiVarInput');

  const AiVariable(this.name, this.source, this.group, this.l10nKey);

  /// The text between the braces.
  final String name;

  /// The contract `source` of the data part the value becomes.
  final DataSource source;

  /// The privacy group that must be on to fill it; null = none needed.
  final AiToolGroup? group;

  /// Key of the description string in the AI settings l10n part (this module
  /// holds the key only).
  final String l10nKey;

  static AiVariable? fromName(String name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

/// Every variable, in the order the settings page and the composer list them.
const List<AiVariable> variableCatalog = AiVariable.values;
