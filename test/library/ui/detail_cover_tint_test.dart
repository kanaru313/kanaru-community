import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/detail/detail_tint.dart';
import 'package:kanaru/src/media/domain/cover_colors.dart';
import 'package:kanaru/src/playback/state/cover_providers.dart';

Future<DetailTint> _tintOf(
  WidgetTester tester,
  String? key,
  Override colors,
) async {
  late DetailTint tint;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [colors],
      child: Consumer(
        builder: (context, ref, _) {
          tint = watchCoverTint(ref, key);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pump();
  return tint;
}

void main() {
  testWidgets('no cover key: no tint, nothing read', (tester) async {
    final tint = await _tintOf(
      tester,
      null,
      coverColorsProvider.overrideWith((ref, key) => throw StateError('read')),
    );
    expect(tint, DetailTint.none);
  });

  testWidgets('colours still being read: loading, no palette', (tester) async {
    final never = StreamController<CoverColors?>();
    addTearDown(never.close);
    final tint = await _tintOf(
      tester,
      'k',
      coverColorsProvider.overrideWith((ref, key) => never.stream),
    );
    expect(tint.loading, isTrue);
    expect(tint.palette, isNull);
  });

  testWidgets('error reading the colours: no tint', (tester) async {
    final tint = await _tintOf(
      tester,
      'k',
      coverColorsProvider.overrideWith(
        (ref, key) => Stream<CoverColors?>.error('boom'),
      ),
    );
    expect(tint, DetailTint.none);
  });

  testWidgets('no colours stored: no tint', (tester) async {
    final tint = await _tintOf(
      tester,
      'k',
      coverColorsProvider.overrideWith((ref, key) => Stream.value(null)),
    );
    expect(tint, DetailTint.none);
  });

  testWidgets('an empty palette falls back to the seed', (tester) async {
    final tint = await _tintOf(
      tester,
      'k',
      coverColorsProvider.overrideWith(
        (ref, key) =>
            Stream.value(const CoverColors(seed: 0xFF112233, palette: [])),
      ),
    );
    expect(tint.palette, [const Color(0xFF112233)]);
  });
}
