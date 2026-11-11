import 'package:flutter/widgets.dart' show IconData;
import 'package:intl/intl.dart' show NumberFormat;
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../domain/browse/menu_targets.dart';
import 'menu_model.dart';

/// The song info sub-page of the song menu: file facts and the absolute path
/// (copyable). Null when the track's file facts are not known.
MenuPageSpec? songInfoPage(SongInfo? info, MenuEnv env) {
  if (info == null) return null;
  final l10n = env.l10n;
  final unknown = l10n.libraryInfoUnknown;
  MenuItemSpec row(String title, String? value, {IconData? icon}) =>
      MenuItemSpec(
        MenuItemId.info,
        icon: icon ?? KIcons.info,
        title: title,
        subtitle: value ?? unknown,
      );
  final path = info.path;
  final bitrate = info.bitrate;
  final sampleRate = info.sampleRate;
  final bitDepth = info.bitDepth;
  final size = info.sizeBytes;
  return MenuPageSpec(
    title: l10n.libraryMenuSongInfo,
    groups: [
      [
        row(l10n.libraryInfoFormat, info.format, icon: KIcons.musicFile),
        row(
          l10n.libraryInfoBitrate,
          bitrate == null ? null : l10n.libraryInfoBitrateValue(bitrate),
        ),
        row(
          l10n.libraryInfoSampleRate,
          sampleRate == null
              ? null
              : l10n.libraryInfoSampleRateValue(
                  _khz(sampleRate, l10n.localeName),
                ),
        ),
        row(
          l10n.libraryInfoBitDepth,
          bitDepth == null ? null : l10n.libraryInfoBitDepthValue(bitDepth),
        ),
        row(
          l10n.libraryInfoSize,
          size == null ? null : formatBytes(size, l10n.localeName),
        ),
        MenuItemSpec(
          MenuItemId.info,
          icon: KIcons.folders,
          title: l10n.libraryInfoPath,
          subtitle: path ?? unknown,
          trailing: path == null
              ? null
              : MenuTrailingSpec(
                  icon: KIcons.copy,
                  tooltip: l10n.libraryMenuCopyPath,
                  action: MenuAction.copy(path),
                ),
        ),
        row(
          l10n.libraryInfoPlayCount,
          '${info.playCount}',
          icon: KIcons.playCount,
        ),
      ],
    ],
  );
}

/// `44.1` for 44100 Hz, `48` for 48000.
String _khz(int hz, String locale) {
  final k = hz / 1000;
  return k == k.roundToDouble()
      ? '${k.round()}'
      : NumberFormat('0.0', locale).format(k);
}

/// `3.4 MB`: binary units, one decimal.
String formatBytes(int bytes, [String locale = 'en']) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return unit == 0
      ? '$bytes B'
      : '${NumberFormat('0.0', locale).format(value)} ${units[unit]}';
}
