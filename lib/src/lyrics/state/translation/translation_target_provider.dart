import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/track_id.dart';
import 'translation_settings.dart';

/// The language the user picked for one track ("Dịch sang…"), null when none;
/// the global target then applies.
final trackTranslationTargetProvider = StreamProvider.autoDispose
    .family<String?, TrackId>(
      (ref, id) => ref.watch(translationPrefsStoreProvider).watch(id),
    );
