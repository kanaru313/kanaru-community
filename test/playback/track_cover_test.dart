import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/media/domain/cover_files.dart';
import 'package:kanaru/src/platform/domain/app_paths.dart';
import 'package:kanaru/src/platform/state/platform_providers.dart';
import 'package:kanaru/src/playback/state/cover_providers.dart';
import 'package:kanaru/src/playback/ui/track_cover.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

class _Paths implements AppPaths {
  _Paths(this.cacheDir);
  @override
  final Directory cacheDir;
  @override
  Directory get dataDir => cacheDir;
  @override
  Directory get configDir => cacheDir;
}

void main() {
  const key = 'ab/0123456789abcdef0123456789abcdef';
  late Directory cache;
  late CoverMissSink sink;
  late List<String> misses;

  setUp(() {
    cache = Directory.systemTemp.createTempSync('track_cover_test');
    sink = CoverMissSink();
    misses = [];
    sink.misses.listen(misses.add);
  });
  tearDown(() async {
    await sink.close();
    cache.deleteSync(recursive: true);
  });

  Widget app(String? coverKey) => ProviderScope(
    overrides: [
      appPathsProvider.overrideWithValue(_Paths(cache)),
      coverMissesProvider.overrideWithValue(sink),
    ],
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: TrackCover(
        coverKey: coverKey,
        seed: 'album',
        size: CoverSize.thumb,
        dimension: 48,
      ),
    ),
  );

  testWidgets('a valid key whose file is gone is reported once', (
    tester,
  ) async {
    await tester.runAsync(() => tester.pumpWidget(app(key)));
    await _pumpUntil(tester, () => misses.isNotEmpty);
    expect(misses, [key]);
    expect(find.byType(KCover), findsOneWidget);
    expect(tester.widget<KCover>(find.byType(KCover)).image, isNull);
  });

  testWidgets('no key or a malformed key is a placeholder, not a miss', (
    tester,
  ) async {
    for (final k in <String?>[null, '../../etc/passwd']) {
      await tester.runAsync(() async {
        await tester.pumpWidget(app(k));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(tester.widget<KCover>(find.byType(KCover)).image, isNull);
    }
    expect(misses, isEmpty);
  });

  testWidgets('an existing file is shown and not reported', (tester) async {
    final file = File(
      '${cache.path}/${coverRelativePath(key, CoverSize.thumb)}',
    )..createSync(recursive: true);
    file.writeAsBytesSync(const [0]);
    await tester.runAsync(() => tester.pumpWidget(app(key)));
    await _pumpUntil(
      tester,
      () => tester.widget<KCover>(find.byType(KCover)).image != null,
    );
    expect(tester.widget<KCover>(find.byType(KCover)).image, isNotNull);
    expect(misses, isEmpty);
  });
}

/// Lets real async work (file checks) run and pumps frames until [done] holds;
/// fails after [timeout] instead of guessing a fixed delay.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  await tester.pump();
  while (!done()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condition not met within $timeout');
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
}
