import 'dart:async';
import 'dart:io';

import 'package:kanaru/src/library/domain/covers/cover_choice.dart';
import 'package:kanaru/src/library/domain/covers/cover_preview.dart';
import 'package:kanaru/src/library/domain/custom_cover_controller.dart';
import 'package:kanaru/src/media/domain/library_keys.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru/src/media/domain/track_info.dart';
import 'package:kanaru/src/platform/domain/image_file_picker.dart';

/// A track of [album] (null: no album) with [cover] (null: none).
TrackInfo track(int id, {String? album, String? cover, int? year}) => TrackInfo(
  id: TrackId(id),
  title: 't$id',
  status: TrackAvailability.present,
  relPath: '$id.flac',
  album: album,
  albumKey: album == null ? null : AlbumKey('artist', album.toLowerCase()),
  coverKey: cover,
  year: year,
);

String coverKeyOf(int n) => 'ab/${n.toRadixString(16).padLeft(32, '0')}';

/// The handle `changeCover` returns; counts what was done to it.
class FakeChange implements CoverChange {
  FakeChange({this.undoResult = true, this.undoError});

  bool undoResult;
  Object? undoError;
  int undos = 0;
  int releases = 0;

  @override
  String? get previousKey => null;
  @override
  String? get currentKey => null;

  @override
  Future<bool> undo() async {
    undos++;
    if (undoError != null) throw undoError!;
    return undoResult;
  }

  @override
  Future<void> release() async => releases++;
}

/// Stands in for the store: no native call. Previews are real files in [dir]
/// with the upright size [sizeOf] says; `changeCover` waits for [gate].
class FakeCoverController implements CustomCoverController {
  FakeCoverController(this.dir);

  final Directory dir;
  final changes = <({CustomCoverKind kind, String key, CoverChoice choice})>[];
  final previews = <File>[];
  final change = FakeChange();

  /// Upright size per source path; the default is 3024 x 4032.
  final sizes = <String, ({int w, int h})>{};
  Object? previewError;
  Object? changeError;
  Completer<void>? gate;
  Completer<void>? previewGate;

  @override
  Future<CoverPreview> previewCover(File source) async {
    await previewGate?.future;
    if (previewError != null) throw previewError!;
    final file = File('${dir.path}/preview-${previews.length}.jpg')
      ..writeAsBytesSync([1]);
    previews.add(file);
    final size = sizes[source.path] ?? (w: 3024, h: 4032);
    return CoverPreview(file: file, width: size.w, height: size.h);
  }

  @override
  Future<CoverChange> changeCover(
    CustomCoverKind kind,
    String itemKey,
    CoverChoice choice,
  ) async {
    await gate?.future;
    if (changeError != null) throw changeError!;
    changes.add((kind: kind, key: itemKey, choice: choice));
    return change;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class FakePicker implements ImageFilePicker {
  PickedImage? next;
  Object? error;
  Completer<void>? gate;
  int calls = 0;
  String? lastLabel;

  @override
  Future<PickedImage?> pick({String? label}) async {
    calls++;
    lastLabel = label;
    await gate?.future;
    if (error != null) throw error!;
    return next;
  }
}

/// A picked image backed by a real file in [dir].
PickedImage pickedFile(Directory dir, String name, {bool temporary = true}) {
  final file = File('${dir.path}/$name')..writeAsBytesSync([1, 2, 3]);
  return PickedImage(file: file, name: name, temporary: temporary);
}
