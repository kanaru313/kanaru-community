import 'dart:convert';

/// Largest catalog text a repository row keeps (UTF-8 bytes).
const maxCatalogJsonBytes = 1024 * 1024;

/// Largest config text of one plugin, and of its custom choices (UTF-8
/// bytes each).
const maxConfigJsonBytes = 64 * 1024;

final _installId = RegExp(r'^plugin-[0-9a-f]{32}$');
final _packageDir = RegExp(r'^v\d{1,9}-\d{1,15}$');
final _sha256 = RegExp(r'^[0-9a-f]{64}$');

/// Whether [value] has the shape of an install id (`plugin-` + 32 hex). Every
/// id is checked with this before it becomes part of a path.
bool isInstallIdShape(String value) => _installId.hasMatch(value);

/// Whether [value] has the shape of a package folder name
/// (`v<version>-<epochMs>`).
bool isPackageDirShape(String value) => _packageDir.hasMatch(value);

/// Whether [value] is a lower-case hex SHA-256.
bool isSha256Shape(String value) => _sha256.hasMatch(value);

/// UTF-8 size of [text] in bytes.
int utf8Length(String text) => utf8.encode(text).length;
