import 'dart:typed_data';

import 'plugin_manifest.dart';

/// A plugin package that passed every check, held in memory.
///
/// What gets stored later is [manifestBytes] and the script files exactly as
/// read; [manifest] is a view of them for the app.
class PluginPackage {
  const PluginPackage({
    required this.manifestBytes,
    required this.manifestText,
    required this.manifest,
    required this.scripts,
    required this.sha256,
    required this.size,
    this.assets = const {},
    this.icon,
  });

  /// The `plugin.json` entry, byte for byte.
  final Uint8List manifestBytes;

  /// [manifestBytes] decoded as UTF-8 (a leading BOM is not part of it). This
  /// is the text kept in the database; unknown fields survive in it.
  final String manifestText;

  final PluginManifest manifest;

  /// Every `src/<name>.js` of the zip by file name (`search.js`): UTF-8
  /// decoded, BOM stripped. Holds at least every file the manifest's script
  /// map names; other files are kept because a script may `load()` them.
  final Map<String, String> scripts;

  /// The `assets/` files of a seekbar package by file name (`t.png`): only
  /// those the `seekbar` block names, header-checked, unmodifiable. Empty for
  /// every other kind.
  final Map<String, Uint8List> assets;

  /// A valid `icon.png` (PNG, at most 256 x 256, 64 KiB); null when there was
  /// none or it was dropped.
  final Uint8List? icon;

  /// Lower-case hex SHA-256 of the zip file.
  final String sha256;

  /// Size of the zip file in bytes.
  final int size;
}
