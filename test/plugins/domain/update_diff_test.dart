import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/catalog/catalog.dart';
import 'package:kanaru/src/plugins/domain/install/update_diff.dart';
import 'package:kanaru/src/plugins/domain/package/package_reader.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_package.dart';

import '../fixtures/zip_builders.dart';
import 'plugin_test_support.dart';

UpdateDiff _diff({
  List<String> consented = const ['music.example.com'],
  int installedVersion = 3,
  PluginKind installedKind = PluginKind.lyrics,
  int version = 4,
  PluginKind? kind = PluginKind.lyrics,
  List<String> hosts = const ['music.example.com'],
}) => diffUpdate(
  consentedHosts: consented,
  installedVersion: installedVersion,
  installedKind: installedKind,
  candidate: UpdateCandidate(version: version, kind: kind, hosts: hosts),
);

PluginPackage _package(Map<String, Object?> manifest) =>
    switch (readPackage(validZip(manifest: manifest))) {
      Ok(:final value) => value,
      Err(:final error) => fail('refused: $error'),
    };

CatalogEntry _entry({
  PluginKind? kind = PluginKind.lyrics,
  int version = 3,
  List<String> hosts = const ['music.example.com'],
  String? sha256,
  int? size,
}) => CatalogEntry(
  slug: 'demo',
  kind: kind,
  name: 'Demo',
  version: version,
  apiVersion: 1,
  hosts: hosts,
  path: Uri.parse('https://r.example.com/demo.zip'),
  sha256: sha256,
  size: size,
);

