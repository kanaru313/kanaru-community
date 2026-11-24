import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../plugins/state/plugin_run_provider.dart';
import '../../../plugins/state/plugin_store_providers.dart';
import '../../data/translation/translate_runner.dart';
import '../../data/translation/translation_jobs.dart';
import '../../data/translation/translation_job_types.dart';
import '../../data/translation/translation_services.dart';
import '../lyrics_choice_commands.dart' show lyricsClockProvider;
import 'translation_settings.dart';

typedef TranslationTimerFactory = Timer Function(
  Duration after,
  void Function() run,
);

/// The app's language code (`vi`, `en`), which picks the default target.
/// The lyrics module cannot read the appearance setting (it sits above), so
/// the app overrides this where it wires the screens.
final translationAppLanguageProvider = Provider<String>((ref) => 'en');

/// How long a song must stay in view before its translation is requested, so
/// skipping through songs bills nothing.
final translationDebounceProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 1),
);

/// The timer behind the debounce; tests replace it.
final translationTimerProvider = Provider<TranslationTimerFactory>(
  (ref) => Timer.new,
);

final translateRunnerProvider = Provider<TranslateRunner>(
  (ref) => TranslateRunner(
    ref.watch(pluginRunnerProvider),
    ref.watch(pluginPausesProvider),
  ),
);

final translationServicesProvider = Provider<TranslationServices>(
  (ref) => PluginTranslationServices(
    rows: ref.watch(pluginRowsProvider),
    config: ref.watch(pluginConfigStoreProvider),
  ),
);

/// Owns every translation run (keep-alive, never watched into a rebuild).
/// Its state is what each key that runs or failed shows; a key without an
/// entry is idle and its result is the saved row.
class TranslationJobsNotifier extends Notifier<Map<JobKey, JobStatus>> {
  late TranslationJobs engine;

  @override
  Map<JobKey, JobStatus> build() {
    // Read, not watch: a rebuild would drop the jobs that are running.
    engine = TranslationJobs(
      runner: ref.read(translateRunnerProvider),
      cache: ref.read(translationCacheStoreProvider),
      services: ref.read(translationServicesProvider),
      mayRun: _mayRun,
      now: ref.read(lyricsClockProvider),
      onChange: () {
        if (ref.mounted) state = engine.statuses;
      },
    );
    ref.onDispose(engine.dispose);
    return const {};
  }

  /// Translation is on and [installId] is the live, chosen service. Asked
  /// before every send, so a switch-off or a service change stops unsent work.
  bool _mayRun(String installId) =>
      ref.read(translationOnProvider) &&
      ref.read(effectiveTranslationServiceProvider).value == installId;
}

final translationJobsProvider =
    NotifierProvider<TranslationJobsNotifier, Map<JobKey, JobStatus>>(
      TranslationJobsNotifier.new,
    );
