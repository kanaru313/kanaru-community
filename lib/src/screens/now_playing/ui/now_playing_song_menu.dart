import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/ui/menus/menu_items.dart';
import '../../../library/ui/menus/menu_model.dart';
import '../../../library/ui/menus/open_menu.dart';
import '../../../library/ui/menus/song_lyrics_entry.dart';
import '../../../lyrics/state/playing_lyrics_providers.dart';
import '../../../lyrics/ui/lyrics_for_track_modal.dart';
import '../../../media/domain/track_info.dart';
import '../../../playback/state/playback_providers.dart';
import '../../../playback/state/sleep_timer_provider.dart';
import '../../../playback/state/track_info_providers.dart';
import '../../../playback/ui/sleep_timer/sleep_timer_modal.dart';
import '../../../playback/ui/sleep_timer/sleep_timer_texts.dart';
import 'desktop/now_playing_chrome.dart';

final _log = Logger('NowPlayingSongMenu');

/// Opens the ⋮ menu of Now Playing: the menu of the playing song, with
/// "Sleep timer" before the lyrics row and "Translate lyrics…" (soon) and
/// "Visual effects" (Pro) after it. Both shells call this one function.
///
/// The menu keeps the song it was opened for, even if the queue moves on while
/// it is open. A song that is not in the library (or nothing playing) shows the
/// "not in your library" toast. [closeNowPlaying] closes Now Playing before a
/// "Go to" row opens its page. [chrome] (desktop) keeps the header shown for
/// as long as the menu, and any dialog opened from it, is up, whichever way it
/// ends; [returnFocus] gets focus back when the sleep timer closes.
///
/// The lyrics row follows the *playing* song at tap time (not the opened one),
/// so after a track change its subtitle can describe the previous song; with
/// nothing playing it shows the "not in your library" toast.
///
/// Never throws: callers fire it with `unawaited`, so any failure is logged and
/// shown as the "could not load" toast here.
Future<void> openNowPlayingSongMenu(
  BuildContext context, {
  VoidCallback? closeNowPlaying,
  NowPlayingChrome? chrome,
  FocusNode? returnFocus,
  bool viaKeyboard = false,
}) async {
  Future<void> open() => _open(
    context,
    closeNowPlaying: closeNowPlaying,
    returnFocus: returnFocus,
    viaKeyboard: viaKeyboard,
  );
  final root = Navigator.of(context, rootNavigator: true).context;
  final l10n = AppLocalizations.of(context);
  try {
    if (chrome == null) {
      await open();
    } else {
      // A header that left the tree meanwhile (Now Playing closed) leaves the
      // controller alone: the screen disposes it.
      await chrome.whilePinned(open, stillOwned: () => context.mounted);
    }
  } on Object catch (e, s) {
    _log.severe('the Now Playing song menu failed', e, s);
    if (root.mounted) showAppSnackBar(root, l10n.libraryMenuLoadFailed);
  }
}

Future<void> _open(
  BuildContext context, {
  required VoidCallback? closeNowPlaying,
  required FocusNode? returnFocus,
  required bool viaKeyboard,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final root = Navigator.of(context, rootNavigator: true).context;
  final l10n = AppLocalizations.of(context);
  final texts = SleepTimerTexts.of(context);

  final TrackInfo? info;
  try {
    final id = container.read(nowPlayingProvider).value?.trackId;
    info = id == null
        ? null
        : await container.read(trackInfoProvider(id).future);
  } on Object catch (e, s) {
    _log.warning('reading the playing song failed', e, s);
    if (root.mounted) showAppSnackBar(root, l10n.libraryMenuLoadFailed);
    return;
  }
  if (info == null) {
    if (root.mounted) showAppSnackBar(root, l10n.libraryNotFoundMessage);
    return;
  }
  if (!context.mounted) return;

  final sleepLabel = _SleepTimerLabel(container, texts);
  // A "Go to" row closes Now Playing first: focus must not go back then.
  var navigated = false;
  final VoidCallback? beforeNavigate = closeNowPlaying == null
      ? null
      : () {
          navigated = true;
          closeNowPlaying();
        };
  try {
    await openSongMenu(
      context,
      info,
      viaKeyboard: viaKeyboard,
      beforeNavigate: beforeNavigate,
      selectRow: false,
      queueButtons: false,
      // The lyrics row follows the playing song, as the source button does.
      openLyrics: container.read(songLyricsEntryProvider) == null
          ? null
          : (ctx) => _openLyricsOfPlaying(ctx, container),
      aroundLyrics: (
        before: [
          MenuItemSpec(
            MenuItemId.sleepTimer,
            icon: KIcons.sleepTimer,
            title: l10n.playbackSleepTimer,
            liveTitle: sleepLabel,
            action: MenuAction.run(
              (ctx) => showSleepTimer(ctx, returnFocus: returnFocus),
            ),
          ),
        ],
        after: [
          soonRow(
            MenuItemId.translate,
            KIcons.language,
            l10n.playbackTranslateLyrics,
          ),
          MenuItemSpec(
            MenuItemId.visualEffects,
            icon: KIcons.image,
            title: l10n.playbackVisualEffects,
            // Dimmed with the Pro pill, no "Coming soon" (spec 02-now-playing).
            enabled: false,
            pro: true,
          ),
        ],
      ),
    );
  } finally {
    sleepLabel.close();
    // Esc / a finished row action: focus goes back to the ⋮ button (desktop).
    if (!navigated &&
        context.mounted &&
        returnFocus != null &&
        returnFocus.context != null &&
        returnFocus.canRequestFocus) {
      returnFocus.requestFocus();
    }
  }
}

Future<void> _openLyricsOfPlaying(
  BuildContext context,
  ProviderContainer container,
) async {
  final id = container.read(playingLyricsProvider).trackId;
  if (id == null) {
    showAppSnackBar(
      context,
      AppLocalizations.of(context).libraryNotFoundMessage,
    );
    return;
  }
  await showLyricsForTrack(context, id, followsPlaying: true);
}

/// The sleep timer row's title while the menu is open: "Sleep timer" or
/// "Sleep timer · 23:41 left", following the timer's state.
class _SleepTimerLabel extends ValueNotifier<String> {
  _SleepTimerLabel(ProviderContainer container, SleepTimerTexts texts)
    : super(texts.menuLabel(container.read(sleepTimerProvider))) {
    _sub = container.listen<SleepTimerState>(
      sleepTimerProvider,
      (_, s) => value = texts.menuLabel(s),
    );
  }

  late final ProviderSubscription<SleepTimerState> _sub;

  void close() {
    _sub.close();
    dispose();
  }
}
