import 'package:logging/logging.dart';

import 'mpv_log_filter.dart';
import 'mpv_options.dart';

final _log = Logger('mpv');

/// The entry [appendEntry] added: its mpv entry id and the playlist length
/// after it.
typedef AppendedEntry = ({int id, int count});

/// Appends [uri] to mpv's playlist and checks that it happened.
///
/// The command is `loadfile <uri> append`, the only form valid on every mpv:
/// 0.35 (Android's libmpv) reads the third argument as the options string, so
/// `append -1 start=0` is rejected there, and from 0.38 the third argument is
/// the index, so `append start=0` is rejected there. mpv reports a rejected
/// command through its log, not by throwing, so success is read back:
/// `playlist-count` must grow by exactly one, and the new entry's id must
/// differ from [currentId] (an id lookup on an unchanged playlist returns the
/// playing entry's own id).
///
/// Returns null, with a warning, when the entry was not appended or could not
/// be verified. The command may still have landed then: the caller removes
/// what follows the playing entry with [removeEntriesAfter].
Future<AppendedEntry?> appendEntry(
  MpvConsole mpv,
  String uri, {
  required int? currentId,
}) async {
  final before = await _readInt(mpv, 'playlist-count') ?? 0;
  await mpv.command(['loadfile', uri, 'append']);
  final after = await _readInt(mpv, 'playlist-count') ?? 0;
  if (after != before + 1) {
    _log.warning(
      'append of ${scrubPaths(uri)} not applied: playlist-count $before -> $after',
    );
    return null;
  }
  final id = await _readInt(mpv, 'playlist/${after - 1}/id');
  if (id == null || id == currentId) {
    _log.warning('append of ${scrubPaths(uri)} gave no new entry id (got $id)');
    return null;
  }
  return (id: id, count: after);
}

Future<int?> _readInt(MpvProperties mpv, String name) async {
  try {
    return int.tryParse(await mpv.get(name));
  } on Object {
    return null; // unavailable while nothing is loaded
  }
}

/// Removes every playlist entry after position [playingPos], last first, so
/// nothing untracked stays behind the playing entry.
Future<void> removeEntriesAfter(MpvConsole mpv, int playingPos) async {
  if (playingPos < 0) return;
  final count = await _readInt(mpv, 'playlist-count') ?? 0;
  for (var i = count - 1; i > playingPos; i--) {
    await mpv.command(['playlist-remove', '$i']);
  }
}
