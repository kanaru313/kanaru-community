import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/scan/folder_list_state.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';

AudioFolderSummary _f(String path, int n) =>
    AudioFolderSummary(path: path, audioCount: n);

void main() {
  Future<List<AudioFolderSummary>> neverCalled(List<AudioFolderSummary> _) =>
      throw StateError('candidates must not be computed');

  test('a failed read is a load failure for every reason', () async {
    for (final reason in AudioFoldersFailure.values) {
      expect(
        await folderListStateOf(AudioFoldersFailed(reason), neverCalled),
        isA<FolderListLoadFailed>(),
      );
    }
  });

  test('an index with no audio is told apart from all-chosen', () async {
    expect(
      await folderListStateOf(const AudioFoldersListed([]), neverCalled),
      isA<FolderListNoIndexedMusic>(),
    );
  });

  test('a listed index with nothing left to add is ready and empty', () async {
    final state = await folderListStateOf(
      AudioFoldersListed([_f('/m', 1)]),
      (_) async => const [],
    );
    expect(state, isA<FolderListReady>());
    expect((state as FolderListReady).candidates, isEmpty);
  });

  test('the candidate function gets the listed folders', () async {
    final listed = [_f('/a', 1), _f('/b', 2)];
    List<AudioFolderSummary>? seen;
    final state = await folderListStateOf(AudioFoldersListed(listed), (
      l,
    ) async {
      seen = l;
      return [l.last];
    });
    expect(seen, listed);
    expect((state as FolderListReady).candidates.single.path, '/b');
  });
}
