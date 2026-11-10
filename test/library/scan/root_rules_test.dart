import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan/root_rules.dart';

void main() {
  test('/ and empty are too broad', () {
    expect(checkNewRoot('/', const []), isA<RootTooBroad>());
    expect(checkNewRoot('///', const []), isA<RootTooBroad>());
    expect(checkNewRoot('  ', const []), isA<RootTooBroad>());
  });

  test('a folder inside an existing root is refused', () {
    final r = checkNewRoot('/m/Live/2020', ['/m/Live']);
    expect(r, isA<RootInsideExisting>());
    expect((r as RootInsideExisting).root, '/m/Live');
  });

  test('the same folder counts as inside', () {
    expect(checkNewRoot('/m/Live', ['/m/Live']), isA<RootInsideExisting>());
  });

  test('a folder containing an existing root is refused', () {
    final r = checkNewRoot('/m', ['/x', '/m/Live']);
    expect(r, isA<RootContainsExisting>());
    expect((r as RootContainsExisting).root, '/m/Live');
  });

  test('siblings with a shared name prefix are fine', () {
    expect(checkNewRoot('/m/Live Albums', ['/m/Live']), isA<RootOk>());
    expect(checkNewRoot('/m/Live', ['/m/Live Albums']), isA<RootOk>());
    expect(checkNewRoot('/m/a', const []), isA<RootOk>());
  });

  test('trailing slashes are ignored on both sides', () {
    expect(checkNewRoot('/m/Live/', ['/m/Live']), isA<RootInsideExisting>());
    expect(checkNewRoot('/m/', ['/m/Live/']), isA<RootContainsExisting>());
    expect(checkNewRoot('/m/Live Albums/', ['/m/Live/']), isA<RootOk>());
  });
}
