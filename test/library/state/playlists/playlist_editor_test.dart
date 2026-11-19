import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/covers/cover_choice.dart';
import 'package:kanaru/src/library/domain/covers/cover_preview.dart';
import 'package:kanaru/src/library/domain/custom_cover_controller.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_models.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_store.dart';
import 'package:kanaru/src/library/state/playlists/playlist_editor.dart';

class _Store implements PlaylistStore {
  PlaylistUpdate result = PlaylistUpdate.saved;
  Object? error;
  final calls = <(String, String?, String?)>[];

  @override
  Future<PlaylistUpdate> updatePlaylist(
    String uid, {
    String? name,
    String? description,
  }) async {
    calls.add((uid, name, description));
    if (error != null) throw error!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Change implements CoverChange {
  _Change(this.log);
  final List<String> log;

  @override
  String? get previousKey => null;
  @override
  String? get currentKey => null;
  @override
  Future<bool> undo() async => false;
  @override
  Future<void> release() async => log.add('release');
}

class _Covers implements CustomCoverController {
  @override
  Future<CoverChange> changeCover(
    CustomCoverKind kind,
    String itemKey,
    CoverChoice choice,
  ) async {
    log.add('change ${kind.name} $itemKey ${(choice as FileCover).image.path}');
    if (error != null) throw error!;
    return _Change(log);
  }

  @override
  Future<CoverPreview> previewCover(File source) => throw UnimplementedError();

  final log = <String>[];
  Object? error;

  @override
  Future<void> removeCover(CustomCoverKind kind, String itemKey) async {
    log.add('remove ${kind.name} $itemKey');
    if (error != null) throw error!;
  }

  @override
  Future<int> collectUnreferencedFiles() async => 0;
}

void main() {
  late _Store store;
  late _Covers covers;
  late PlaylistEditor editor;

  setUp(() {
    store = _Store();
    covers = _Covers();
    editor = PlaylistEditor(store, covers);
  });

  test('keep writes the text only', () async {
    final r = await editor.save('p', name: 'N', description: 'D');
    expect(r, const PlaylistEditResult(text: PlaylistUpdate.saved));
    expect(store.calls, [('p', 'N', 'D')]);
    expect(covers.log, isEmpty);
  });

  test('automatic removes the custom cover after the text', () async {
    final r = await editor.save(
      'p',
      name: 'N',
      description: '',
      cover: const PlaylistCoverEdit.automatic(),
    );
    expect(r.coverFailed, isFalse);
    expect(covers.log, ['remove playlist p']);
  });

  test('choice changes the cover and releases it; unchanged text still applies the cover', () async {
    store.result = PlaylistUpdate.unchanged;
    final r = await editor.save(
      'p',
      name: 'N',
      description: '',
      cover: PlaylistCoverEdit.choice(CoverChoice.file(File('/x/a.png'))),
    );
    expect(r.text, PlaylistUpdate.unchanged);
    expect(covers.log, ['change playlist p /x/a.png', 'release']);
  });

  test('a playlist that is gone skips the cover', () async {
    store.result = PlaylistUpdate.gone;
    final r = await editor.save(
      'p',
      name: 'N',
      description: '',
      cover: const PlaylistCoverEdit.automatic(),
    );
    expect(r.text, PlaylistUpdate.gone);
    expect(covers.log, isEmpty);
  });

  test('a cover failure keeps the saved text and is reported', () async {
    covers.error = const FileSystemException('disk full');
    final r = await editor.save(
      'p',
      name: 'N',
      description: '',
      cover: PlaylistCoverEdit.choice(CoverChoice.file(File('/x/a.png'))),
    );
    expect(
      r,
      const PlaylistEditResult(text: PlaylistUpdate.saved, coverFailed: true),
    );
  });

  test('an invalid text propagates and touches no cover', () async {
    store.error = ArgumentError('name');
    await expectLater(
      editor.save(
        'p',
        name: '',
        description: '',
        cover: const PlaylistCoverEdit.automatic(),
      ),
      throwsArgumentError,
    );
    expect(covers.log, isEmpty);
  });
}
