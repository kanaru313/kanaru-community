import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_parse.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_relative_path.dart';
import 'package:kanaru/src/storage/domain/m3u/m3u_write.dart';

M3uParse roundTrip(List<M3uWriteItem> items) =>
    parseM3u(Uint8List.fromList(utf8.encode(writeM3u(items).text)));

void main() {
  const absolutePaths = [
    '/music/Nhạc Việt/Đêm.mp3',
    '/music/a b/c.flac',
    '/music/a b/c.flac', // repeat kept
    '/music/x.mp3',
  ];

  test('absolute: paths, order, repeats and EXTINF survive', () {
    final items = [
      for (var i = 0; i < absolutePaths.length; i++)
        M3uWriteItem(
          path: absolutePaths[i],
          title: 'Title $i',
          artist: i.isEven ? 'Artist $i' : null,
          durationMs: 200000 + i * 1000,
        ),
    ];
    final p = roundTrip(items);
    expect(p.entries.map((e) => e.text), absolutePaths);
    for (var i = 0; i < items.length; i++) {
      final x = p.entries[i].extinf!;
      expect(x.title, items[i].title);
      expect(x.artist, items[i].artist);
      expect(x.durationMs, items[i].durationMs);
    }
  });

  test(
    'relative: lines computed from the target folder come back as written',
    () {
      const dir = '/music/lists';
      final lines = [for (final a in absolutePaths) relativeM3uPath(dir, a)];
      final p = roundTrip([for (final l in lines) M3uWriteItem(path: l)]);
      expect(p.entries.map((e) => e.text), lines);
      expect(lines.first, '../Nhạc Việt/Đêm.mp3');
    },
  );

  test('a #-name and a name with a colon survive through ./', () {
    final p = roundTrip(const [
      M3uWriteItem(path: '#1 hit.mp3'),
      M3uWriteItem(path: 'a:b.mp3'),
    ]);
    expect(p.entries.map((e) => e.text), ['./#1 hit.mp3', './a:b.mp3']);
  });

  test('skipped items leave no trace and keep the others in order', () {
    final r = writeM3u(const [
      M3uWriteItem(path: '/a'),
      M3uWriteItem(path: '/bad\npath'),
      M3uWriteItem(path: '/b'),
    ]);
    expect(r.skipped, 1);
    final p = parseM3u(Uint8List.fromList(utf8.encode(r.text)));
    expect(p.entries.map((e) => e.text), ['/a', '/b']);
  });

  test('relative: EXTINF title, artist and duration survive', () {
    final items = [
      M3uWriteItem(
        path: relativeM3uPath('/music/lists', '/music/Nhạc/a.mp3'),
        title: 'Đêm',
        artist: 'Ca sĩ',
        durationMs: 61000,
      ),
    ];
    final x = roundTrip(items).entries.single;
    expect(x.text, '../Nhạc/a.mp3');
    expect((x.extinf!.title, x.extinf!.artist, x.extinf!.durationMs),
        ('Đêm', 'Ca sĩ', 61000));
  });
}
