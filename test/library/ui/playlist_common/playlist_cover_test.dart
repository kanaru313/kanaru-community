import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/library/state/browse/custom_cover_index_providers.dart';
import 'package:kanaru/src/library/state/custom_cover_providers.dart';
import 'package:kanaru/src/library/ui/playlist_common/playlist_cover.dart';
import 'package:kanaru/src/media/domain/cover_files.dart';
import 'package:kanaru/src/playback/ui/track_cover.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

class _Paths implements AppPaths {
  @override
  final dataDir = Directory('/nonexistent/data');
  @override
  final cacheDir = Directory('/nonexistent/cache');
  @override
  final configDir = Directory('/nonexistent/config');
}

String _key(int i) => '${i.toRadixString(16).padLeft(2, '0')}/${'a' * 32}';

Future<void> _pump(
  WidgetTester tester,
  PlaylistCover cover, {
  Set<String> custom = const {},
  double dpr = 1,
  List overrides = const [],
}) async {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = const Size(800, 800);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPathsProvider.overrideWithValue(_Paths()),
        customCoverIndexProvider.overrideWith(
          (ref, kind) => Stream.value(custom),
        ),
        ...overrides,
      ],
      child: MaterialApp(home: Center(child: cover)),
    ),
  );
  await tester.pump();
}

List<TrackCover> _tracks(WidgetTester tester) =>
    tester.widgetList<TrackCover>(find.byType(TrackCover)).toList();

