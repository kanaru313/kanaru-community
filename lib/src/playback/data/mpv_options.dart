import 'package:logging/logging.dart';

final _log = Logger('mpv');

/// Options set before the first open. The queue lives in Dart; mpv only holds
/// the current and the next entry.
const Map<String, String> mpvOptions = {
  // The .lrc next to a song must not load as subtitles.
  'sub-auto': 'no',
  'gapless-audio': 'weak',
  'cache-on-disk': 'no',
  'demuxer': 'lavf',
  // Local files only.
  'demuxer-lavf-o': 'protocol_whitelist=file',
  'ytdl': 'no',
  'vid': 'no',
};

/// Options read back after setting, with the value that must come back.
/// `keep-open` is media_kit's own setting: its end-of-file handling relies
/// on `yes`.
const Map<String, String> mpvExpected = {
  'gapless-audio': 'weak',
  'demuxer-lavf-o': 'protocol_whitelist=file',
  'keep-open': 'yes',
};

/// Reads/writes mpv properties; the media_kit player in production.
abstract interface class MpvProperties {
  Future<void> set(String name, String value);
  Future<String> get(String name);
}

/// [MpvProperties] plus raw commands; the media_kit player in production.
abstract interface class MpvConsole implements MpvProperties {
  Future<void> command(List<String> args);
}

/// Applies [mpvOptions] and warns about every [mpvExpected] value that did not
/// stick. Returns the properties that differ (for tests and the smoke test).
Future<Map<String, String>> applyMpvOptions(MpvProperties mpv) async {
  for (final e in mpvOptions.entries) {
    try {
      await mpv.set(e.key, e.value);
    } on Object catch (err) {
      _log.warning('could not set ${e.key}: $err');
    }
  }
  final wrong = <String, String>{};
  for (final e in mpvExpected.entries) {
    String actual;
    try {
      actual = await mpv.get(e.key);
    } on Object catch (err) {
      actual = '<unreadable: $err>';
    }
    if (actual != e.value) {
      wrong[e.key] = actual;
      _log.warning('mpv ${e.key} is "$actual", expected "${e.value}"');
    }
  }
  return wrong;
}
