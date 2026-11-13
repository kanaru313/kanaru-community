import 'package:flutter/painting.dart' show Color;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../playback/state/cover_providers.dart';
import '../../state/custom_cover_providers.dart';
import '../../state/shown_cover_provider.dart';

/// What a detail page feeds its tint: the colours of the image the page shows,
/// and whether they are still being resolved.
class DetailTint {
  const DetailTint({this.palette, this.loading = false});

  /// No cover or no colours: the page is not tinted.
  static const none = DetailTint();

  final List<Color>? palette;

  /// The image or its colours are not known yet: nothing is drawn (first
  /// time) or the previous tint stays (the cover changed on an open page).
  final bool loading;

  @override
  bool operator ==(Object other) =>
      other is DetailTint &&
      other.loading == loading &&
      listEquals(other.palette, palette);

  @override
  int get hashCode => Object.hash(loading, Object.hashAll(palette ?? const []));
}

/// The tint of the album or artist page of [item], from the colours of the
/// image [shownCoverProvider] says the page shows: the custom cover's, else
/// [automaticCoverKey]'s (an album's track cover; an artist's `coverKey`, else
/// the cover of its first own album).
///
/// While that is unknown the result is `loading` with no palette, so a page
/// never draws the colours of a picture it is not showing.
DetailTint watchDetailTint(
  WidgetRef ref,
  CustomCoverItem item,
  String? automaticCoverKey,
) {
  final shown = ref.watch(
    shownCoverProvider((item: item, automaticCoverKey: automaticCoverKey)),
  );
  final String? coverKey;
  switch (shown) {
    case ShownCoverLoading():
      return const DetailTint(loading: true);
    case ShownCustomCover(coverKey: final custom):
      coverKey = custom;
    case ShownAutomaticCover(coverKey: final automatic):
      if (automatic == null) return DetailTint.none;
      coverKey = automatic;
  }
  final colors = ref.watch(coverColorsProvider(coverKey));
  // An error counts as "no colours": the page stays as it is without a tint.
  if (!colors.hasValue) {
    return colors.hasError ? DetailTint.none : const DetailTint(loading: true);
  }
  final value = colors.requireValue;
  if (value == null) return DetailTint.none;
  final ints = value.palette.isEmpty ? [value.seed] : value.palette;
  return DetailTint(palette: [for (final c in ints) Color(c)]);
}
