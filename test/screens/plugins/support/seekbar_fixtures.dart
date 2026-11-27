import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/database/tables.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/install/held_package.dart';
import 'package:kanaru/src/plugins/domain/package/package_reader.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_manifest.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_package.dart';
import 'package:kanaru/src/plugins/domain/package/manifest_parser.dart';

import '../../../plugins/fixtures/image_bytes.dart';
import '../../../plugins/fixtures/zip_builders.dart';

/// The `seekbar` block of a flat bar with one 16 x 16 sprite thumb.
Map<String, Object?> flatWithThumb() => {
  'track': {'kind': 'flat'},
  'thumb': {
    'image': 'assets/t.png',
    'frames': 1,
    'size': [16, 16],
  },
};

String seekbarJson({
  String name = 'Neon',
  String license = 'CC0-1.0',
  Map<String, Object?>? seekbar,
}) => jsonEncode({
  'metadata': {
    'apiVersion': 1,
    'type': 'seekbar',
    'name': name,
    'version': 2,
    'author': 'someone',
    'license': license,
    'description': 'A glowing bar',
  },
  'seekbar':
      seekbar ??
      {
        'track': {'kind': 'flat'},
      },
});

/// A seek bar package read from a real zip.
PluginPackage seekbarPackage({
  String name = 'Neon',
  String license = 'CC0-1.0',
  Map<String, Object?>? seekbar,
}) {
  final block = seekbar ?? flatWithThumb();
  final withImage = block['thumb'] != null;
  final zip = buildZip({
    'plugin.json': seekbarJson(name: name, license: license, seekbar: block),
    if (withImage) 'assets/t.png': pngBytes(16, 16),
  });
  return switch (readPackage(zip)) {
    Ok(:final value) => value,
    Err(:final error) => fail('seek bar package refused: $error'),
  };
}

HeldPackage heldSeekbar({
  String name = 'Neon',
  Map<String, Object?>? seekbar,
  PackageReview review = const InstallReview(),
}) => HeldPackage(
  token: 'token-1',
  package: seekbarPackage(name: name, seekbar: seekbar),
  installId: 'id-demo',
  source: const RepoHeldSource(
    repoId: 1,
    repoUrl: 'https://repo1.example.com/plugins.json',
    slug: 'demo',
  ),
  review: review,
  snapshot: null,
);

/// The manifest the page of an installed seek bar plugin reads.
PluginManifest seekbarManifestOf({
  String name = 'Neon',
  String license = 'CC0-1.0',
  Map<String, Object?>? seekbar,
}) => switch (parseManifest(
  seekbarJson(
    name: name,
    license: license,
    seekbar: seekbar ?? flatWithThumb(),
  ),
)) {
  Ok(:final value) => value,
  Err(:final error) => fail('manifest refused: $error'),
};

/// An installed seek bar row, shaped like the page fixtures' rows.
PluginRow seekbarRow({String name = 'Neon'}) => PluginRow(
  installId: 'id-demo',
  kind: 'seekbar',
  name: name,
  author: 'someone',
  version: 2,
  apiVersion: 1,
  manifestJson: '{}',
  packageSha256: 'a' * 64,
  origin: 'repo',
  repoUrl: 'https://repo1.example.com/plugins.json',
  repoSlug: 'demo',
  consentedHostsJson: '[]',
  installedAt: 1762041600000,
  updatedAt: 1762041600000,
);
