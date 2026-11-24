import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../lyrics/state/playing_lyrics_providers.dart';
import '../../../../lyrics/ui/lyrics_for_track_modal.dart';
import '../../../../lyrics/ui/translation/translate_entry.dart';
import '../../../../playback/state/playing_cover_colors.dart';
import '../../../../playback/state/now_playing_panel.dart';
import '../../state/desktop_view.dart';
import 'desktop_now_playing_body.dart';
import 'now_playing_chrome.dart';

/// The desktop Now Playing screen, as the shell's overlay shows it. It has its
/// own Scaffold (transparent over the cover tint), so snack bars appear on top
/// of it, and its own focus scope: Esc closes it here, before the history
/// input could take Esc as "go back".
///
/// Keys: Esc closes; `V` shows or hides the cover column, `L` opens the
/// lyrics modal and `T` turns translation on or off (no modifier, no text field focused, no menu open); any key shows the hidden header.
class DesktopNowPlaying extends ConsumerStatefulWidget {
  const DesktopNowPlaying({super.key});

  @override
  ConsumerState<DesktopNowPlaying> createState() => _DesktopNowPlayingState();
}

class _DesktopNowPlayingState extends ConsumerState<DesktopNowPlaying> {
  final _focus = FocusNode(debugLabel: 'Now Playing');
  final _chrome = NowPlayingChrome();

  @override
  void initState() {
    super.initState();
    // `autofocus` alone loses to whatever the shell still has focused, which
    // is only released once this frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
    _chrome.poke();
  }

  @override
  void dispose() {
    _focus.dispose();
    _chrome.dispose();
    super.dispose();
  }

  void _close() => ref.read(nowPlayingPanelProvider.notifier).close();

  bool get _textFieldFocused {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    _chrome.poke();
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (_textFieldFocused) return KeyEventResult.ignored;
      _close();
      return KeyEventResult.handled;
    }
    if (key != LogicalKeyboardKey.keyV &&
        key != LogicalKeyboardKey.keyL &&
        key != LogicalKeyboardKey.keyT) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed ||
        keyboard.isShiftPressed ||
        _chrome.hasFloating ||
        _textFieldFocused) {
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.keyL) {
      final id = ref.read(playingLyricsProvider).trackId;
      if (id == null) return KeyEventResult.ignored;
      // The page may close while the modal is open: then it leaves the
      // controller to its own dispose.
      unawaited(
        _chrome.whilePinned(
          () => showLyricsForTrack(context, id, followsPlaying: true),
          stillOwned: () => mounted,
        ),
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyT) {
      // Without lyrics there is nothing to translate: the key is not taken.
      if (!ref.read(translateMenuAvailableProvider)) {
        return KeyEventResult.ignored;
      }
      toggleTranslationNow(context, ref);
      return KeyEventResult.handled;
    }
    ref.read(coverColumnShownProvider.notifier).toggle();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final cover = ref.watch(playingCoverColorsProvider);
    final columnShown = ref.watch(coverColumnShownProvider);
    return FocusScope(
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        child: CoverTintBackground(
          palette: cover.palette,
          loading: cover.isPending,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: DesktopNowPlayingBody(
              chrome: _chrome,
              columnShown: columnShown,
              onToggleColumn: ref
                  .read(coverColumnShownProvider.notifier)
                  .toggle,
              onClose: _close,
            ),
          ),
        ),
      ),
    );
  }
}
