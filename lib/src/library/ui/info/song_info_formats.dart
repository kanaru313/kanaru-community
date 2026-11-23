import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/info/release_date.dart';

/// `44.1` for 44100 Hz, `48` for 48000.
String formatKhz(int hz, String locale) {
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

/// `5:10` / `1:02:03` for a length in milliseconds.
String formatInfoDuration(int ms) {
  final total = (ms / 1000).round();
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
}

/// A moment as `8 thg 6, 2025 21:14` (locale's `yMMMd` + `Hm`), local time.
String formatInfoDate(int epochMs, String locale) =>
    DateFormat.yMMMd(locale)
        .add_Hm()
        .format(DateTime.fromMillisecondsSinceEpoch(epochMs));

/// `2018`, `2018-03` or `2018-03-09`: what the tag gave, nothing invented.
String formatReleaseDate(ReleaseDate date) {
  final b = StringBuffer('${date.year}');
  final month = date.month;
  if (month != null) {
    b.write('-${month.toString().padLeft(2, '0')}');
    final day = date.day;
    if (day != null) b.write('-${day.toString().padLeft(2, '0')}');
  }
  return b.toString();
}

/// `Mono`, `Stereo` or `N channels`.
String channelsText(AppLocalizations l10n, int channels) => switch (channels) {
  1 => l10n.libraryInfoMono,
  2 => l10n.libraryInfoStereo,
  _ => l10n.libraryInfoChannelCount(channels),
};

// Codec strings the Rust reader writes and file extensions, folded to one
// family each so "MP3" and "MPEG-1 Layer 3" (or "MP4" and "M4A") count as the
// same thing. Anything not listed is its own family, lower-cased.
const Map<String, String> _families = {
  'mp3': 'mp3',
  'mpeg-1 layer 3': 'mp3',
  'mpeg layer 3': 'mp3',
  'mpeg-1 audio layer 3': 'mp3',
  'mp4': 'mp4',
  'm4a': 'mp4',
  'm4b': 'mp4',
  'm4p': 'mp4',
  'm4r': 'mp4',
  'wav': 'wav',
  'wave': 'wav',
  'aiff': 'aiff',
  'aif': 'aiff',
  'aifc': 'aiff',
  'flac': 'flac',
  'fla': 'flac',
  'wavpack': 'wavpack',
  'wv': 'wavpack',
  'vorbis': 'vorbis',
  'ogg': 'vorbis',
  'oga': 'vorbis',
  'speex': 'speex',
  'spx': 'speex',
  'mpc': 'mpc',
  'mp+': 'mpc',
};

String _family(String raw) {
  final key = raw.trim().toLowerCase();
  return _families[key] ?? key;
}

/// Whether [codec] tells something the [format] (the file's extension) does
/// not: false for no codec or the same family ignoring case; true for
/// `AAC-LC` inside an `M4A`.
bool codecDiffersFromFormat(String? codec, String? format) {
  if (codec == null || codec.trim().isEmpty) return false;
  if (format == null || format.trim().isEmpty) return true;
  return _family(codec) != _family(format);
}

/// File name of [path] without its extension (`01 - Song`), for the
/// "title comes from the file name" check.
String fileStem(String path) {
  final name = path.substring(path.lastIndexOf('/') + 1);
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}
