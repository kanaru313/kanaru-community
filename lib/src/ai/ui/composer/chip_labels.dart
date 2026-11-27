import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/conversation/parts.dart';
import '../../domain/settings/tool_groups.dart';
import '../../domain/variables/chip_ref.dart';

/// The text of a context chip: what it points at, in the user's words.
String chipLabel(AppLocalizations l10n, ChipPart chip) {
  final label = chip.label ?? '';
  return switch (chip.kind) {
    ChipKind.nowPlaying => l10n.aiChatChipNowPlaying,
    ChipKind.song => label.isEmpty ? l10n.aiChatChipSong : label,
    ChipKind.songs => l10n.aiChatChipSongs(
      int.tryParse(label) ?? chip.tracks.length,
    ),
    ChipKind.album => l10n.aiChatChipAlbum(label),
    ChipKind.artist => l10n.aiChatChipArtist(label),
    ChipKind.genre => l10n.aiChatChipGenre(label),
    ChipKind.language => l10n.aiChatChipLanguage(label),
    ChipKind.playlist => l10n.aiChatChipPlaylist(label),
  };
}

/// The glyph of a context chip's kind.
IconData chipIcon(ChipKind kind) => switch (kind) {
  ChipKind.nowPlaying || ChipKind.song => KIcons.songs,
  ChipKind.songs => KIcons.multiSelect,
  ChipKind.album => KIcons.albums,
  ChipKind.artist => KIcons.artists,
  ChipKind.genre => KIcons.genres,
  ChipKind.language => KIcons.languages,
  ChipKind.playlist => KIcons.playlists,
};

/// The name of the tool group a chip needs, for the "tool is off" note.
String chipGroupName(AppLocalizations l10n, ChipKind kind) =>
    toolGroupName(l10n, chipGroup(kind));

/// The name of a tool group in the user's words.
String toolGroupName(AppLocalizations l10n, AiToolGroup group) =>
    switch (group) {
      AiToolGroup.nowPlaying => l10n.aiChatGroupNowPlaying,
      AiToolGroup.playlists => l10n.aiChatGroupPlaylists,
      AiToolGroup.lyrics => l10n.aiChatGroupLyrics,
      AiToolGroup.queue => l10n.aiChatGroupQueue,
      _ => l10n.aiChatGroupTrackInfo,
    };
