import '../../domain/lyrics_status.dart';
import '../../domain/online/online_lyrics_ref.dart';
import '../../domain/online/online_rows.dart';

/// What the "Bản trực tuyến" row of "Lời cho bài này" says: where the online
/// copy of the track came from and whether it is what shows now.
class OnlineRowInfo {
  const OnlineRowInfo({
    required this.providerId,
    required this.providerName,
    required this.how,
    required this.selected,
    this.synced = false,
    this.instrumental = false,
    this.duration,
  });

  final String providerId;

  /// The plugin's name, as kept with the copy (known after the plugin is
  /// removed).
  final String providerName;

  /// Found by the automatic search, or kept by the user.
  final OnlineHow how;

  /// The online copy is what the track shows.
  final bool selected;
  final bool synced;
  final bool instrumental;

  /// The duration the source declared for it; null when it declared none.
  final Duration? duration;

  /// The user can still refuse or keep what shows: the bottom bar's cases.
  bool get autoShown => selected && how == OnlineHow.auto;
  bool get keptShown => selected && how == OnlineHow.kept;

  @override
  bool operator ==(Object other) =>
      other is OnlineRowInfo &&
      other.providerId == providerId &&
      other.providerName == providerName &&
      other.how == how &&
      other.selected == selected &&
      other.synced == synced &&
      other.instrumental == instrumental &&
      other.duration == duration;

  @override
  int get hashCode => Object.hash(
    providerId,
    providerName,
    how,
    selected,
    synced,
    instrumental,
    duration,
  );
}

OnlineRowInfo _fromRef(
  OnlineLyricsRef ref, {
  required bool selected,
  required bool synced,
  bool instrumental = false,
}) => OnlineRowInfo(
  providerId: ref.providerId,
  providerName: ref.providerName,
  how: ref.how,
  selected: selected,
  synced: synced,
  instrumental: instrumental,
  duration: ref.remoteDurationMs == null
      ? null
      : Duration(milliseconds: ref.remoteDurationMs!),
);

/// The online copy a track has, for its row: what shows now, else what an
/// off choice would show, else the kept copy [pin] (a `Lời trong file` choice
/// keeps it out of sight but not gone). Null when the track has none.
OnlineRowInfo? onlineRowInfoOf(TrackLyrics lyrics, OnlinePick? pin) {
  switch (lyrics) {
    case LyricsShown(:final lyrics) when lyrics.online != null:
      return _fromRef(lyrics.online!, selected: true, synced: lyrics.synced);
    case LyricsInstrumental(:final ref):
      return _fromRef(ref, selected: true, synced: false, instrumental: true);
    case LyricsOff(:final available?) when available.online != null:
      return _fromRef(
        available.online!,
        selected: false,
        synced: available.synced,
      );
    default:
  }
  if (pin == null || !pin.usable) return null;
  return OnlineRowInfo(
    providerId: pin.providerId,
    providerName: pin.providerName,
    how: OnlineHow.kept,
    selected: false,
    synced: pin.text?.synced ?? false,
    instrumental: pin.text == null && pin.instrumental,
    duration: pin.remoteDurationMs == null
        ? null
        : Duration(milliseconds: pin.remoteDurationMs!),
  );
}
