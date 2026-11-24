import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/track_id.dart';
import '../../domain/translation/translation_language.dart';
import 'translation_engine_providers.dart' show translationAppLanguageProvider;
import 'translation_settings.dart';

/// The language the user picked for one track ("Dịch sang…"), null when none;
/// the global target then applies.
final trackTranslationTargetProvider = StreamProvider.autoDispose
    .family<String?, TrackId>(
      (ref, id) => ref.watch(translationPrefsStoreProvider).watch(id),
    );

/// The language [id] is translated into now (what "Dịch sang" shows): the
/// song's own, else the global one, else the app language's default. The
/// engine plans with the same [pickTranslationTarget].
final effectiveTranslationTargetProvider = Provider.autoDispose
    .family<String, TrackId>(
      (ref, id) => pickTranslationTarget(
        trackPref: ref.watch(trackTranslationTargetProvider(id)).value,
        global: ref.watch(translationTargetProvider),
        appLanguage: ref.watch(translationAppLanguageProvider),
      ),
    );
