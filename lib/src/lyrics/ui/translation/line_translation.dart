import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import '../../../media/domain/track_id.dart';
import '../../domain/lyrics.dart';
import '../../domain/translation/translation_alignment.dart';
import '../../domain/translation/translation_status.dart';
import '../../state/translation/translation_layout_provider.dart';
import '../../state/translation/translation_providers.dart';
import '../../state/translation/translation_view.dart';

/// What one lyric line shows of its translation. Part of the line's intent:
/// the line widget decides how it looks.
class LineTranslation {
  const LineTranslation({
    this.text,
    this.pending = false,
    this.replace = false,
    this.rtl = false,
  });

  /// The translated text; null when the line has none.
  final String? text;

  /// The translation is on its way: a bar stands where it will be.
  final bool pending;

  /// The translation is the line, the original a small dim line above it.
  final bool replace;

  /// The translation is written right to left.
  final bool rtl;

  @override
  bool operator ==(Object other) =>
      other is LineTranslation &&
      other.text == text &&
      other.pending == pending &&
      other.replace == replace &&
      other.rtl == rtl;

  @override
  int get hashCode => Object.hash(text, pending, replace, rtl);
}

/// The text and waiting state of [line] in [view]: nothing for a gap, for a
/// translation that only repeats the line, and while the lyrics already are in
/// the target language.
({String? text, bool pending}) lineTranslationOf(
  LyricLine line,
  TranslationView view,
) {
  final status = view.status;
  if (status is StatusSame || status is StatusIdle) {
    return (text: null, pending: false);
  }
  final text = translationFor(line, view.map);
  final waiting =
      text == null &&
      status is StatusLoading &&
      !status.background &&
      line.text.trim().isNotEmpty;
  return (text: text, pending: waiting);
}

/// Builds one line with its translation. It watches only this line's slice
/// of the track's translation, so a chunk that arrives rebuilds the lines it
/// covers and no others. Watching is also what asks for the translation
/// while lyrics are shown.
class TranslatedLineScope extends ConsumerWidget {
  const TranslatedLineScope({
    super.key,
    required this.trackId,
    required this.line,
    required this.layout,
    required this.builder,
  });

  final TrackId trackId;
  final LyricLine line;
  final TranslationLayout layout;
  final Widget Function(BuildContext context, LineTranslation translation)
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = ref.watch(
      trackTranslationProvider(trackId)
          .select((v) => lineTranslationOf(line, v)),
    );
    return builder(
      context,
      LineTranslation(
        text: shown.text,
        pending: shown.pending,
        replace: layout.replace,
        rtl: layout.rtl,
      ),
    );
  }
}
