import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:kanaru/src/platform/data/image_file_picker_android.dart';

class _FakePlatform extends ImagePickerPlatform {
  XFile? result;
  ImageSource? source;
  ImagePickerOptions? options;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    this.source = source;
    this.options = options;
    return result;
  }
}

void main() {
  test(
    'asks the gallery with original bytes and no metadata permission',
    () async {
      final fake = _FakePlatform()..result = XFile('/cache/u/IMG_1.jpg');
      final picked = (await AndroidImageFilePicker(platform: fake).pick())!;

      expect(fake.source, ImageSource.gallery);
      expect(fake.options!.maxWidth, isNull);
      expect(fake.options!.maxHeight, isNull);
      expect(fake.options!.imageQuality, isNull);
      expect(fake.options!.requestFullMetadata, isFalse);
      expect(picked.temporary, isTrue);
      expect(picked.name, 'IMG_1.jpg');
      expect(picked.nameIsGenerated, isFalse);
    },
  );

  test('cancel returns null', () async {
    final fake = _FakePlatform();
    expect(await AndroidImageFilePicker(platform: fake).pick(), isNull);
  });

  test('turns the Photo Picker on for the Android implementation', () {
    final android = ImagePickerAndroid();
    expect(android.useAndroidPhotoPicker, isFalse);
    AndroidImageFilePicker(platform: android);
    expect(android.useAndroidPhotoPicker, isTrue);
  });

  test('generated names are detected', () {
    for (final name in [
      'image_picker.jpg',
      'image_picker_3A1F.png',
      'scaled_IMG_1.jpg',
      '3f2504e0-4f89-11d3-9a0c-0305e82c3301.jpg',
      '3F2504E0-4F89-11D3-9A0C-0305E82C3301',
    ]) {
      expect(AndroidImageFilePicker.looksGenerated(name), isTrue, reason: name);
    }
    for (final name in ['IMG_20240101.jpg', 'cover.png', 'image.jpg']) {
      expect(
        AndroidImageFilePicker.looksGenerated(name),
        isFalse,
        reason: name,
      );
    }
  });
}
