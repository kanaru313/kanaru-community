import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/data/scan/native_cover_import.dart';
import 'package:kanaru/src/library/domain/covers/cover_choice.dart';
import 'package:kanaru/src/rust/api/covers.dart';
import 'package:kanaru/src/rust/api/error.dart';

CoverPreviewDto _failed(NativeErrorKind kind, {required bool transient}) =>
    CoverPreviewDto(
      width: 0,
      height: 0,
      error: NativeError(kind: kind, detail: 'x', transient: transient),
    );

void main() {
  group('coverPreviewOf', () {
    test('a success carries the file and the original size', () {
      final p = coverPreviewOf(
        const CoverPreviewDto(
          previewPath: '/tmp/p/.kanaru-tmp-preview-1.jpg',
          width: 6000,
          height: 2000,
        ),
        '/src.jpg',
      );
      expect(p.file.path, '/tmp/p/.kanaru-tmp-preview-1.jpg');
      expect((p.width, p.height), (6000, 2000));
    });

    test('transient and permission errors are a FileSystemException', () {
      for (final (kind, transient) in [
        (NativeErrorKind.io, true),
        (NativeErrorKind.permissionDenied, false),
      ]) {
        expect(
          () => coverPreviewOf(_failed(kind, transient: transient), '/s'),
          throwsA(isA<FileSystemException>()),
          reason: kind.name,
        );
      }
    });

    test('every permanent kind is a FormatException naming the kind', () {
      for (final kind in [
        NativeErrorKind.corrupt,
        NativeErrorKind.unsupported,
        NativeErrorKind.tooLarge,
        NativeErrorKind.notFound,
        NativeErrorKind.panic,
      ]) {
        expect(
          () => coverPreviewOf(_failed(kind, transient: false), '/s'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains(kind.name),
            ),
          ),
          reason: kind.name,
        );
      }
    });

    test('no error and no path is a FormatException', () {
      expect(
        () => coverPreviewOf(const CoverPreviewDto(width: 0, height: 0), '/s'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('coverCropDtoOf', () {
    test('null stays null and fields are copied', () {
      expect(coverCropDtoOf(null), isNull);
      final dto = coverCropDtoOf(const CoverCrop(left: 1, top: 2, side: 3));
      expect((dto?.left, dto?.top, dto?.side), (1, 2, 3));
    });

    test('values outside u32 are an ArgumentError', () {
      for (final crop in const [
        CoverCrop(left: -1, top: 0, side: 1),
        CoverCrop(left: 0, top: -1, side: 1),
        CoverCrop(left: 0, top: 0, side: -5),
        CoverCrop(left: 0x100000000, top: 0, side: 1),
        CoverCrop(left: 0, top: 0, side: 0x100000000),
      ]) {
        expect(
          () => coverCropDtoOf(crop),
          throwsArgumentError,
          reason: '$crop',
        );
      }
      expect(
        coverCropDtoOf(const CoverCrop(left: 0, top: 0, side: 0xFFFFFFFF)),
        isNotNull,
      );
    });
  });
}
