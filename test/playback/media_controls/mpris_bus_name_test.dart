import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/media_controls/mpris/mpris_bus_name.dart';

void main() {
  test('the first name is the app name', () {
    expect(mprisBusName, 'org.mpris.MediaPlayer2.kanaru_community');
    expect(mprisBusNameCandidates(77), [
      mprisBusName,
      '$mprisBusName.instance77',
      for (var n = 1; n <= 5; n++) '$mprisBusName.instance77_$n',
    ]);
  });

  test('a free name is taken at once', () async {
    final asked = <String>[];
    final name = await acquireMprisBusName(
      (n) async {
        asked.add(n);
        return DBusRequestNameReply.primaryOwner;
      },
      pid: 5,
      cancelled: () => false,
    );
    expect(name, mprisBusName);
    expect(asked, [mprisBusName]);
  });

  test('taken names fall back to the instance names', () async {
    final taken = {mprisBusName, '$mprisBusName.instance5'};
    final name = await acquireMprisBusName(
      (n) async =>
          taken.contains(n) ? DBusRequestNameReply.exists : DBusRequestNameReply.primaryOwner,
      pid: 5,
      cancelled: () => false,
    );
    expect(name, '$mprisBusName.instance5_1');
  });

  test('already owner counts as ours', () async {
    final name = await acquireMprisBusName(
      (n) async => DBusRequestNameReply.alreadyOwner,
      pid: 5,
      cancelled: () => false,
    );
    expect(name, mprisBusName);
  });

  test('every name taken: null, after seven tries', () async {
    var tries = 0;
    final name = await acquireMprisBusName(
      (n) async {
        tries++;
        return DBusRequestNameReply.exists;
      },
      pid: 5,
      cancelled: () => false,
    );
    expect(name, isNull);
    expect(tries, 7);
  });

  test('a queued reply is not ours', () async {
    final name = await acquireMprisBusName(
      (n) async => DBusRequestNameReply.inQueue,
      pid: 5,
      cancelled: () => false,
    );
    expect(name, isNull);
  });

  test('cancelling stops the search', () async {
    var tries = 0;
    var cancel = false;
    final name = await acquireMprisBusName(
      (n) async {
        tries++;
        cancel = true;
        return DBusRequestNameReply.exists;
      },
      pid: 5,
      cancelled: () => cancel,
    );
    expect(name, isNull);
    expect(tries, 1);
  });
}
