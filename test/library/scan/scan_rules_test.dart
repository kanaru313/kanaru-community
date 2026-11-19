import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan/scan_rules.dart';
import 'package:kanaru/src/storage/domain/local_folder_listing.dart';

ListedFile _file(String locator, {int size = 5000000}) =>
    ListedFile(locator: locator, sizeBytes: size, mtimeMs: 1);

void main() {
  test('default rules accept every scanned format at any size', () {
    final r = ScanRules.defaults;
    expect(r.accepts(_file('a/b.FLAC', size: 1)), isTrue);
    expect(r.accepts(_file('x.dff')), isTrue);
    expect(r.minDurationMs, 30000);
  });

  test('a disabled format is refused, case-insensitively', () {
    final r = ScanRules(allowedExtensions: {'mp3'});
    expect(r.accepts(_file('a.mp3')), isTrue);
    expect(r.accepts(_file('a.FLAC')), isFalse);
    expect(r.accepts(_file('noext')), isFalse);
  });

  test('size below the minimum is refused, equal is kept', () {
    final r = ScanRules(minSizeBytes: 1000000);
    expect(r.accepts(_file('a.mp3', size: 999999)), isFalse);
    expect(r.accepts(_file('a.mp3', size: 1000000)), isTrue);
  });

  test('an unknown size (0 or less) is never filtered', () {
    final r = ScanRules(minSizeBytes: 10000000);
    expect(r.accepts(_file('a.mp3', size: 0)), isTrue);
    expect(r.accepts(_file('a.mp3', size: -1)), isTrue);
  });

  test('applyTo counts drops in ruleOut and keeps filteredOut', () {
    final listing = SourceListing(
      files: [_file('a.mp3'), _file('b.flac'), _file('c.mp3', size: 10)],
      excludedOut: 2,
      shortOut: 1,
      ruleOut: 4,
    );
    final out = ScanRules(
      minSizeBytes: 100000,
      allowedExtensions: {'mp3'},
    ).applyTo(listing);
    expect(out.files.map((f) => f.locator), ['a.mp3']);
    expect(out.ruleOut, 6);
    expect(out.filteredOut, listing.filteredOut);
    expect(out.excludedOut, 2);
  });

  test('applyTo returns an unreachable listing as it is', () {
    const listing = SourceListing.unreachable();
    expect(identical(ScanRules.defaults.applyTo(listing), listing), isTrue);
  });
}
