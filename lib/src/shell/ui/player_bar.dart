import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../media/domain/cover_files.dart';
import '../../playback/state/playback_providers.dart';
import '../../playback/state/playing_cover_colors.dart';
import '../../playback/state/track_info_providers.dart';
import '../../playback/ui/play_pause_button.dart';
import '../../playback/ui/playback_time_label.dart';
import '../../playback/ui/track_cover.dart';
import '../../playback/ui/transport_buttons.dart';
import '../../playback/ui/volume_control.dart';
import '../../screens/now_playing/ui/favorite_button.dart';
import '../../playback/state/now_playing_panel.dart';
import '../state/right_panel.dart';

/// Left-part widths below which the bar drops controls: under [wide] no
/// volume, sleep timer or favorite; under [narrow] no shuffle or repeat.
const double playerBarWide = 1000;
const double playerBarNarrow = 760;

/// How much of the playing cover's colour tints the bar: 0.5, the chosen
/// strength, lighter than Now Playing at full strength (1). It multiplies the
/// alpha of the gradient stops, which are already lowered until the text keeps
/// its contrast, so any value in (0, 1] stays readable.
const double playerBarTintStrength = 0.5;

/// Desktop player bar under the page: 88 dp, shown only while a track is
/// current. Lyrics, the cover and expand open Now Playing (the bar is offstage
/// while it is open); Queue toggles the shell's right panel.
class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key});

  static const double height = 88;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final cover = ref.watch(playingCoverColorsProvider);
    // Same provider and widget as Now Playing, so a later drag-to-expand
    // shows one continuous tint. No colours: the flat surface, as before.
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: RepaintBoundary(
        child: CoverTintBackground(
          palette: cover.palette,
          loading: cover.isPending,
          strength: playerBarTintStrength,
          base: scheme.surfaceContainerLow,
          child: SizedBox(
            height: height,
            child: LayoutBuilder(
              builder: (context, box) {
                final full = box.maxWidth >= playerBarWide;
                final transport = box.maxWidth >= playerBarNarrow;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: KSpace.x4),
                  child: Row(
                    spacing: KSpace.x4,
                    children: [
                      Expanded(child: _TrackPart(showFavorite: full)),
                      Flexible(
                        flex: 2,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 240,
                              maxWidth: 520,
                            ),
                            child: _CenterPart(showShuffleRepeat: transport),
                          ),
                        ),
                      ),
                      // Natural width: the buttons never shrink, the title does.
                      _ToolsPart(full: full),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackPart extends ConsumerWidget {
  const _TrackPart({required this.showFavorite});

  final bool showFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackId = ref.watch(
      nowPlayingProvider.select((n) => n.value?.trackId),
    );
    final info = trackId == null
        ? null
        : ref.watch(trackInfoProvider(trackId)).value;
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Tooltip(
          message: l10n.playbackOpenNowPlaying,
          child: KPressable(
            radius: KRadius.xs,
            onTap: () => ref.read(nowPlayingPanelProvider.notifier).open(),
            child: TrackCover(
              coverKey: info?.coverKey,
              seed: info?.albumKey?.toString() ?? info?.title ?? '',
              size: CoverSize.thumb,
              dimension: 58,
              radius: KRadius.xs,
            ),
          ),
        ),
        const SizedBox(width: KSpace.x3),
        // The text takes only the width it needs, so the heart sits right
        // after the title/artist block.
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info?.title ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (info?.artist != null)
                Text(
                  info!.artist!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (showFavorite && trackId != null) FavoriteButton(trackId: trackId),
      ],
    );
  }
}

class _CenterPart extends StatelessWidget {
  const _CenterPart({required this.showShuffleRepeat});

  final bool showShuffleRepeat;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showShuffleRepeat) const ShuffleButton(),
            const PreviousButton(),
            const PlayPauseButton(filled: true, iconSize: 28),
            const NextButton(),
            if (showShuffleRepeat) const RepeatButton(),
          ],
        ),
        const Row(
          spacing: KSpace.x2,
          children: [
            PlaybackTimeLabel(),
            Expanded(child: RepaintBoundary(child: PlaybackSeekBar())),
            PlaybackTimeLabel(total: true),
          ],
        ),
      ],
    );
  }
}

class _ToolsPart extends ConsumerWidget {
  const _ToolsPart({required this.full});

  final bool full;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final panel = ref.read(nowPlayingPanelProvider.notifier);
    final queueOpen = ref.watch(rightPanelProvider) == RightPanelKind.queue;
    final soon = l10n.appComingSoon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (full)
          IconButton(
            icon: const Icon(KIcons.sleepTimer),
            tooltip: '${l10n.playbackSleepTimer} · $soon',
            onPressed: null,
          ),
        IconButton(
          icon: const Icon(KIcons.lyrics),
          tooltip: l10n.playbackLyrics,
          onPressed: panel.open,
        ),
        IconButton(
          icon: const Icon(KIcons.queueMusic),
          tooltip: l10n.playbackNavQueue,
          isSelected: queueOpen,
          style: queueOpen
              ? IconButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .secondaryContainer,
                  foregroundColor: Theme.of(context)
                      .colorScheme
                      .onSecondaryContainer,
                )
              : null,
          onPressed: () => ref
              .read(rightPanelProvider.notifier)
              .toggle(RightPanelKind.queue),
        ),
        if (full) const VolumeControl(),
        IconButton(
          icon: const Icon(KIcons.openFull),
          tooltip: l10n.playbackExpand,
          onPressed: panel.open,
        ),
      ],
    );
  }
}
