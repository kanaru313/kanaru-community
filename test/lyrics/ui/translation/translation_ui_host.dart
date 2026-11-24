import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kanaru/src/lyrics/domain/translation/translation_status.dart';
import 'package:kanaru/src/lyrics/state/translation/track_translation_notifier.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_credit_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_providers.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_view.dart';
import 'package:kanaru/src/media/domain/track_id.dart';

/// The translation every track shows in a test, set by the test.
class ViewBox extends Notifier<TranslationView> {
  @override
  TranslationView build() => TranslationView.idle;

  void set(TranslationView view) => state = view;
}

final viewBox = NotifierProvider<ViewBox, TranslationView>(ViewBox.new);

/// The credit of every track, set by the test.
class CreditBox extends Notifier<TranslationCredit?> {
  @override
  TranslationCredit? build() => null;

  void set(TranslationCredit? credit) => state = credit;
}

final creditBox = NotifierProvider<CreditBox, TranslationCredit?>(
  CreditBox.new,
);

/// How many times a track's translation was built (asked for).
int translationAsks = 0;

/// A translation that shows what the test put in [viewBox].
class FakeTrackTranslation extends TrackTranslation {
  FakeTrackTranslation(super.trackId);

  @override
  TranslationView build() {
    translationAsks++;
    return ref.watch(viewBox);
  }
}

/// Overrides that give the lyrics views a translation without a database or a
/// plugin: [target] is the language shown, [viewBox] the translation.
List<Override> translationOverrides({String target = 'vi'}) {
  translationAsks = 0;
  return [
    trackTranslationProvider.overrideWith2(FakeTrackTranslation.new),
    effectiveTranslationTargetProvider.overrideWith((ref, id) => target),
    translationCreditProvider.overrideWith((ref, id) => ref.watch(creditBox)),
  ];
}

/// A ready translation of [map].
TranslationView readyView(Map<String, String> map) =>
    TranslationView(status: const TranslationStatus.ready(), map: map);

/// A translation that is still coming.
const pendingView = TranslationView(status: TranslationStatus.loading(0, 3));

/// Turns translation on (and replace mode when [replace]) in [container].
Future<void> turnTranslationOn(
  ProviderContainer container, {
  bool replace = false,
}) async {
  await container.read(translationOnProvider.notifier).set(true);
  if (replace) {
    await container
        .read(translationDisplayProvider.notifier)
        .set(TranslationDisplay.replace);
  }
}

const trackOne = TrackId(1);
