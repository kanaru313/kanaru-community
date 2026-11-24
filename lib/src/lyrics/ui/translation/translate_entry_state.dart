import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/domain/track_id.dart';
import '../../../plugins/state/plugin_store_providers.dart';
import '../../domain/lyrics_status.dart';
import '../../domain/translation/translation_status.dart';
import '../../state/playing_lyrics_providers.dart';
import '../../state/translation/translation_providers.dart';
import '../../state/translation/translation_settings.dart';
import 'shown_translation.dart';

/// What the translate entry points (the lyrics-screen button, the desktop
/// pill, the ⋮ item) show about the playing song. One place derives it, so
/// the three never disagree.
class TranslateEntryState {
  const TranslateEntryState({
    this.trackId,
    this.available = false,
    this.on = false,
    this.working = false,
    this.failed = false,
    this.target,
    this.installId,
    this.pluginName,
  });

  /// Nothing plays.
  static const none = TranslateEntryState();

  /// The playing track.
  final TrackId? trackId;

  /// The song has lyrics to translate; without them every entry is dimmed and
  /// inert.
  final bool available;

  /// Translation is turned on.
  final bool on;

  /// A run for the song is going (a forced "Dịch lại" included).
  final bool working;

  /// The last attempt failed, whatever the failure (a half-done run too).
  final bool failed;

  /// Code of the language the song is translated into (`translationLanguageCodes`);
  /// null when nothing plays.
  final String? target;

  /// The plugin whose translation is on screen and its name; null while the
  /// lyrics show none.
  final String? installId;
  final String? pluginName;

  /// A translation is on screen (ready, another plugin's copy, half done).
  bool get translated => !working && installId != null;

  @override
  bool operator ==(Object other) =>
      other is TranslateEntryState &&
      other.trackId == trackId &&
      other.available == available &&
      other.on == on &&
      other.working == working &&
      other.failed == failed &&
      other.target == target &&
      other.installId == installId &&
      other.pluginName == pluginName;

  @override
  int get hashCode => Object.hash(
    trackId,
    available,
    on,
    working,
    failed,
    target,
    installId,
    pluginName,
  );
}

/// The entry state of the playing song. It is passive: it reads what a
/// mounted lyrics view publishes ([shownTranslationProvider]) and never
/// watches `trackTranslationProvider`, so the entry points can never start (or
/// bill) a translation. With no lyrics view of the song mounted they show on
/// or off from the settings only.
final translateEntryProvider = Provider.autoDispose<TranslateEntryState>((ref) {
  final playing = ref.watch(playingLyricsProvider);
  final id = playing.trackId;
  if (id == null) return TranslateEntryState.none;
  final available = playing.lyrics is LyricsShown;
  final on = ref.watch(translationOnProvider);
  final target = ref.watch(effectiveTranslationTargetProvider(id));
  if (!available || !on) {
    return TranslateEntryState(
      trackId: id,
      available: available,
      on: on,
      target: target,
    );
  }
  final view = ref.watch(shownTranslationProvider.select((m) => m[id]));
  if (view == null) {
    return TranslateEntryState(
      trackId: id,
      available: true,
      on: true,
      target: target,
    );
  }
  final status = view.status;
  final installId = view.installId;
  final plugin = installId == null
      ? null
      : ref.watch(installedPluginProvider(installId)).value;
  final hasCopy =
      view.map.isNotEmpty &&
      plugin != null &&
      (status is StatusReady ||
          status is StatusOther ||
          status is StatusFailed);
  return TranslateEntryState(
    trackId: id,
    available: true,
    on: true,
    working: status is StatusLoading,
    failed: status is StatusFailed,
    target: target,
    installId: hasCopy ? installId : null,
    pluginName: hasCopy ? plugin.name : null,
  );
});
