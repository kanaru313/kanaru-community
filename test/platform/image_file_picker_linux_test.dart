import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/data/image_file_picker_linux.dart';

void main() {
  test('dialog is filtered to images, both cases of each extension', () async {
    List<XTypeGroup>? groups;
    final picker = LinuxImageFilePicker(
      label: 'Ảnh',
      openFile: ({acceptedTypeGroups = const []}) async {
        groups = acceptedTypeGroups;
        return null;
      },
    );
    await picker.pick();

    final group = groups!.single;
    expect(group.label, 'Ảnh');
    expect(
      group.extensions,
      containsAll(['jpg', 'jpeg', 'png', 'webp', 'JPG', 'JPEG', 'PNG', 'WEBP']),
    );
    expect(group.mimeTypes, ['image/jpeg', 'image/png', 'image/webp']);
  });

  test('cancel returns null', () async {
    final picker = LinuxImageFilePicker(
      openFile: ({acceptedTypeGroups = const []}) async => null,
    );
    expect(await picker.pick(), isNull);
  });

  test('picked file is the user\'s own, not temporary', () async {
    final picker = LinuxImageFilePicker(
      openFile: ({acceptedTypeGroups = const []}) async =>
          XFile('/home/u/Pictures/cover.PNG'),
    );
    final picked = (await picker.pick())!;
    expect(picked.file.path, '/home/u/Pictures/cover.PNG');
    expect(picked.name, 'cover.PNG');
    expect(picked.temporary, isFalse);
    expect(picked.nameIsGenerated, isFalse);
  });
}
