import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/library/data/m3u/m3u_index_check.dart';
import 'package:kanaru/src/library/data/m3u/m3u_results.dart';
import 'package:kanaru/src/library/data/m3u/m3u_scan_rules.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';

import '../scan/support/pipeline_fixtures.dart';
import 'support/m3u_env.dart';

/// What "MediaStore shows" per folder. A root in [throwing] throws, one in
/// [hanging] never answers; every listed root is recorded and the short
/// filter must stay off.
class _Catalog extends MapCatalog {
  _Catalog(super.listings);

  final throwing = <String>{};
  final hanging = <String>{};
  final slow = <String>{};

  @override
  Future<AudioListing> listAudio({
    required String root,
    required Set<String> excludedKeys,
    int skipShorterThanMs = 0,
  }) {
    expect(skipShorterThanMs, 0);
    if (throwing.contains(root)) throw StateError('boom');
    if (hanging.contains(root)) return Completer<AudioListing>().future;
    if (slow.contains(root)) {
      listed.add(root);
      return Future<AudioListing>.delayed(
        const Duration(milliseconds: 150),
        () => const AudioListing(),
      );
    }
    return super.listAudio(
      root: root,
      excludedKeys: excludedKeys,
      skipShorterThanMs: skipShorterThanMs,
    );
  }

  @override
  Future<MediaIndexRefresh> refreshMediaIndex({
    required List<String> volumeRoots,
    required List<String> folders,
  }) => throw StateError('the import must never start a media scan');
}

AudioListing _listing(Map<String, int?> files) => AudioListing(
  audio: [
    for (final e in files.entries)
      LocalAudioFile(
        path: e.key,
        sizeBytes: 100,
        mtimeMs: 10,
        durationMs: e.value,
      ),
  ],
);

void main() {
  late M3uEnv env;
  late String hidden;
  late String listText;
  late String newDir;

  setUp(() async {
    env = await M3uEnv.open();
    env.file('a.mp3');
    hidden = env.file('_new/moi-chua-quet.mp3');
    newDir = '${env.music}/_new';
    listText = '#EXTINF:180,Bài mới chép vào\n$hidden\n${env.music}/a.mp3\n';
  });

  Future<List<String>> locators() async => [
    for (final t in await env.db.select(env.db.tracks).get()) t.locator,
  ];

  /// The scan root's listing: a.mp3 plus [extra]. The parents `music` and
  /// `music/_new` collapse to one listing of `music`.
  _Catalog catalog([Map<String, int?> extra = const {}]) => _Catalog({
    env.music: _listing({'${env.music}/a.mp3': 180000, ...extra}),
  });

  Future<Result<M3uImportResult, M3uImportError>> run(
    _Catalog c, {
    bool android = true,
    ShortTrackRule short = const ShortTrackRule.off(),
    Duration budget = m3uIndexCheckBudget,
  }) => env
      .service(
        androidStorage: android,
        short: short,
        indexCheck: catalogIndexCheck(c, short: short, budget: budget),
      )
      .importDocument(env.list(listText), fallbackName: 'x');

  M3uImportResult ok(Result<M3uImportResult, M3uImportError> r) =>
      (r as Ok<M3uImportResult, M3uImportError>).value;

  test('file on disk but not in the listing: notIndexed, no row', () async {
    final r = ok(await run(catalog()));
    expect(r.problems.map((p) => p.kind), [M3uProblemKind.notIndexed]);
    expect(r.notIndexed, 1);
    expect(r.added, 1);
    expect(r.clean, isFalse);
    expect(await locators(), isNot(contains('_new/moi-chua-quet.mp3')));
  });

  test('a listed file keeps its placeholder; no scan is started', () async {
    final c = catalog({hidden: 180000});
    final r = ok(await run(c));
    expect(r.problems, isEmpty);
    expect(r.added, 2);
    expect(await locators(), contains('_new/moi-chua-quet.mp3'));
  });

  test('listed but short while skip-short is on: notScanned', () async {
    final c = catalog({hidden: 5000});
    final r = ok(await run(c, short: const ShortTrackRule(enabled: true)));
    expect(r.problems.map((p) => p.kind), [M3uProblemKind.notScanned]);
    expect(r.notScanned, 1);
    expect(r.notIndexed, 0);
  });

  test('the listing spelling is the placeholder locator', () async {
    final c = catalog({'${env.music}/_new/Moi-Chua-Quet.MP3': 180000});
    final r = ok(await run(c));
    expect(r.problems, isEmpty);
    expect(await locators(), contains('_new/Moi-Chua-Quet.MP3'));
    expect(await locators(), isNot(contains('_new/moi-chua-quet.mp3')));
  });

  test('a throwing listing: placeholder kept, import succeeds', () async {
    final c = catalog()..throwing.add(env.music);
    final r = ok(await run(c));
    expect(r.notIndexed, 0);
    expect(r.added, 2);
    expect(await locators(), contains('_new/moi-chua-quet.mp3'));
  });

  test('an unreachable listing is not claimed as notIndexed', () async {
    final c = _Catalog({
      env.music: const AudioListing.unreachable(UnreachableReason.permission),
    });
    final r = ok(await run(c));
    expect(r.notIndexed, 0);
    expect(await locators(), contains('_new/moi-chua-quet.mp3'));
  });

  test('a listing that never answers: budget ends, placeholder kept', () async {
    final c = catalog()..hanging.add(env.music);
    final r = ok(await run(c, budget: const Duration(milliseconds: 50)));
    expect(r.notIndexed, 0);
    expect(r.added, 2);
  });

  test('after the budget ends no further folder is listed', () async {
    env.file('other/y.mp3');
    final other = '${env.music}/other';
    final c = _Catalog({other: const AudioListing()})..slow.add(newDir);
    final check = catalogIndexCheck(
      c,
      budget: const Duration(milliseconds: 50),
    );
    final v = await check([hidden, '$other/y.mp3']);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(v, isEmpty);
    expect(c.listed, [newDir]);
  });

  test('nested folders are listed once through the ancestor', () async {
    env.file('_new/deep/x.mp3');
    final deep = '$newDir/deep/x.mp3';
    listText = '$hidden\n$deep\n';
    final c = _Catalog({
      newDir: _listing({hidden: 180000, deep: 180000}),
    });
    final r = ok(await run(c));
    expect(r.problems, isEmpty);
    expect(c.listed, [newDir]);
  });

  test(
    'a volume root is never listed; its files keep the placeholder',
    () async {
      final check = catalogIndexCheck(catalog());
      final verdicts = await check(['/storage/emulated/0/x.mp3']);
      expect(verdicts, isEmpty);
    },
  );

  test('only not-indexed lines: the notIndexed refusal', () async {
    listText = '$hidden\n${env.tmp}/elsewhere/x.mp3\n';
    final r = await run(_Catalog({newDir: const AudioListing()}));
    expect(
      (r as Err<M3uImportResult, M3uImportError>).error,
      M3uImportError.notIndexed,
    );
    expect(await locators(), isNot(contains('_new/moi-chua-quet.mp3')));
  });

  test('Linux: placeholder created without any check', () async {
    final c = catalog();
    final r = ok(await run(c, android: false));
    expect(r.notIndexed, 0);
    expect(r.added, 2);
    expect(await locators(), contains('_new/moi-chua-quet.mp3'));
    expect(c.listed, isEmpty);
  });
}
