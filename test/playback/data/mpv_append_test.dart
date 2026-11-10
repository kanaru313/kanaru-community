import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/data/mpv_append.dart';
import 'package:kanaru/src/playback/data/mpv_options.dart';

/// A scripted mpv. The 4th `loadfile` argument is the index from 0.38 (it
/// must be an integer, so `append -1 start=0` is accepted and `append
/// start=0` is rejected) and the options string before (so `append start=0`
/// is accepted and the five-argument `append -1 start=0` is rejected). A rejected command
/// does not throw, as with libmpv: it changes nothing.
class FakeMpv implements MpvConsole {
  FakeMpv({this.legacy = false, this.dropAppends = false, this.unreadableId});

  final bool legacy;
  final bool dropAppends;

  /// A playlist index whose id cannot be read (the entry still lands).
  final int? unreadableId;
  final commands = <List<String>>[];
  final ids = <int>[10]; // the playing entry has id 10
  final props = <String, String>{};
  var _nextId = 11;

  bool _accepts(List<String> a) {
    if (a.length == 3) return true;
    if (legacy) return a.length == 4 && a[3].contains('='); // options
    return a.length >= 4 && int.tryParse(a[3]) != null; // index
  }

  @override
  Future<void> command(List<String> args) async {
    commands.add(args);
    if (args.first == 'playlist-remove') {
      ids.removeAt(int.parse(args[1]));
      return;
    }
    if (args.first != 'loadfile' || dropAppends || !_accepts(args)) return;
    ids.add(_nextId++);
  }

  @override
  Future<String> get(String name) async {
    if (name == 'playlist-count') return '${ids.length}';
    final m = RegExp(r'^playlist/(\d+)/id$').firstMatch(name);
    if (m != null) {
      final i = int.parse(m.group(1)!);
      if (i == unreadableId) throw StateError('no id');
      return '${ids[i]}';
    }
    final v = props[name];
    if (v == null) throw StateError('property unavailable: $name');
    return v;
  }

  @override
  Future<void> set(String name, String value) async => props[name] = value;
}

void main() {
  for (final legacy in [true, false]) {
    test(
      'appends with the portable form (${legacy ? '0.35' : 'new'} mpv)',
      () async {
        final mpv = FakeMpv(legacy: legacy);
        final r = await appendEntry(mpv, 'file:///b.flac', currentId: 10);
        expect(mpv.commands, [
          ['loadfile', 'file:///b.flac', 'append'],
        ]);
        expect(r, (id: 11, count: 2));
      },
    );
  }

  test(
    'an append that leaves the count unchanged is reported as not done',
    () async {
      final mpv = FakeMpv(dropAppends: true);
      expect(await appendEntry(mpv, 'file:///b.flac', currentId: 10), isNull);
      expect(mpv.ids, [10]);
    },
  );

  test('an id equal to the current one is refused', () async {
    final mpv = FakeMpv();
    expect(await appendEntry(mpv, 'file:///b.flac', currentId: 11), isNull);
  });

  test(
    'an append that landed but could not be verified leaves nothing behind',
    () async {
      final mpv = FakeMpv(unreadableId: 1);
      expect(await appendEntry(mpv, 'file:///b.flac', currentId: 10), isNull);
      expect(mpv.ids, [10, 11], reason: 'it did land');
      await removeEntriesAfter(mpv, 0);
      expect(mpv.ids, [10]);
    },
  );

  test(
    'removeEntriesAfter keeps the playing entry and what precedes it',
    () async {
      final mpv = FakeMpv()..ids.addAll([11, 12, 13]);
      await removeEntriesAfter(mpv, 1);
      expect(mpv.ids, [10, 11]);
      await removeEntriesAfter(mpv, -1);
      expect(mpv.ids, [10, 11]);
    },
  );
}
