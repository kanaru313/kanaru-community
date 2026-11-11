import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/library/domain/folder_exclusions.dart';
import 'package:kanaru/src/library/domain/music_folder.dart';
import 'package:kanaru/src/platform/domain/file_manager.dart';

/// Records the exclusions asked of it; an undo is an include.
class FakeFolderExclusions implements FolderExclusions {
  final List<String> calls = [];
  Object? failWith;

  @override
  Future<void> exclude(
    MusicFolder folder,
    String folderKey, {
    required String displayPath,
  }) async {
    if (failWith != null) throw failWith!;
    calls.add('exclude ${folder.sourceId} $folderKey $displayPath');
  }

  @override
  Future<void> include(MusicFolder folder, String folderKey) async {
    calls.add('include ${folder.sourceId} $folderKey');
  }

  @override
  Stream<List<({String folderKey, String displayPath})>> watch(
    MusicFolder folder,
  ) => const Stream.empty();
}

/// A file manager that records what it was asked to show.
class FakeFileManager implements FileManager {
  FakeFileManager({this.canReveal = true, this.result});

  @override
  final bool canReveal;

  /// Answer to [reveal]; null = success.
  final FileManagerError? result;
  final List<String> revealed = [];

  @override
  Future<Result<void, FileManagerError>> reveal(String absolutePath) async {
    revealed.add(absolutePath);
    final error = result;
    return error == null ? const Ok(null) : Err(error);
  }
}
