final _installId = RegExp(r'^plugin-[0-9a-f]{32}$');

/// Whether [value] has the shape of an install id (`plugin-` + 32 hex). Every
/// id is checked with this before it becomes part of a path.
bool isInstallIdShape(String value) => _installId.hasMatch(value);
