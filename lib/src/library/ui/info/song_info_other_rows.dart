import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/info/song_details.dart';
import 'song_info_formats.dart';
import 'song_info_row_helpers.dart';
import 'song_info_spec.dart';

/// Rows of the Audio, File and Yours groups.
List<InfoRowSpec> audioRows(AppLocalizations l10n, SongDetails d) {
  final locale = l10n.localeName;
  final duration = d.durationMs;
  final bitrate = d.bitrate;
  final rate = d.sampleRate;
  final depth = d.bitDepth;
  final channels = d.channels;
  return [
    textRow(
      InfoRowId.duration,
      l10n.libraryInfoDuration,
      duration == null ? null : formatInfoDuration(duration),
    ),
    textRow(InfoRowId.format, l10n.libraryInfoFormat, d.format),
    if (codecDiffersFromFormat(d.codec, d.format))
      textRow(InfoRowId.codec, l10n.libraryInfoCodec, d.codec),
    textRow(
      InfoRowId.bitrate,
      l10n.libraryInfoBitrate,
      bitrate == null ? null : l10n.libraryInfoBitrateAverage(bitrate),
    ),
    textRow(
      InfoRowId.sampleRate,
      l10n.libraryInfoSampleRate,
      rate == null
          ? null
          : l10n.libraryInfoSampleRateValue(formatKhz(rate, locale)),
    ),
    textRow(
      InfoRowId.bitDepth,
      l10n.libraryInfoBitDepth,
      depth == null ? null : l10n.libraryInfoBitDepthValue(depth),
    ),
    textRow(
      InfoRowId.channels,
      l10n.libraryInfoChannels,
      channels == null || channels <= 0 ? null : channelsText(l10n, channels),
    ),
    InfoRowSpec(InfoRowId.replayGain, l10n.libraryInfoReplayGain, soon: true),
  ];
}

List<InfoRowSpec> fileRows(
  AppLocalizations l10n,
  SongDetails d,
  bool canReveal,
  bool desktop,
) {
  final locale = l10n.localeName;
  final path = infoText(d.path);
  final gone = d.status == SongFileStatus.missing;
  final source = infoText(d.sourceName);
  final root = infoText(d.sourceRoot);
  final size = d.sizeBytes;
  final mtime = d.mtimeMs;
  return [
    InfoRowSpec(
      InfoRowId.path,
      l10n.libraryInfoPath,
      kind: InfoRowKind.path,
      value: path,
      empty: path == null,
      missing: gone && path != null,
      canReveal: canReveal && path != null,
    ),
    textRow(
      InfoRowId.musicFolder,
      l10n.libraryInfoMusicFolder,
      desktop ? (root ?? source) : source,
    ),
    textRow(
      InfoRowId.size,
      l10n.libraryInfoSize,
      size == null ? null : formatBytes(size, locale),
    ),
    textRow(
      InfoRowId.modified,
      l10n.libraryInfoModified,
      mtime == null ? null : formatInfoDate(mtime, locale),
    ),
    textRow(
      InfoRowId.added,
      l10n.libraryInfoAdded,
      formatInfoDate(d.addedAt, locale),
    ),
  ];
}

List<InfoRowSpec> yourRows(AppLocalizations l10n, SongDetails d) {
  final locale = l10n.localeName;
  final first = d.firstPlayedAt;
  final last = d.lastPlayedAt;
  return [
    InfoRowSpec(
      InfoRowId.favorite,
      l10n.libraryInfoFavorite,
      kind: InfoRowKind.favorite,
    ),
    InfoRowSpec(InfoRowId.rating, l10n.libraryInfoRating, soon: true),
    textRow(
      InfoRowId.plays,
      l10n.libraryInfoPlayCount,
      l10n.libraryInfoTimes(d.playCount),
    ),
    textRow(
      InfoRowId.skips,
      l10n.libraryInfoSkips,
      l10n.libraryInfoTimes(d.skipCount),
    ),
    first == null
        ? InfoRowSpec(
            InfoRowId.firstPlayed,
            l10n.libraryInfoFirstPlayed,
            value: l10n.libraryInfoNeverPlayed,
            muted: true,
          )
        : textRow(
            InfoRowId.firstPlayed,
            l10n.libraryInfoFirstPlayed,
            formatInfoDate(first, locale),
          ),
    textRow(
      InfoRowId.lastPlayed,
      l10n.libraryInfoLastPlayed,
      last == null ? null : formatInfoDate(last, locale),
    ),
  ];
}
