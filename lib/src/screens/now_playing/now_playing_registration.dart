import 'package:logging/logging.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../extension/state/extension_registry.dart';
import '../../extension/state/registry_entries.dart';
import '../../platform/state/media_controls_provider.dart';
import '../../playback/state/playback_flush.dart';

final _log = Logger('now_playing.registration');

/// How long the media session may take to start before the app goes on
/// without it.
const mediaSessionStartTimeout = Duration(seconds: 3);

/// Registers the playback module's seams: the exit hook that pauses, the
/// flush hook that saves the session, the Android media session start and
/// the Queue nav item (a placeholder until the Now Playing screen lands).
void registerNowPlaying(ExtensionRegistry registry) {
  registry
    ..addBeforeExitHook(pausePlaybackOnExitHook)
    ..addFlushHook(playbackFlushHook)
    ..addStartupHook(mediaSessionStartHook())
    ..addNavItem(
      NavItem(
        id: 'queue',
        path: '/queue',
        icon: KIcons.queue,
        selectedIcon: KIcons.queue,
        label: (c) => AppLocalizations.of(c).playbackNavQueue,
        order: 230,
        mobileTab: false,
        comingSoon: true,
      ),
    );
}

/// Startup hook for the media session. It must run once per process (the
/// Android audio service wants its init at launch), but a failure or a hang
/// never stops the app from starting. [start] and [timeout] are for tests.
StartupHook mediaSessionStartHook({
  Future<void> Function()? start,
  Duration timeout = mediaSessionStartTimeout,
}) {
  final init = start ?? initAndroidMediaSession;
  return (StartupContext _) async {
    try {
      await init().timeout(timeout);
    } on Object catch (e, st) {
      _log.warning('media session did not start: $e', e, st);
    }
  };
}
