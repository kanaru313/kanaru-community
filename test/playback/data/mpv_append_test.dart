import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/data/leaked_start.dart';
import 'package:kanaru/src/playback/data/mpv_append.dart';

/// A scripted mpv. [legacy] mimics 0.35 (Android): the 3rd argument of
/// `loadfile` is the options string and a call with more than three
/// arguments is rejected without throwing, as libmpv does.
class FakeMpv implements MpvConsole {
  FakeMpv({this.legacy = false, this.dropAppends = false});

  final bool legacy;
  final bool dropAppends;
  final commands = <List<String>>[];
  final ids = <int>[10]; // the playing entry has id 10
  final props = <String, String>{};
  var _nextId = 11;

  @override
  Future<void> command(List<String> args) async {
    commands.add(args);
    if (args.first != 'loadfile' || dropAppends) return;
    if (legacy && args.length > 3) return; // rejected: log only
    if (args.length > 3) return; // `append start=0` is rejected on >= 0.38
    ids.add(_nextId++);
  }

  @override
  Future<String> get(String name) async {
    if (name == 'playlist-count') return '${ids.length}';
    final m = RegExp(r'^playlist/(\d+)/id$').firstMatch(name);
    if (m != null) return '${ids[int.parse(m.group(1)!)]}';
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

  group('resume offset after an advance', () {
    const resume = Duration(milliseconds: 2400);

    Future<FakeMpv> run(String? timePos, {bool seeked = false}) async {
      final mpv = FakeMpv();
      if (timePos != null) mpv.props['time-pos'] = timePos;
      await undoLeakedStart(
        mpv,
        leaked: resume,
        seekedSinceAdvance: () => seeked,
        disposed: () => false,
        pollEvery: Duration.zero,
      );
      return mpv;
    }

    test('a position at the offset is put back to 0', () async {
      final mpv = await run('2.4');
      expect(mpv.commands, [
        ['seek', '0', 'absolute'],
      ]);
    });

    test('a position at 0 or a user seek is left alone', () async {
      expect((await run('0.1')).commands, isEmpty);
      expect((await run('2.4', seeked: true)).commands, isEmpty);
    });

    test('no offset means nothing is read or sent', () async {
      final mpv = FakeMpv();
      await undoLeakedStart(
        mpv,
        leaked: Duration.zero,
        seekedSinceAdvance: () => false,
        disposed: () => false,
      );
      expect(mpv.commands, isEmpty);
    });

    test('waits until mpv reports a position', () async {
      final mpv = FakeMpv();
      final done = undoLeakedStart(
        mpv,
        leaked: resume,
        seekedSinceAdvance: () => false,
        disposed: () => false,
        pollEvery: const Duration(milliseconds: 5),
      );
      await Future<void>.delayed(const Duration(milliseconds: 12));
      mpv.props['time-pos'] = '2.3';
      await done;
      expect(mpv.commands, [
        ['seek', '0', 'absolute'],
      ]);
    });
  });
}
