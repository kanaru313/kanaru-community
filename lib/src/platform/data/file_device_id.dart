import 'dart:io';

import '../../foundation/ids/ulid.dart';
import '../domain/device_id.dart';
import 'atomic_file.dart';

/// Device id kept in `<dataDir>/device_id`, outside the database.
class FileDeviceId implements DeviceIdSource {
  FileDeviceId(this._file);

  final File _file;

  @override
  Future<String> load() async {
    try {
      if (await _file.exists()) {
        final id = (await _file.readAsString()).trim();
        if (isUlid(id)) return id;
      }
    } on FileSystemException {
      // Unreadable: replace below.
    }
    final id = newUlid();
    await _file.parent.create(recursive: true);
    await writeFileAtomic(_file, id);
    return id;
  }
}
