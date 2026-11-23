import '../../domain/lyrics_status.dart';

/// The plugin behind what a track shows, when that is online lyrics.
class OnlineShown {
  const OnlineShown({
    required this.providerId,
    required this.providerName,
    required this.synced,
    this.instrumental = false,
  });

  final String providerId;

  /// The name the lyrics were found or kept with.
  final String providerName;
  final bool synced;
  final bool instrumental;
}

/// The online source of [lyrics]; null for anything that is not shown online
/// lyrics (local lyrics, a lookup state, off).
OnlineShown? onlineShownOf(TrackLyrics lyrics) => switch (lyrics) {
  LyricsShown(:final lyrics) when lyrics.online != null => OnlineShown(
    providerId: lyrics.online!.providerId,
    providerName: lyrics.online!.providerName,
    synced: lyrics.synced,
  ),
  LyricsInstrumental(:final ref) => OnlineShown(
    providerId: ref.providerId,
    providerName: ref.providerName,
    synced: false,
    instrumental: true,
  ),
  _ => null,
};
