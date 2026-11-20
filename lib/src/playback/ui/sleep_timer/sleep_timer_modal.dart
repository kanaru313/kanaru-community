import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/playback_providers.dart';
import '../../state/sleep_timer_provider.dart';
import 'sleep_timer_announce.dart';
import 'sleep_timer_custom_view.dart';
import 'sleep_timer_draft.dart';
import 'sleep_timer_focus.dart';
import 'sleep_timer_running_view.dart';
import 'sleep_timer_texts.dart';
import 'sleep_timer_tiles_view.dart';

/// Opens the sleep timer: a bottom sheet on phones, a dialog from 600 px, on
/// the root navigator. It opens on the running screen while a timer runs, else
/// on the tiles. [returnFocus] gets focus back when it closes.
Future<void> showSleepTimer(
  BuildContext context, {
  required FocusNode returnFocus,
}) => showKSheet<void>(
  context,
  dialog: KSheetDialog.modal,
  useRootNavigator: true,
  returnFocus: returnFocus,
  builder: (_) => const _SleepTimerModal(),
);

enum _Screen { tiles, custom, running }

class _SleepTimerModal extends ConsumerStatefulWidget {
  const _SleepTimerModal();

  @override
  ConsumerState<_SleepTimerModal> createState() => _SleepTimerModalState();
}

class _SleepTimerModalState extends ConsumerState<_SleepTimerModal> {
  final _focus = SleepTimerFocus();
  late _Screen _screen;
  SleepTimerDraft _draft = const SleepTimerDraft();
  late SleepTimerAnnouncer _announcer;

  /// One pop only, whatever closes the modal first (a button, the timer
  /// ending, the track going away).
  bool _closed = false;

  /// The modal should close but another route covers it: it closes when it is
  /// the current route again, so nothing stale shows.
  bool _closeWhenCurrent = false;

  @override
  void initState() {
    super.initState();
    _screen = ref.read(sleepTimerProvider).active
        ? _Screen.running
        : _Screen.tiles;
    // The timer turning off by itself while its screen shows.
    ref.listenManual(sleepTimerProvider.select((s) => s.active), (_, active) {
      if (active || _screen != _Screen.running || _closed) return;
      _announcer.say(SleepTimerTexts.of(context).announceExpired);
      _requestClose();
    });
    // No track, no timer entry: the modal has nothing to set.
    ref.listenManual(hasCurrentTrackProvider, (_, has) {
      if (!has) _requestClose();
    });
    _focusScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _announcer = SleepTimerAnnouncer.of(context);
    if (_closeWhenCurrent && (ModalRoute.of(context)?.isCurrent ?? true)) {
      _closeWhenCurrent = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _close());
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    Navigator.of(context).pop();
  }

  void _requestClose() {
    if (_closed) return;
    if (ModalRoute.of(context)?.isCurrent ?? true) {
      _close();
    } else {
      _closeWhenCurrent = true;
    }
  }

  /// Initial focus of the screen just shown, for the keyboard shell. On touch
  /// shells nothing takes focus (a focused number would raise the keyboard
  /// over the sheet). Content swapped in after the first frame cannot use
  /// `autofocus`, so every switch asks for focus itself.
  void _focusScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || FormFactor.of(context) != FormFactor.desktop) return;
      switch (_screen) {
        case _Screen.tiles:
          if (!ref.read(sleepTimerProvider).active ||
              !_focus.focusRunningCard()) {
            _focus.tile45.requestFocus();
          }
        case _Screen.custom:
          _focus.number.requestFocus();
        case _Screen.running:
          _focusFirstRunningControl();
      }
    });
  }

  void _focusFirstRunningControl() {
    final s = ref.read(sleepTimerProvider);
    final candidates = <(FocusNode, bool)>[
      (_focus.minus, s.canSubtract(sleepMinutesRange.step) || s.canRemoveTrack),
      (_focus.plus, s.mode == SleepTimerMode.minutes || s.canAddTrack),
      (_focus.pause, s.mode == SleepTimerMode.minutes),
      (_focus.off, true),
      (_focus.change, true),
    ];
    for (final (node, enabled) in candidates) {
      if (enabled && node.canRequestFocus && node.context != null) {
        node.requestFocus();
        return;
      }
    }
  }

  void _show(_Screen screen) {
    setState(() => _screen = screen);
    _focusScreen();
  }

  /// A tile or row: start the timer, say so once, close.
  void _startAndClose(void Function(SleepTimer timer) start) {
    final timer = ref.read(sleepTimerProvider.notifier);
    start(timer);
    final started = ref.read(sleepTimerProvider);
    // A start the engine ignored (no player yet) says nothing.
    if (started.active) {
      _announcer.say(
        SleepTimerTexts.of(context).announceStart(started, DateTime.now()),
      );
    }
    _close();
  }

  void _turnOff() {
    // Closed first: the timer turning off must not read as it ending by
    // itself (no second close, no "ended" announcement).
    _close();
    ref.read(sleepTimerProvider.notifier).cancel();
    _announcer.say(SleepTimerTexts.of(context).announceCancelled);
  }

  /// "Đổi…": minutes and tracks go to the custom screen filled with what runs;
  /// the end-of modes have nothing to fill, so the tiles (with the running
  /// card) are shown.
  void _change() {
    final s = ref.read(sleepTimerProvider);
    final custom =
        s.mode == SleepTimerMode.minutes || s.mode == SleepTimerMode.tracks;
    if (custom) _draft = SleepTimerDraft.fromState(s);
    _show(custom ? _Screen.custom : _Screen.tiles);
  }

  void _openCustom(SleepTimerKind kind) {
    _draft = const SleepTimerDraft().withKind(kind);
    _show(_Screen.custom);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = SleepTimerTexts.of(context).l10n;
    return Semantics(
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: true,
      label: l10n.playbackSleepTimer,
      child: switch (_screen) {
        _Screen.tiles => SleepTimerTilesView(
          focus: _focus,
          onStart: _startAndClose,
          onCustom: _openCustom,
          onRunning: () => _show(_Screen.running),
          onCancel: _close,
        ),
        _Screen.custom => SleepTimerCustomView(
          draft: _draft,
          focus: _focus,
          onDraft: (d) => setState(() => _draft = d),
          onBack: () => _show(_Screen.tiles),
          onRunning: () => _show(_Screen.running),
          onStart: () => _startAndClose(_draft.startOn),
          onCancel: _close,
        ),
        _Screen.running => SleepTimerRunningView(
          focus: _focus,
          announcer: _announcer,
          onOff: _turnOff,
          onChange: _change,
        ),
      },
    );
  }
}
