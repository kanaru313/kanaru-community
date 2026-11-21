import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../media/domain/cover_files.dart';
import '../../../../playback/state/playback_providers.dart';
import '../../../../playback/state/track_info_providers.dart';
import '../../../../playback/ui/track_cover.dart';
import '../favorite_button.dart';
import 'now_playing_header.dart'
    show nowPlayingHeaderHeight, nowPlayingHeaderTallHeight;

/// Header of the lyrics screen: `[⌄] · cover 40 · title / artist · [source]
/// [Dịch] · [♥]`. [sourceButton] is the lyrics source button (null leaves its
/// place empty); the translate button is dimmed and inert until translation
/// exists.
class LyricsScreenHeader extends ConsumerWidget {
  const LyricsScreenHeader({
    super.key,
    required this.onClose,
    this.sourceButton,
  });

  final VoidCallback onClose;
  final Widget? sourceButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final id = ref.watch(nowPlayingProvider.select((n) => n.value?.trackId));
    final info = id == null ? null : ref.watch(trackInfoProvider(id)).value;
    final tall = MediaQuery.textScalerOf(context).scale(1) >= 2;
    return SizedBox(
      height: tall ? nowPlayingHeaderTallHeight : nowPlayingHeaderHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: KSpace.x1),
        child: Row(
          spacing: KSpace.x3,
          children: [
            KIconButton(
              icon: KIcons.collapse,
              tooltip: l10n.playbackMinimize,
              onPressed: onClose,
            ),
            TrackCover(
              coverKey: info?.coverKey,
              seed: info?.coverSeed ?? '',
              size: CoverSize.thumb,
              dimension: KSpace.x8,
              radius: KRadius.xs,
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info?.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
            ?sourceButton,
            KIconButton(
              icon: KIcons.languages,
              tooltip: l10n.lyricsTranslateSoon,
              onPressed: null,
            ),
            if (id != null) FavoriteButton(trackId: id),
          ],
        ),
      ),
    );
  }
}
