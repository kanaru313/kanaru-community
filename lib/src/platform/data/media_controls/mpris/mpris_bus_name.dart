import 'package:dbus/dbus.dart';
import 'package:logging/logging.dart';

final _log = Logger('mpris');

/// The well-known name of the app (the part after the standard prefix is the
/// desktop-entry style id with dots replaced by underscores).
const mprisBusName = 'org.mpris.MediaPlayer2.kanaru_community';

/// How many `.instance<pid>_<n>` names to try after the plain ones.
const _maxExtraNames = 5;

/// The names to try, in order: the plain one, `.instance<pid>`, then
/// `.instance<pid>_1` to `_5`. Another instance (or a leftover of a crashed
/// one) may hold the plain name.
List<String> mprisBusNameCandidates(int pid) => [
  mprisBusName,
  '$mprisBusName.instance$pid',
  for (var n = 1; n <= _maxExtraNames; n++) '$mprisBusName.instance${pid}_$n',
];

/// Asks the bus for the first free name of [mprisBusNameCandidates] through
/// [request] (`DBusClient.requestName` with the `doNotQueue` flag: without it
/// the bus queues the request and never says no). Returns the name that is
/// ours, or null when none is free or [cancelled] turns true.
Future<String?> acquireMprisBusName(
  Future<DBusRequestNameReply> Function(String name) request, {
  required int pid,
  required bool Function() cancelled,
}) async {
  for (final name in mprisBusNameCandidates(pid)) {
    if (cancelled()) return null;
    final reply = await request(name);
    if (reply == DBusRequestNameReply.primaryOwner ||
        reply == DBusRequestNameReply.alreadyOwner) {
      if (name != mprisBusName) _log.info('$mprisBusName is taken, using $name');
      return name;
    }
  }
  _log.warning('no free MPRIS bus name, media controls stay off');
  return null;
}
