import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/plugins/domain/catalog/catalog.dart';
import 'package:kanaru/src/plugins/domain/catalog/catalog_parser.dart';

Map<String, Object?> entryJson([Map<String, Object?> over = const {}]) => {
  'slug': 'netease',
  'name': 'NetEase Cloud Music',
  'version': 3,
  'apiVersion': 1,
  'type': 'lyrics',
  'hosts': ['music.163.com'],
  'path': 'https://cdn.example.com/netease/plugin.zip',
  ...over,
};

Uint8List jsonBytes(Object? value) =>
    Uint8List.fromList(utf8.encode(jsonEncode(value)));

Map<String, Object?> catalogJson(List<Object?> data) => {
  'metadata': {'name': 'Kho của hieu05', 'author': 'hieu05'},
  'data': data,
};

final catalogUrl = Uri.parse('https://repo.example.com/plugins.json');

Result<Catalog, CatalogProblem> parseJson(
  Object? json, {
  Uri? url,
  bool Function(Uri)? allowed,
}) => parseCatalog(
  jsonBytes(json),
  url ?? catalogUrl,
  isReferenceAllowed: allowed ?? allowAll,
);

bool allowAll(Uri _) => true;

Catalog okCatalog(Object? json, {Uri? url, bool Function(Uri)? allowed}) =>
    switch (parseJson(json, url: url, allowed: allowed)) {
      Ok(:final value) => value,
      Err(:final error) => fail('refused: $error'),
    };

CatalogProblem problemOfCatalog(Object? json) => switch (parseJson(json)) {
  Ok() => fail('the catalog was accepted'),
  Err(:final error) => error,
};
