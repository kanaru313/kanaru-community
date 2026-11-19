import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan/format_groups.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';

void main() {
  test('the groups together hold exactly the scanned extensions', () {
    expect(allGroupExtensions, audioExtensions);
  });

  test('no extension is in two groups', () {
    final all = [for (final g in formatGroups) ...g.extensions];
    expect(all.length, all.toSet().length);
  });

  test('group ids are unique and in the listed order', () {
    expect(allFormatGroupIds, [
      'mp3',
      'flac',
      'm4a',
      'ogg',
      'wav',
      'aiff',
      'ape',
      'wavpack',
      'dsd',
    ]);
  });

  test('extensionsOfGroups ignores unknown ids', () {
    expect(extensionsOfGroups(['ogg', 'nope']), {'ogg', 'oga', 'opus'});
    expect(extensionsOfGroups(const []), isEmpty);
  });

  test('lossless extensions are scanned extensions and leave out .m4a', () {
    expect(audioExtensions.containsAll(losslessExtensions), isTrue);
    expect(losslessExtensions, isNot(contains('m4a')));
    expect(losslessExtensions, isNot(contains('mp3')));
  });
}
