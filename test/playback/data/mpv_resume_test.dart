import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/data/mpv_options.dart';
import 'package:kanaru/src/playback/data/mpv_resume.dart';

class _Mpv implements MpvConsole {
  _Mpv(this.props);
  final Map<String, String> props;
  final commands = <List<String>>[];

  @override
  Future<void> command(List<String> args) async => commands.add(args);

  @override
  Future<String> get(String name) async {
    final v = props[name];
    if (v == null) throw StateError('unavailable: $name');
    return v;
  }

  @override
  Future<void> set(String name, String value) async => props[name] = value;
}

void main() {
  Future<bool> run(_Mpv m, Duration start, {int attempts = 100}) =>
      seekToResume(
        m,
        start,
        disposed: () => false,
        pollEvery: const Duration(milliseconds: 1),
        attempts: attempts,
      );

  test('seeks once, absolute, when the file is open', () async {
    final m = _Mpv({'duration': '200.0'});
    expect(
      await run(m, const Duration(seconds: 90, milliseconds: 500)),
      isTrue,
    );
    expect(m.commands, [
      ['seek', '90.500', 'absolute'],
    ]);
  });

  test('an offset past the end is clamped to the duration', () async {
    final m = _Mpv({'duration': '134.75'});
    await run(m, const Duration(seconds: 500));
    expect(m.commands.single[1], '134.750');
  });

  test('no offset sends nothing', () async {
    final m = _Mpv({'duration': '200'});
    expect(await run(m, Duration.zero), isFalse);
    expect(m.commands, isEmpty);
  });

  test('waits for the duration to appear', () async {
    final m = _Mpv({});
    final done = run(m, const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(m.commands, isEmpty);
    m.props['duration'] = '60';
    expect(await done, isTrue);
    expect(m.commands.single, ['seek', '5.000', 'absolute']);
  });

  test('gives up when mpv went idle or never opens', () async {
    final idle = _Mpv({'idle-active': 'yes'});
    expect(await run(idle, const Duration(seconds: 5)), isFalse);
    final never = _Mpv({});
    expect(await run(never, const Duration(seconds: 5), attempts: 3), isFalse);
    expect(idle.commands + never.commands, isEmpty);
  });
}
