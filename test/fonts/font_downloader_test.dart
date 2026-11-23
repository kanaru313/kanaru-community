import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/fonts/data/font_downloader.dart';
import 'package:kanaru/src/fonts/data/font_registrar.dart';
import 'package:kanaru/src/fonts/data/font_storage.dart';
import 'package:kanaru/src/fonts/data/zip_font_extractor.dart';
import 'package:kanaru/src/fonts/domain/font_catalog.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/data/net/fetcher.dart';
import 'package:kanaru/src/plugins/domain/net/address_rules.dart';
import 'package:kanaru/src/plugins/domain/net/cancel_token.dart';
import 'package:kanaru/src/plugins/domain/net/fetch_failure.dart';
import 'package:kanaru/src/plugins/domain/net/net_policy.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';

import '../plugins/fixtures/zip_builders.dart';

class _Paths implements AppPaths {
  _Paths(this.dataDir);
  @override
  final Directory dataDir;
  @override
  Directory get cacheDir => dataDir;
  @override
  Directory get configDir => dataDir;
}

/// Serves [bytes] (or [failure]) and remembers what was asked.
class _FakeFetcher extends HttpFetcher {
  _FakeFetcher(this.bytes);
  Uint8List bytes;
  FetchFailure? failure;
  final calls = <(Uri, NetPolicy, int?)>[];

  @override
  Future<Result<FetchResult, FetchFailure>> get(
    Uri uri,
    NetPolicy policy, {
    AddressKind? catalogKind,
    int? maxBytes,
    int? expectedSize,
    CancelToken? cancel,
    void Function(int received, int? total)? onProgress,
  }) async {
    calls.add((uri, policy, maxBytes));
    final f = failure;
    if (f != null) return Err(f);
    return Ok(
      FetchResult(
        bytes: bytes,
        finalUrl: uri,
        kind: catalogKind ?? AddressKind.public,
      ),
    );
  }
}

void main() {
  late Directory tmp;
  late FontStorage storage;
  late _FakeFetcher fetcher;
  late List<String> loaded;
  late FontRegistrar registrar;
  late CatalogFont font;

  FontDownloader downloader({DirectoryMover? mover}) => FontDownloader(
    fetcher: fetcher,
    storage: storage,
    registrar: registrar,
    extractor: (zip) async => extractFontZip(zip),
    mover: mover ?? (from, to) => from.renameSync(to),
  );

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('font_downloader');
    storage = FontStorage(_Paths(tmp));
    loaded = [];
    registrar = FontRegistrar(registrar: (f, _) async => loaded.add(f));
    final zip = buildZip({
      'Lato/Lato-Regular.ttf': Uint8List.fromList([1, 2, 3]),
      'Lato/OFL.txt': 'licence',
    });
    fetcher = _FakeFetcher(zip);
    font = CatalogFont(
      id: 'lato',
      label: 'Lato',
      family: 'Lato',
      designer: 'x',
      license: 'OFL-1.1',
      filename: 'lato.zip',
      sizeBytes: zip.length,
      sha256: sha256.convert(zip).toString(),
    );
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  List<String> leftovers() => storage.catalogDir.existsSync()
      ? [for (final e in storage.catalogDir.listSync()) e.path.split('/').last]
      : [];

  test(
    'installs: fetched under the public policy, capped at twice the size',
    () async {
      await downloader().download(font);
      expect(storage.installedCatalogIds(), {'lato'});
      expect(leftovers(), ['lato']);
      expect(loaded, ['Lato']);
      final (uri, policy, cap) = fetcher.calls.single;
      expect(uri, font.downloadUri);
      expect(policy, NetPolicy.package);
      expect(cap, font.sizeBytes * 2);
      expect(storage.licenseFiles(font.asAppFont), hasLength(1));
    },
  );

  test('a checksum mismatch leaves nothing', () async {
    fetcher.bytes = Uint8List.fromList([...fetcher.bytes]..[10] ^= 0xff);
    await expectLater(
      downloader().download(font),
      throwsA(isA<FontDownloadException>()),
    );
    expect(leftovers(), isEmpty);
    expect(loaded, isEmpty);
  });

  test('a failed fetch leaves nothing', () async {
    fetcher.failure = const FetchFailure(FetchFailureKind.network);
    await expectLater(
      downloader().download(font),
      throwsA(isA<FontDownloadException>()),
    );
    expect(leftovers(), isEmpty);
  });

  test('a rename failure leaves nothing', () async {
    await expectLater(
      downloader(mover: (_, _) => throw const FileSystemException('no space'))
          .download(font),
      throwsA(isA<FontDownloadException>()),
    );
    expect(leftovers(), isEmpty);
    expect(storage.installedCatalogIds(), isEmpty);
  });

  test('an engine load failure removes the installed folder', () async {
    registrar = FontRegistrar(
      registrar: (_, _) async => throw StateError('bad font'),
    );
    await expectLater(
      downloader().download(font),
      throwsA(isA<FontDownloadException>()),
    );
    expect(leftovers(), isEmpty);
  });

  test('a zip without a font leaves nothing', () async {
    final zip = buildZip({'OFL.txt': 'x'});
    fetcher.bytes = zip;
    font = CatalogFont(
      id: 'lato',
      label: 'Lato',
      family: 'Lato',
      designer: 'x',
      license: 'OFL-1.1',
      filename: 'lato.zip',
      sizeBytes: zip.length,
      sha256: sha256.convert(zip).toString(),
    );
    await expectLater(
      downloader().download(font),
      throwsA(isA<FontDownloadException>()),
    );
    expect(leftovers(), isEmpty);
  });

  test(
    'an installed font is never overwritten or removed by a failure',
    () async {
      await downloader().download(font);
      fetcher.failure = const FetchFailure(FetchFailureKind.network);
      await expectLater(
        downloader().download(font),
        throwsA(isA<FontDownloadException>()),
      );
      expect(storage.installedCatalogIds(), {'lato'});
    },
  );

  test('installedCatalogIds ignores staging and empty folders', () {
    Directory('${storage.catalogDir.path}/lora.tmp')
        .createSync(recursive: true);
    Directory('${storage.catalogDir.path}/empty').createSync(recursive: true);
    expect(storage.installedCatalogIds(), isEmpty);
  });

  test('catalog entries are well formed', () {
    for (final f in catalogFonts) {
      expect(f.downloadUri.toString(), startsWith('https://github.com/'));
      expect(f.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
    }
    expect(catalogFontById('be-vietnam-pro')!.formattedSize, '160 KB');
  });
}
