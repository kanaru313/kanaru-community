import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import '../../../foundation/result.dart';
import 'manifest_parser.dart';
import 'package_problem.dart';
import 'plugin_package.dart';
import 'zip_reader.dart';

/// Reads a plugin zip: safe unpack in memory, manifest checks, every script
/// decoded, SHA-256 of the file. Returns the whole package or the first
/// problem found, never a part. Nothing is written and no script runs; the
/// syntax check of the scripts is a separate step (`ScriptChecker`).
///
/// Pure and synchronous, and CPU-bound for up to 5 MiB: callers run it in
/// `Isolate.run`.
Result<PluginPackage, PackageProblem> readPackage(Uint8List bytes) {
  try {
    return Ok(_read(bytes));
  } on PackageProblemError catch (e) {
    return Err(e.problem);
  }
}

PluginPackage _read(Uint8List bytes) {
  final contents = readZip(bytes);
  // `utf8.decode` drops a leading BOM, like `parseManifest` does.
  final String manifestText;
  try {
    manifestText = utf8.decode(contents.manifest);
  } on FormatException {
    throw const PackageProblemError(InvalidManifest('plugin.json'));
  }
  final parsed = parseManifest(manifestText);
  final manifest = switch (parsed) {
    Ok(:final value) => value,
    Err(:final error) => throw PackageProblemError(error.first),
  };
  final names = contents.scripts.keys.toList()..sort();
  final scripts = {
    for (final name in names)
      name: _decodeScript(name, contents.scripts[name]!),
  };
  for (final file in manifest.scriptFiles) {
    if (!scripts.containsKey(file)) {
      throw PackageProblemError(MissingScript(file));
    }
  }
  return PluginPackage(
    manifestBytes: contents.manifest,
    manifestText: manifestText,
    manifest: manifest,
    scripts: Map.unmodifiable(scripts),
    icon: contents.icon,
    sha256: crypto.sha256.convert(bytes).toString(),
    size: bytes.length,
  );
}

/// UTF-8 decode, BOM stripped; a script that is not UTF-8 is refused.
String _decodeScript(String name, Uint8List bytes) {
  try {
    final text = utf8.decode(bytes);
    return text.startsWith('﻿') ? text.substring(1) : text;
  } on FormatException {
    throw PackageProblemError(ScriptNotUtf8(name));
  }
}
