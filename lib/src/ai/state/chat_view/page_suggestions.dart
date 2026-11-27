import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/domain/ask_ai_target.dart';
import '../../../library/state/browse/detail_providers.dart';
import '../../../library/state/browse/selection_providers.dart';
import '../../../library/state/playlists/playlist_providers.dart';
import '../../../library/ui/browse/library_labels.dart';
import '../../../library/ui/playlist_common/playlist_labels.dart';
import '../../../media/domain/library_keys.dart';
import '../../../playback/state/playback_providers.dart';
import '../../../playback/state/track_info_providers.dart';
import '../../domain/conversation/parts.dart';
import '../../domain/variables/chip_ref.dart';

/// The location of the page the chat was opened over (what the user sees
/// next to the desktop panel, or under the phone's chat page). The shell
/// writes it: live on desktop, and on the phone it keeps the last page that
/// was not the chat, so it is the one captured before the push.
class ChatPageLocation extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? location) {
    if (state != location) state = location;
  }
}

final chatPageLocationProvider = NotifierProvider<ChatPageLocation, String?>(
  ChatPageLocation.new,
);

/// The selected songs as the chat names them: ids only (at most
/// `askAiMaxSongs`), so a toggle reads nothing from the library; empty
/// without a selection.
final selectionTracksProvider = Provider.autoDispose<List<AskAiTrack>>((ref) {
  final ids = ref.watch(librarySelectionProvider.select((s) => s.ids));
  return askAiTracksOfIds([for (final id in ids) id.value]);
});

/// How many songs are selected (the chip may carry fewer ids).
final selectionCountProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(librarySelectionProvider.select((s) => s.ids.length)),
);

ChipPart _chip(AskAiTarget target, {String? label}) {
  final ref = chipRefOf(target);
  return ChipPart(
    kind: ref.kind,
    ref: ref.ref,
    label: label ?? ref.label,
    tracks: ref.tracks,
  );
}

/// What a library location names, as a chat target; null for a page that is
/// not an album, artist, genre, language or playlist (or whose name is not
/// loaded yet).
AskAiTarget? pageTargetOf(Ref ref, AppLocalizations l10n, String location) {
  final segments = Uri.tryParse(location)?.pathSegments;
  if (segments == null || (segments.length != 2 && segments.length != 3)) {
    return null;
  }
  if (segments.length == 2) {
    if (segments[0] != 'playlists') return null;
    final uid = segments[1];
    final summary = ref.watch(playlistDetailProvider(uid)).value?.summary;
    return summary == null
        ? null
        : AskAiTarget.playlist(uid, playlistDisplayName(l10n, summary));
  }
  if (segments[0] != 'library') return null;
  final id = segments[2];
  switch (segments[1]) {
    case 'albums':
      final key = AlbumKey.decode(id);
      final title = key == null
          ? null
          : ref.watch(albumDetailProvider(key)).value?.title;
      return title == null ? null : AskAiTarget.album(key!.encode(), title);
    case 'artists':
      final key = ArtistKey.decode(id);
      final name = key == null
          ? null
          : ref.watch(artistNameProvider(key)).value;
      return name == null ? null : AskAiTarget.artist(key!.encode(), name);
    case 'genres':
      final key = decodeKey(id);
      final name = key == null || key.isEmpty
          ? null
          : ref.watch(genreNameProvider(key)).value;
      return name == null ? null : AskAiTarget.genre(key!, name);
    case 'languages':
      final code = id == '_unknown' ? null : decodeKey(id);
      if (id != '_unknown' && (code == null || code.isEmpty)) return null;
      return AskAiTarget.language(code, languageDisplayName(l10n, code));
  }
  return null;
}

/// The title of the playing song, null while none is loaded or its row has
/// not arrived. Follows the player, so the "now playing" suggestion stays
/// current when the song changes.
final currentTrackTitleProvider = Provider.autoDispose<String?>((ref) {
  if (!ref.watch(hasCurrentTrackProvider)) return null;
  final id = ref.watch(nowPlayingProvider.select((n) => n.value?.trackId));
  if (id == null) return null;
  return ref.watch(trackInfoProvider(id).select((t) => t.value?.title));
});

/// The chips offered under the composer, in order: the playing song, the
/// selected songs ("N bài đã chọn"), then the page the chat opened over
/// (album, artist, genre, language or playlist). A root page has no page
/// chip. Keyed by the localizations because language and playlist names are
/// localized.
final chatSuggestionsProvider = Provider.autoDispose
    .family<List<ChipPart>, AppLocalizations>((ref, l10n) {
      final location = ref.watch(chatPageLocationProvider);
      final page = location == null ? null : pageTargetOf(ref, l10n, location);
      final selected = ref.watch(selectionTracksProvider);
      return [
        if (ref.watch(hasCurrentTrackProvider))
          _chip(
            const AskAiTarget.nowPlaying(),
            label: ref.watch(currentTrackTitleProvider),
          ),
        if (selected.isNotEmpty)
          _chip(
            AskAiTarget.songs(
              selected,
              total: ref.watch(selectionCountProvider),
            ),
          ),
        if (page != null) _chip(page),
      ];
    });
