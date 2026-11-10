import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/playback/data/mpv_log_filter.dart';

void main() {
  List<String> feed(
    MpvLogFilter f,
    String level,
    String prefix,
    String text,
    int ms,
  ) => f.accept(level: level, prefix: prefix, text: text, nowMs: ms);

  test('errors pass from any prefix, warnings only from relevant ones', () {
    final f = MpvLogFilter();
    expect(feed(f, 'error', 'ffmpeg', 'x', 0), hasLength(1));
    expect(feed(f, 'warn', 'main', 'a', 0), hasLength(1));
    expect(feed(f, 'warn', 'ffmpeg', 'Header missing', 0), isEmpty);
    expect(feed(f, 'info', 'main', 'b', 0), isEmpty);
  });

  test('a repeated line in the same second is dropped', () {
    final f = MpvLogFilter();
    expect(feed(f, 'error', 'main', 'same', 0), hasLength(1));
    expect(feed(f, 'error', 'main', 'same', 100), isEmpty);
  });

  test('the budget caps a second and the next one starts with a summary', () {
    final f = MpvLogFilter(budget: 2);
    var passed = 0;
    for (var i = 0; i < 10; i++) {
      passed += feed(f, 'error', 'main', 'line $i', 10).length;
    }
    expect(passed, 2);
    final next = feed(f, 'error', 'main', 'later', 1010);
    expect(next, ['mpv: 8 messages suppressed', 'mpv error [main] later']);
  });

  test('paths and file URIs are reduced to the file name', () {
    expect(
      scrubPaths("Cannot open file '/storage/emulated/0/Music/A Song.flac'"),
      "Cannot open file 'A Song.flac'",
    );
    expect(
      scrubPaths('open file:///home/u/Music/a%20b.mp3 failed'),
      'open a%20b.mp3 failed',
    );
    expect(
      scrubPaths('loadfile, append, 1/2 done'),
      'loadfile, append, 1/2 done',
    );
    final f = MpvLogFilter();
    expect(
      feed(f, 'error', 'file', 'no /home/u/x.mp3', 0).single,
      'mpv error [file] no x.mp3',
    );
  });

  test('directories with spaces, Vietnamese names and %20 do not leak', () {
    expect(
      scrubPaths('Cannot open /storage/emulated/0/My Music/x.flac'),
      'Cannot open x.flac',
    );
    expect(
      scrubPaths(
        "failed '/storage/emulated/0/Nhạc Việt/Mang Tiền Về Cho Mẹ.flac'",
      ),
      "failed 'Mang Tiền Về Cho Mẹ.flac'",
    );
    expect(
      scrubPaths('loadfile file:///home/hieu/My%20Music/Bài%20Hát.flac'),
      'loadfile Bài%20Hát.flac',
    );
    expect(scrubPaths('a / b and 3/4'), 'a / b and 3/4');
  });
}
