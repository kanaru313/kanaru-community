import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_cover_rule.dart';

List<({String group, String? coverKey})> items(int n) => [
  for (var i = 0; i < n; i++) (group: 'g$i', coverKey: 'c$i'),
];

void main() {
  test('0, 1, 3 and 4 groups return their keys in order', () {
    expect(pickAutoCoverKeys(const []), isEmpty);
    expect(pickAutoCoverKeys(items(1)), ['c0']);
    expect(pickAutoCoverKeys(items(3)), ['c0', 'c1', 'c2']);
    expect(pickAutoCoverKeys(items(4)), ['c0', 'c1', 'c2', 'c3']);
  });

  test('more groups are cut at the limit', () {
    expect(pickAutoCoverKeys(items(9)), hasLength(4));
    expect(pickAutoCoverKeys(items(9), limit: 6), hasLength(6));
  });

  test('tracks without a cover key are skipped', () {
    final r = pickAutoCoverKeys([
      (group: 'a', coverKey: null),
      (group: 'b', coverKey: 'cb'),
    ]);
    expect(r, ['cb']);
  });

  test('a group seen again counts once', () {
    final r = pickAutoCoverKeys([
      (group: 'album', coverKey: 'c1'),
      (group: 'album', coverKey: 'c1'),
      (group: 'track:2', coverKey: 'c2'),
    ]);
    expect(r, ['c1', 'c2']);
  });

  test('two groups with the same cover key give one tile', () {
    final r = pickAutoCoverKeys([
      (group: 'a', coverKey: 'shared'),
      (group: 'b', coverKey: 'shared'),
      (group: 'c', coverKey: 'c3'),
    ]);
    expect(r, ['shared', 'c3']);
  });

  test('a skipped duplicate group does not use up the limit', () {
    final r = pickAutoCoverKeys([
      (group: 'a', coverKey: 'k1'),
      (group: 'b', coverKey: 'k1'),
      (group: 'c', coverKey: 'k2'),
    ], limit: 2);
    expect(r, ['k1', 'k2']);
  });

  test('one group with different keys counts once (first key wins)', () {
    final r = pickAutoCoverKeys([
      (group: 'album', coverKey: 'k1'),
      (group: 'album', coverKey: 'k2'),
      (group: 'other', coverKey: 'k3'),
    ]);
    expect(r, ['k1', 'k3']);
  });
}
