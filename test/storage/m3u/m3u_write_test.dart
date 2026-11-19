import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_write.dart';

void main() {
  test('empty list is just the header', () {
    final r = writeM3u(const []);
    expect((r.text, r.skipped), ('#EXTM3U\n', 0));
  });

  test('EXTINF with artist, title and seconds', () {
    final r = writeM3u(const [
      M3uWriteItem(
        path: '/m/a.mp3',
        title: 'T',
        artist: 'A',
        durationMs: 123900,
      ),
    ]);
    expect(r.text, '#EXTM3U\n#EXTINF:123,A - T\n/m/a.mp3\n');
  });

  test('unknown duration is -1, missing artist writes the title only', () {
    final r = writeM3u(const [M3uWriteItem(path: '/a', title: 'T')]);
    expect(r.text, contains('#EXTINF:-1,T\n'));
  });

  test('no title writes the path alone', () {
    expect(writeM3u(const [M3uWriteItem(path: '/a')]).text, '#EXTM3U\n/a\n');
  });

  test('control and bidi characters in labels become spaces', () {
    final r = writeM3u(const [
      M3uWriteItem(path: '/a', title: 'T\nX\u202E', artist: 'A\r'),
    ]);
    expect(r.text, '#EXTM3U\n#EXTINF:-1,A - T X\n/a\n');
  });

  test('paths with line breaks or NUL are skipped and counted', () {
    final r = writeM3u(const [
      M3uWriteItem(path: '/a\nb'),
      M3uWriteItem(path: '/a\rb'),
      M3uWriteItem(path: '/a\u0000b'),
      M3uWriteItem(path: '/ok'),
    ]);
    expect((r.text, r.skipped), ('#EXTM3U\n/ok\n', 3));
  });

  test('relative lines starting with # or holding an early colon get ./', () {
    final r = writeM3u(const [
      M3uWriteItem(path: '#hash.mp3'),
      M3uWriteItem(path: 'a:b.mp3'),
      M3uWriteItem(path: 'dir/a:b.mp3'),
      M3uWriteItem(path: '../x.mp3'),
    ]);
    expect(r.text, '#EXTM3U\n./#hash.mp3\n./a:b.mp3\ndir/a:b.mp3\n../x.mp3\n');
  });

  test('a blank path is skipped and counted, its EXTINF too', () {
    final r = writeM3u(const [
      M3uWriteItem(path: '', title: 'T'),
      M3uWriteItem(path: '  '),
    ]);
    expect((r.text, r.skipped), ('#EXTM3U\n', 2));
  });

  test('a negative duration is written as -1', () {
    final r = writeM3u(const [
      M3uWriteItem(path: '/a', title: 'T', durationMs: -5),
    ]);
    expect(r.text, contains('#EXTINF:-1,T'));
  });

  test('C1 controls, direction marks and separators in labels become spaces', () {
    final r = writeM3u(const [
      M3uWriteItem(path: '/a', title: 'A\u0085B\u200EC\u2028D\u061CE'),
    ]);
    expect(r.text, contains('#EXTINF:-1,A B C D E\n'));
  });
}
