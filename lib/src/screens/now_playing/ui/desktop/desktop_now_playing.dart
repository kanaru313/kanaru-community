import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../playback/state/cover_providers.dart';
import '../../../../playback/state/now_playing_panel.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../state/desktop_view.dart';
import 'desktop_now_playing_body.dart';
import 'now_playing_auto_hide.dart';

/// The desktop Now Playing screen, as the shell's overlay shows it. It has its
/// own Scaffold (transparent over the cover tint), so snack bars appear on top
/// of it, and its own focus scope: Esc closes it here, before the history
/// input could take Esc as "go back".
///
/// Keys: Esc closes; `V` shows or hides the cover column (no modifier, no text
/// field focused, no menu open); any key shows the hidden header.
class DesktopNowPlaying extends ConsumerStatefulWidget {
  const DesktopNowPlaying({super.key});

  @override
  ConsumerState<DesktopNowPlaying> createState() => _DesktopNowPlayingState();
}

class _DesktopNowPlayingState extends ConsumerState<DesktopNowPlaying> {
  final _focus = FocusNode(debugLabel: 'Now Playing');
  final _chrome = AutoHideController();

  /// True while a menu floats outside the header; the header stays shown.
  final _floatingOpen = ValueNotifier<bool>(false);

  void _pinForFloating() =>
      _floatingOpen.value ? _chrome.pin() : _chrome.unpin();

  @override
  void initState() {
    super.initState();
    _floatingOpen.addListener(_pinForFloating);
    // `autofocus` alone loses to whatever the shell still has focused, which
    // is only released once this frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
    _chrome.poke();
  }

  @override
  void dispose() {
    _floatingOpen
      ..removeListener(_pinForFloating)
      ..dispose();
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
    if (key != LogicalKeyboardKey.keyV) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed ||
        keyboard.isShiftPressed ||
        _floatingOpen.value ||
        _textFieldFocused) {
      return KeyEventResult.ignored;
    }
    ref.read(coverColumnShownProvider.notifier).toggle();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final trackId = ref.watch(
      nowPlayingProvider.select((n) => n.value?.trackId),
    );
    final coverKey = trackId == null
        ? null
        : ref.watch(
            trackInfoProvider(trackId).select((i) => i.value?.coverKey),
          );
    final colors = coverKey == null
        ? null
        : ref.watch(coverColorsProvider(coverKey)).value;
    Color? tint(int i) => colors == null || colors.palette.length <= i
        ? null
        : Color(colors.palette[i]);
    final columnShown = ref.watch(coverColumnShownProvider);
    return FocusScope(
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _onKey,
        child: CoverTintBackground(
          first: tint(0),
          second: tint(1) ?? tint(0),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: DesktopNowPlayingBody(
              chrome: _chrome,
              floatingOpen: _floatingOpen,
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
