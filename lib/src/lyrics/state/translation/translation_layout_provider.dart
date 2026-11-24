import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/track_id.dart';
import '../../domain/translation/translation_language.dart';
import 'translation_settings.dart';
import 'translation_target_provider.dart';

/// How the lyrics views lay translated lines out for one track.
typedef TranslationLayout = ({
  /// The translation takes the line's place (the original becomes a small
  /// dim line above it).
  bool replace,

  /// The translation is written right to left.
  bool rtl,
});

/// The layout of [id]'s translated lines, or null while translation is off:
/// then no lyrics view shows, or asks for, a translation.
final translationLayoutProvider = Provider.autoDispose
    .family<TranslationLayout?, TrackId>((ref, id) {
      if (!ref.watch(translationOnProvider)) return null;
      final target = ref.watch(effectiveTranslationTargetProvider(id));
      return (
        replace:
            ref.watch(translationDisplayProvider) == TranslationDisplay.replace,
        rtl: rtlLanguages.contains(baseLanguage(target)),
      );
    });
