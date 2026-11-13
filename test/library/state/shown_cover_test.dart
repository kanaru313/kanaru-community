import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:kanaru/src/library/state/browse/custom_cover_index_providers.dart';
import 'package:kanaru/src/media/domain/cover_files.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/state/shown_cover_provider.dart';
import 'package:kanaru/src/library/ui/browse/item_covers.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

const _item = (kind: CustomCoverKind.album, itemKey: 'album-1');
const _hex = '00000000000000000000000000000001';
const _customKey = 'ab/$_hex';

ShownCoverQuery _query([String? auto = 'aaaaaaaaaaaaaaaa']) =>
    (item: _item, automaticCoverKey: auto);

/// Overrides for an index holding [indexed] (null: never answers), a file
/// stream [file] and a key stream [key].
List<Override> _overrides({
  Set<String>? indexed,
  Stream<File?>? file,
  Stream<Set<String>>? indexStream,
}) => [
  customCoverIndexProvider.overrideWith(
    (ref, kind) =>
        indexStream ??
        (indexed == null ? const Stream.empty() : Stream.value(indexed)),
  ),
  customCoverFileProvider.overrideWith(
    (ref, item) => file ?? Stream.value(null),
  ),
];

Future<ShownCover> _read(List<Override> overrides, [String? auto]) async {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);
  final query = auto == null ? _query() : _query(auto);
  final sub = container.listen(shownCoverProvider(query), (_, _) {});
  await Future<void>.delayed(const Duration(milliseconds: 5));
  await Future<void>.delayed(const Duration(milliseconds: 5));
  final value = sub.read();
  sub.close();
  return value;
}

void main() {
  group('shownCoverProvider', () {
    test('is loading while the custom cover index has not answered', () async {
      expect(await _read(_overrides()), isA<ShownCoverLoading>());
    });

    test('an item outside the index shows the automatic cover', () async {
      final shown = await _read(_overrides(indexed: {'other'}));
      expect(shown, const ShownAutomaticCover('aaaaaaaaaaaaaaaa'));
    });

    test('no automatic cover and no custom one is none', () async {
      final container = ProviderContainer(
        overrides: _overrides(indexed: const {}),
      );
      addTearDown(container.dispose);
      final sub = container.listen(shownCoverProvider(_query(null)), (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(sub.read(), const ShownAutomaticCover(null));
    });

    test('is loading while the chosen file resolves, no automatic first', () {
      final never = StreamController<File?>();
      addTearDown(never.close);
      return _read(_overrides(indexed: {'album-1'}, file: never.stream))
          .then((shown) => expect(shown, isA<ShownCoverLoading>()));
    });

    test(
      'a chosen file that exists is the custom cover with its key',
      () async {
        final dir = Directory.systemTemp.createTempSync('shown_cover');
        addTearDown(() => dir.deleteSync(recursive: true));
        final file =
            File('${dir.path}/covers/full/ab/${_customKey.substring(3)}.jpg')
              ..createSync(recursive: true)
              ..writeAsBytesSync([1]);
        final shown = await _read(
          _overrides(indexed: {'album-1'}, file: Stream.value(file)),
        );
        expect(shown, ShownCustomCover(_customKey, file));
      },
    );

    test('a chosen file that is missing falls back to the automatic cover', () {
      return _read(_overrides(indexed: {'album-1'}, file: Stream.value(null)))
          .then(
            (shown) =>
                expect(shown, const ShownAutomaticCover('aaaaaaaaaaaaaaaa')),
          );
    });
  });

  test('a custom file outside the cover layout is not used', () async {
    final dir = Directory.systemTemp.createTempSync('shown_cover');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/full.png')..writeAsBytesSync([1]);
    final shown = await _read(
      _overrides(indexed: {'album-1'}, file: Stream.value(file)),
    );
    expect(shown, const ShownAutomaticCover('aaaaaaaaaaaaaaaa'));
    expect(
      customCoverKeyOfFile(File('/x/covers/full/ab/$_hex.jpg')),
      _customKey,
    );
  });

  test('an index that fails means no custom cover, and is logged', () async {
    resetCoverIndexErrorLog();
    final records = <LogRecord>[];
    final sub = Logger.root.onRecord.listen(records.add);
    addTearDown(sub.cancel);
    final shown = await _read(
      _overrides(indexStream: Stream<Set<String>>.error(StateError('boom'))),
    );
    expect(shown, const ShownAutomaticCover('aaaaaaaaaaaaaaaa'));
    expect(
      records.where((r) => r.loggerName == 'library.covers'),
      hasLength(1),
    );
  });

  test('every distinct index failure is logged once', () async {
    resetCoverIndexErrorLog();
    final records = <LogRecord>[];
    final sub = Logger.root.onRecord.listen(records.add);
    addTearDown(sub.cancel);
    for (final e in [StateError('a'), StateError('a'), StateError('b')]) {
      await _read(_overrides(indexStream: Stream<Set<String>>.error(e)));
    }
    expect(
      records.where((r) => r.loggerName == 'library.covers'),
      hasLength(2),
    );
  });

  test('the key of a custom file round-trips for every size', () {
    for (final size in CoverSize.values) {
      final file = File(
        '/data/custom_covers/${coverRelativePath(_customKey, size)}',
      );
      expect(customCoverKeyOfFile(file), _customKey);
    }
  });

  test('the last answer stays while a new one is being read', () async {
    final dir = Directory.systemTemp.createTempSync('shown_cover');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/covers/full/ab/$_hex.jpg')
      ..createSync(recursive: true)
      ..writeAsBytesSync([1]);
    final index = StreamController<Set<String>>();
    final files = StreamController<File?>();
    addTearDown(index.close);
    addTearDown(files.close);
    final container = ProviderContainer(
      overrides: _overrides(indexStream: index.stream, file: files.stream),
    );
    addTearDown(container.dispose);
    final seen = <ShownCover>[];
    container.listen(shownCoverProvider(_query()), (_, next) => seen.add(next));
    // Held for the whole test so the index provider keeps its value.
    container.listen(
      customCoverIndexProvider(CustomCoverKind.album),
      (_, _) {},
    );
    index.add(const {});
    await Future<void>.delayed(const Duration(milliseconds: 5));
    // A cover is chosen: the file is not read yet.
    index.add({'album-1'});
    await Future<void>.delayed(const Duration(milliseconds: 5));
    files.add(file);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(seen.whereType<ShownCoverLoading>(), isEmpty);
    expect(seen.last, ShownCustomCover(_customKey, file));
  });

  testWidgets('an album cover is the skeleton, not the source cover, while '
      'the index loads', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: const MaterialApp(
          home: Center(
            child: AlbumCover(
              itemKey: 'album-1',
              coverKey: 'aaaaaaaaaaaaaaaa',
              dimension: 64,
            ),
          ),
        ),
      ),
    );
    final cover = tester.widget<KCover>(find.byType(KCover));
    expect(cover.loading, isTrue);
    expect(cover.size, 64);
  });
}
