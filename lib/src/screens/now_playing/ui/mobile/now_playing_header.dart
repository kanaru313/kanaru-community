import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../../../playback/ui/sleep_timer/sleep_timer_entries.dart';

/// Height of the mobile page header.
const double nowPlayingHeaderHeight = 56;

/// Height from 200 % text on, so the two title lines fit.
const double nowPlayingHeaderTallHeight = 72;

/// Width of a header button (the ring button has the same 40 dp).
const double _buttonWidth = KIconButton.defaultWidth;

/// Each side of the title is kept free for the buttons on the right: the ring
/// slot (always reserved, so the title never moves when a timer starts) and ⋮.
/// The left side takes the same width, so the title is centred on the screen.
const double _sideWidth = _buttonWidth * 2;

/// `[⌄] · position over album · [ring][⋮]` (the album line is empty when the
/// track has none). The whole part between the side slots is the drag handle
/// the page owner attaches a gesture to ([dragHandle]).
class NowPlayingHeader extends ConsumerStatefulWidget {
  const NowPlayingHeader({
    super.key,
    required this.onClose,
    required this.onMore,
    required this.dragHandle,
  });

  final VoidCallback onClose;
  final VoidCallback onMore;

  /// Wraps the title area with the drag-to-close gesture.
  final Widget Function(Widget child) dragHandle;

  @override
  ConsumerState<NowPlayingHeader> createState() => _NowPlayingHeaderState();
}

class _NowPlayingHeaderState extends ConsumerState<NowPlayingHeader> {
  /// The ⋮ button: where focus goes when the ring button leaves.
  final _moreFocus = FocusNode(debugLabel: 'now playing more');

  @override
  void dispose() {
    _moreFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final place = ref.watch(
      nowPlayingProvider.select((n) => (n.value?.index, n.value?.length)),
    );
    final id = ref.watch(nowPlayingProvider.select((n) => n.value?.trackId));
    final album = id == null
        ? null
        : ref.watch(trackInfoProvider(id).select((i) => i.value?.album));
    final (index, length) = place;
    final tall = MediaQuery.textScalerOf(context).scale(1) >= 2;
    return SizedBox(
      height: tall ? nowPlayingHeaderTallHeight : nowPlayingHeaderHeight,
      child: Stack(
        children: [
          Positioned.fill(
            left: _sideWidth,
            right: _sideWidth,
            child: widget.dragHandle(
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index != null)
                      Text(
                        '${index + 1}/$length',
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      album ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: KIconButton(
              icon: KIcons.collapse,
              tooltip: l10n.playbackMinimize,
              onPressed: widget.onClose,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: _buttonWidth,
                  child: Center(
                    child: SleepTimerRingButton(fallbackFocus: _moreFocus),
                  ),
                ),
                KIconButton(
                  icon: KIcons.moreVert,
                  tooltip: l10n.playbackMore,
                  focusNode: _moreFocus,
                  onPressed: widget.onMore,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