void main() {
  group('diffUpdate', () {
    test('a newer version with the same hosts needs no review', () {
      final d = _diff();
      expect(d.versionOrder, VersionOrder.newer);
      expect(d.newHosts, isEmpty);
      expect(d.needsReview, isFalse);
      expect(d.kindChange, KindChange.none);
    });

    test('same and older versions', () {
      expect(_diff(version: 3).versionOrder, VersionOrder.same);
      expect(_diff(version: 2).versionOrder, VersionOrder.older);
    });

    test('a new host needs review and is listed in candidate order', () {
      final d = _diff(
        hosts: ['z.example.com', 'music.example.com', 'a.example.com'],
      );
      expect(d.newHosts, ['z.example.com', 'a.example.com']);
      expect(d.needsReview, isTrue);
    });

    test('fewer hosts than consented needs no review', () {
      final d = _diff(
        consented: ['a.example.com', 'b.example.com'],
        hosts: ['a.example.com'],
      );
      expect(d.needsReview, isFalse);
    });

    test('a plain name under a consented wildcard is not new', () {
      final d = _diff(
        consented: ['*.googlevideo.com'],
        hosts: [
          'rr1.googlevideo.com',
          'a.b.googlevideo.com',
          'googlevideo.com',
        ],
      );
      expect(d.newHosts, ['a.b.googlevideo.com', 'googlevideo.com']);
    });

    test('a wildcard is covered only by the same wildcard', () {
      expect(
        _diff(
          consented: ['rr1.googlevideo.com'],
          hosts: ['*.googlevideo.com'],
        ).needsReview,
        isTrue,
      );
      expect(
        _diff(
          consented: ['*.googlevideo.com'],
          hosts: ['*.googlevideo.com'],
        ).needsReview,
        isFalse,
      );
    });

    test('kind change: same, translate family allowed, others refused', () {
      expect(
        _diff(
          installedKind: PluginKind.translate,
          kind: PluginKind.aiTranslate,
        ).kindChange,
        KindChange.allowed,
      );
      expect(
        _diff(
          installedKind: PluginKind.aiTranslate,
          kind: PluginKind.translate,
        ).kindChange,
        KindChange.allowed,
      );
      expect(
        _diff(
          installedKind: PluginKind.aiTranslate,
          kind: PluginKind.aiTranslate,
        ).kindChange,
        KindChange.none,
      );
      expect(_diff(kind: PluginKind.streaming).kindChange, KindChange.refused);
      expect(
        _diff(
          installedKind: PluginKind.aiTranslate,
          kind: PluginKind.aiChat,
        ).kindChange,
        KindChange.refused,
      );
      expect(
        _diff(
          installedKind: PluginKind.aiChat,
          kind: PluginKind.aiTranslate,
        ).kindChange,
        KindChange.refused,
      );
      expect(
        _diff(installedKind: PluginKind.aiChat, kind: PluginKind.aiChat)
            .kindChange,
        KindChange.none,
      );
      expect(
        _diff(
          installedKind: PluginKind.translate,
          kind: PluginKind.lyrics,
        ).kindChange,
        KindChange.refused,
      );
      expect(_diff(kind: null).kindChange, KindChange.refused);
    });

    test('works from a catalog entry and from a package alike', () {
      final entry = UpdateCandidate.fromEntry(
        _entry(version: 5, hosts: ['new.example.com']),
      );
      final fromEntry = diffUpdate(
        consentedHosts: ['music.example.com'],
        installedVersion: 3,
        installedKind: PluginKind.lyrics,
        candidate: entry,
      );
      final package = _package(
        withMeta((m) {
          m['version'] = 5;
          m['hosts'] = ['new.example.com'];
        }),
      );
      final fromPackage = diffUpdate(
        consentedHosts: ['music.example.com'],
        installedVersion: 3,
        installedKind: PluginKind.lyrics,
        candidate: UpdateCandidate.fromPackage(package),
      );
      expect(fromPackage.newHosts, fromEntry.newHosts);
      expect(fromPackage.versionOrder, fromEntry.versionOrder);
      expect(fromPackage.needsReview, isTrue);
    });
  });

  group('catalogMatches', () {
    // validManifest: lyrics, version 3, host music.example.com.
    test('an entry that agrees gives no difference', () {
      final package = _package(validManifest());
      expect(catalogMatches(_entry(), package), isEmpty);
    });

    test('kind, version and hosts differences', () {
      final package = _package(validManifest());
      expect(catalogMatches(_entry(kind: PluginKind.translate), package), [
        CatalogMismatch.kind,
      ]);
      expect(catalogMatches(_entry(kind: null), package), [
        CatalogMismatch.kind,
      ]);
      expect(catalogMatches(_entry(version: 4), package), [
        CatalogMismatch.version,
      ]);
      expect(catalogMatches(_entry(hosts: ['other.example.com']), package), [
        CatalogMismatch.hosts,
      ]);
      expect(
        catalogMatches(
          _entry(hosts: ['music.example.com', 'extra.example.com']),
          package,
        ),
        [CatalogMismatch.hosts],
      );
    });

    test('hosts compare as sets', () {
      final package = _package(
        withMeta((m) => m['hosts'] = ['b.example.com', 'a.example.com']),
      );
      expect(
        catalogMatches(
          _entry(hosts: ['a.example.com', 'b.example.com']),
          package,
        ),
        isEmpty,
      );
    });

    test('sha256 and size are compared only when the entry gives them', () {
      final zip = validZip();
      final package = switch (readPackage(zip)) {
        Ok(:final value) => value,
        Err(:final error) => fail('$error'),
      };
      expect(
        catalogMatches(
          _entry(sha256: package.sha256, size: zip.length),
          package,
        ),
        isEmpty,
      );
      expect(
        catalogMatches(_entry(sha256: 'a' * 64, size: zip.length + 1), package),
        [CatalogMismatch.sha256, CatalogMismatch.size],
      );
      expect(catalogMatches(_entry(), package), isEmpty);
    });

    test('several differences are all listed', () {
      final package = _package(validManifest());
      expect(
        catalogMatches(
          _entry(
            kind: PluginKind.streaming,
            version: 9,
            hosts: ['x.example.com'],
          ),
          package,
        ),
        [CatalogMismatch.kind, CatalogMismatch.version, CatalogMismatch.hosts],
      );
    });
  });
}