void main() {
  test('big tiles read the full files, small ones the thumbs', () {
    expect(playlistCoverFileSize(320, 1), CoverSize.full);
    expect(playlistCoverFileSize(132, 2), CoverSize.full);
    expect(playlistCoverFileSize(132, 1), CoverSize.thumb);
    expect(playlistCoverFileSize(128, 2), CoverSize.thumb);
    expect(playlistCoverFileSize(48, 3), CoverSize.thumb);
  });

  testWidgets('Favorites is a heart tile', (tester) async {
    await _pump(
      tester,
      const PlaylistCover(
        uid: PlaylistUids.favorites,
        autoCoverKeys: [],
        dimension: 56,
      ),
    );
    expect(find.byType(TrackCover), findsNothing);
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, KIcons.heartFilled);
    expect(icon.size, 56 * 0.42);
  });

  testWidgets('no keys: placeholder cover', (tester) async {
    await _pump(
      tester,
      const PlaylistCover(uid: 'p1', autoCoverKeys: [], dimension: 56),
    );
    expect(find.byType(TrackCover), findsNothing);
    expect(find.byType(KCoverMosaic), findsNothing);
    final scheme = Theme.of(tester.element(find.byType(PlaylistCover)))
        .colorScheme;
    final tile = tester.widget<DecoratedBox>(find.byType(DecoratedBox).first);
    expect(
      (tile.decoration as BoxDecoration).color,
      scheme.surfaceContainerHighest,
    );
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.color, scheme.onSurfaceVariant);
    expect(icon.size, 56 * 0.42);
  });

  testWidgets('one key: that cover alone', (tester) async {
    await _pump(
      tester,
      PlaylistCover(uid: 'p1', autoCoverKeys: [_key(1)], dimension: 56),
    );
    expect(find.byType(KCoverMosaic), findsNothing);
    expect(_tracks(tester).map((t) => t.coverKey), [_key(1)]);
  });

  for (final n in [2, 3, 4]) {
    testWidgets('$n keys: a mosaic of those covers', (tester) async {
      await _pump(
        tester,
        PlaylistCover(
          uid: 'p1',
          autoCoverKeys: [for (var i = 0; i < n; i++) _key(i)],
          dimension: 56,
        ),
      );
      expect(find.byType(KCoverMosaic), findsOneWidget);
      expect(_tracks(tester).map((t) => t.coverKey), [
        for (var i = 0; i < n; i++) _key(i),
      ]);
    });
  }

  testWidgets('mosaic tile side follows the file-size rule', (tester) async {
    // 4 tiles of a 320 dp header: 160 dp tiles at 2x = 320 px > thumb.
    await _pump(
      tester,
      PlaylistCover(
        uid: 'p1',
        autoCoverKeys: [for (var i = 0; i < 4; i++) _key(i)],
        dimension: 320,
      ),
      dpr: 2,
    );
    expect(_tracks(tester).every((t) => t.size == CoverSize.full), isTrue);
    await _pump(
      tester,
      PlaylistCover(
        uid: 'p1',
        autoCoverKeys: [for (var i = 0; i < 4; i++) _key(i)],
        dimension: 56,
      ),
    );
    expect(_tracks(tester).every((t) => t.size == CoverSize.thumb), isTrue);
  });

  const item = (kind: CustomCoverKind.playlist, itemKey: 'p1');
  final full = File('/x/covers/full/cd/${'b' * 32}.jpg');
  final thumb = File('/x/covers/thumb/cd/${'b' * 32}.jpg');
  final customOverrides = [
    customCoverFileProvider(item).overrideWith((ref) => Stream.value(full)),
  ];

  testWidgets('a custom cover wins over the automatic one', (tester) async {
    await _pump(
      tester,
      PlaylistCover(uid: 'p1', autoCoverKeys: [_key(1)], dimension: 56),
      custom: {'p1'},
      overrides: customOverrides,
    );
    await tester.pump();
    expect(find.byType(TrackCover), findsNothing);
    expect(tester.widget<KCover>(find.byType(KCover)).image, isA<FileImage>());
  });

  testWidgets('a custom cover reads the thumb in lists, full in headers', (
    tester,
  ) async {
    String? shown() =>
        ((tester.widget<KCover>(find.byType(KCover)).image) as FileImage?)
            ?.file
            .path;
    await _pump(
      tester,
      const PlaylistCover(uid: 'p1', autoCoverKeys: [], dimension: 56),
      custom: {'p1'},
      overrides: customOverrides,
    );
    await tester.pump();
    expect(shown(), thumb.path);
    await _pump(
      tester,
      const PlaylistCover(uid: 'p1', autoCoverKeys: [], dimension: 320),
      custom: {'p1'},
      overrides: customOverrides,
    );
    await tester.pump();
    expect(shown(), full.path);
  });

  testWidgets('every cover kind has the same default corners', (tester) async {
    Future<BorderRadius> radiusOf(List<String> keys, String uid) async {
      await _pump(
        tester,
        PlaylistCover(uid: uid, autoCoverKeys: keys, dimension: 56),
      );
      final clip = tester.widgetList<ClipRRect>(find.byType(ClipRRect));
      return clip.isEmpty
          ? ((tester.widget<DecoratedBox>(find.byType(DecoratedBox).first))
                            .decoration
                        as BoxDecoration)
                    .borderRadius!
                as BorderRadius
          : clip.first.borderRadius as BorderRadius;
    }

    final empty = await radiusOf([], 'p1');
    expect(empty, KRadius.sm);
    expect(await radiusOf([_key(1)], 'p1'), KRadius.sm);
    expect(await radiusOf([_key(1), _key(2)], 'p1'), KRadius.sm);
    expect(await radiusOf([], PlaylistUids.favorites), KRadius.sm);
  });

  testWidgets('a changed cover never shows the old thumb', (tester) async {
    final first = File('/x/covers/full/ef/${'c' * 32}.jpg');
    final second = File('/x/covers/full/12/${'d' * 32}.jpg');
    final files = StreamController<File?>();
    addTearDown(files.close);
    String? shown() =>
        ((tester.widget<KCover>(find.byType(KCover)).image) as FileImage?)
            ?.file
            .path;
    await _pump(
      tester,
      const PlaylistCover(uid: 'p1', autoCoverKeys: [], dimension: 56),
      custom: {'p1'},
      overrides: [
        customCoverFileProvider(item).overrideWith((ref) => files.stream),
      ],
    );
    files.add(first);
    await tester.pump();
    await tester.pump();
    expect(shown(), '/x/covers/thumb/ef/${'c' * 32}.jpg');
    files.add(second);
    await tester.pump();
    await tester.pump();
    expect(shown(), '/x/covers/thumb/12/${'d' * 32}.jpg');
  });

  testWidgets('a missing thumb falls back to the full file, then to the '
      'automatic cover', (tester) async {
    await _pump(
      tester,
      PlaylistCover(uid: 'p1', autoCoverKeys: [_key(1)], dimension: 56),
      custom: {'p1'},
      overrides: customOverrides,
    );
    await tester.pump();
    // Outermost cover draws the thumb; its error fallback is the full file;
    // that one's error fallback is the automatic cover.
    final thumbCover = tester.widget<KCover>(find.byType(KCover).first);
    expect((thumbCover.image! as FileImage).file.path, thumb.path);
    final fullCover = thumbCover.errorFallback! as KCover;
    expect((fullCover.image! as FileImage).file.path, full.path);
    expect((fullCover.errorFallback! as TrackCover).coverKey, _key(1));
  });

  testWidgets('automaticOnly ignores a custom cover', (tester) async {
    await _pump(
      tester,
      PlaylistCover(
        uid: 'p1',
        autoCoverKeys: [_key(1)],
        dimension: 56,
        automaticOnly: true,
      ),
      custom: {'p1'},
      overrides: customOverrides,
    );
    expect(find.byType(TrackCover), findsOneWidget);
  });
}
