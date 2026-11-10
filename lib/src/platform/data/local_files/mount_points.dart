import 'dart:io';

import 'package:logging/logging.dart';

/// Mount points listed in the text of `/proc/self/mounts` (second column,
/// with the kernel's octal escapes such as `\040` decoded).
Set<String> parseMountPoints(String mountsContent) {
  final points = <String>{};
  for (final line in mountsContent.split('\n')) {
    final columns = line.split(' ');
    if (columns.length < 2 || columns[1].isEmpty) continue;
    points.add(_unescape(columns[1]));
  }
  return points;
}

final _octal = RegExp(r'\\([0-7]{3})');

String _unescape(String value) => value.replaceAllMapped(
  _octal,
  (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 8)),
);

/// Mount points of this machine; empty when `/proc/self/mounts` cannot be read.
Set<String> readMountPoints() {
  try {
    return parseMountPoints(File('/proc/self/mounts').readAsStringSync());
  } on FileSystemException catch (error) {
    Logger('platform.files').fine('No readable /proc/self/mounts: $error');
    return const {};
  }
}
