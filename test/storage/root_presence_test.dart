import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/domain/local_audio_catalog.dart';
import 'package:kanaru/src/storage/data/root_presence.dart';

class _Catalog implements LocalAudioCatalog {
  _Catalog({this.android = false, this.reachable = true});

  final bool android;
  final bool reachable;

  @override
  Future<AudioListing> listAudio({
    required String root,
    required Set<String> excludedKeys,
    int skipShorterThanMs = 0,
  }) async =>
      reachable ? const AudioListing() : const AudioListing.unreachable();

  @override
  Future<List<AudioFolderSummary>> audioFolders() async => const [];
  @override
  Future<String?> suggestedMusicFolder() async => null;
  @override
  Future<String> canonicalize(String path) async => path;
  @override
  FolderChoice get folderChoice =>
      android ? FolderChoice.mediaStoreSheet : FolderChoice.systemDialog;
  @override
  Future<String?> pickFolder({String? initialDirectory}) async => null;
}

void main() {
  late Directory tmp;
  late String root;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('kanaru_presence_test');
    root = '${tmp.path}/usb';
    Directory(root).createSync();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  void addFile() => File('$root/a.mp3').writeAsStringSync('x');

  test('a folder with content and unchanged mounts is present', () async {
    addFile();
    final check = rootPresenceCheck(
      catalog: _Catalog(),
      root: root,
      readMounts: () => {root, '/'},
    );
    final p = await check();
    expect(p.present, isTrue);
    expect(p.lostPrefixes, isEmpty);
  });

  test(
    'an empty folder left by an unmounted mount point is not present',
    () async {
      addFile();
      var mounted = true;
      final check = rootPresenceCheck(
        catalog: _Catalog(),
        root: root,
        readMounts: () => mounted ? {root} : {'/'},
      );
      // The drive is unplugged: the mount point stays as an empty folder.
      File('$root/a.mp3').deleteSync();
      mounted = false;
      expect((await check()).present, isFalse);
    },
  );

  test('an existing empty folder is not present even without mounts', () async {
    final check = rootPresenceCheck(
      catalog: _Catalog(),
      root: root,
      readMounts: () => {'/'},
    );
    expect((await check()).present, isFalse);
  });

  test('content with the mount gone is not present', () async {
    addFile();
    var mounted = true;
    final check = rootPresenceCheck(
      catalog: _Catalog(),
      root: root,
      readMounts: () => mounted ? {tmp.path} : {'/'},
    );
    mounted = false;
    expect((await check()).present, isFalse);
  });

  test('a missing folder is not present', () async {
    final check = rootPresenceCheck(
      catalog: _Catalog(),
      root: '${tmp.path}/nope',
      readMounts: () => {'/'},
    );
    expect((await check()).present, isFalse);
  });

  test('an unreadable mounts file changes nothing', () async {
    addFile();
    var calls = 0;
    final check = rootPresenceCheck(
      catalog: _Catalog(),
      root: root,
      readMounts: () => calls++ == 0 ? {root} : <String>{},
    );
    expect((await check()).present, isTrue);
  });

  test('a nested mount that vanished is reported by prefix', () async {
    addFile();
    Directory('$root/nas').createSync();
    var mounted = true;
    final check = rootPresenceCheck(
      catalog: _Catalog(),
      root: '$root/',
      readMounts: () => mounted ? {'/', '$root/nas'} : {'/'},
    );
    mounted = false;
    final p = await check();
    expect(p.present, isTrue);
    expect(p.lostPrefixes, ['nas/']);
    expect(p.isLost('nas/deep/a.mp3'), isTrue);
    expect(p.isLost('nasty/a.mp3'), isFalse);
  });

  test('on Android the catalog decides', () async {
    expect(
      (await rootPresenceCheck(
        catalog: _Catalog(android: true),
        root: '/storage/x',
      )()).present,
      isTrue,
    );
    expect(
      (await rootPresenceCheck(
        catalog: _Catalog(android: true, reachable: false),
        root: '/storage/x',
      )()).present,
      isFalse,
    );
  });
}
