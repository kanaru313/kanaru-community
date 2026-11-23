import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/kanaru.dart';
import 'package:material_ui/material_ui.dart';

SongDetailSection _section(String id, int order) =>
    SongDetailSection(id: id, order: order, build: (_, trackId) => Text(id));

void main() {
  test('starts empty', () {
    expect(ExtensionRegistry().songDetailSections, isEmpty);
  });

  test('sorts by order, ties keep registration order', () {
    final r = ExtensionRegistry()
      ..addSongDetailSection(_section('b', 2))
      ..addSongDetailSection(_section('a', 1))
      ..addSongDetailSection(_section('c', 2));
    expect(r.songDetailSections.map((s) => s.id), ['a', 'b', 'c']);
  });

  test('a repeated id throws', () {
    final r = ExtensionRegistry()..addSongDetailSection(_section('a', 1));
    expect(() => r.addSongDetailSection(_section('a', 2)), throwsStateError);
  });

  test('the list cannot be changed from outside', () {
    final r = ExtensionRegistry()..addSongDetailSection(_section('a', 1));
    expect(
      () => r.songDetailSections.add(_section('x', 9)),
      throwsUnsupportedError,
    );
  });

  testWidgets('build receives the track id', (tester) async {
    int? seen;
    final r = ExtensionRegistry()
      ..addSongDetailSection(
        SongDetailSection(
          id: 'a',
          order: 1,
          build: (_, trackId) {
            seen = trackId;
            return const SizedBox();
          },
        ),
      );
    await tester.pumpWidget(
      Builder(builder: (c) => r.songDetailSections.single.build(c, 42)),
    );
    expect(seen, 42);
  });
}
