import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/ids/stable_uid.dart';

void main() {
  test('stableUid matches fixed vectors', () {
    expect(stableUid('x', ['a', 'b']), 'x:f04cdced9736a69d');
    expect(
      stableUid('src', ['src', 'local', '', '/music']),
      'src:9b12751fc8d74a71',
    );
  });

  test('stableHashHex joins with the unit separator and truncates', () {
    expect(
      stableHashHex(['a'], 64),
      'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb',
    );
    expect(
      stableHashHex(const [], 64),
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
    expect(stableHashHex(['a', 'b'], 8), 'f04cdced');
    expect(stableHashHex(['a', ''], 8), '69fc94c0');
  });

  test('part boundaries matter', () {
    expect(
      stableHashHex(['a', 'bc'], 16),
      isNot(stableHashHex(['ab', 'c'], 16)),
    );
  });

  test('non-ASCII parts are hashed as UTF-8', () {
    expect(stableHashHex(['日本'], 16), 'cf2abf0c5be326cb');
    expect(stableHashHex(['日本'], 16), isNot(stableHashHex(['日'], 16)));
  });

  test('rejects an invalid length', () {
    expect(() => stableHashHex(['a'], 0), throwsRangeError);
    expect(() => stableHashHex(['a'], 65), throwsRangeError);
  });
}
