import '../extension/kanaru_extension.dart';
import '../extension/state/extension_registry.dart';
import '../extension/state/registry_entries.dart';
import 'ui/song_info/song_info_lyrics_section.dart';

/// The lyrics module's entries in the app's extension points: today only the
/// "Lời bài hát" group of the song info page, which `library` cannot import.
class LyricsExtension implements KanaruExtension {
  const LyricsExtension();

  @override
  String get id => 'lyrics';

  @override
  void register(ExtensionRegistry registry) {
    registry.addSongDetailSection(
      SongDetailSection(
        id: 'lyrics',
        order: 0,
        build: (_, trackId) => SongInfoLyricsSection(trackId: trackId),
      ),
    );
  }
}
