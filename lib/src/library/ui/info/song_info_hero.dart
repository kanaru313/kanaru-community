import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/cover_files.dart';
import '../../../media/domain/track_info.dart';
import '../../../playback/ui/track_cover.dart';
import '../../domain/info/song_details.dart';
import '../../state/info/song_details_providers.dart';
import 'song_info_formats.dart';

/// Cover, name, `artist · album` and the quality chips (format, bit depth ·
/// rate, length). Reads [info] (known the moment the page opens) until
/// [details] arrive, so the head does not jump while loading.
class SongInfoHero extends StatelessWidget {
  const SongInfoHero({super.key, required this.info, this.details});

  final TrackInfo info;
  final SongDetails? details;

  /// 104 on a page and on a tablet box, 112 in the desktop box.
  static double sideOf(BuildContext context) {
    final box = KOverlayPageScope.maybeKindOf(context) == KOverlayKind.box;
    return box && FormFactor.of(context) == FormFactor.desktop ? 112 : 104;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final d = details;
    final side = sideOf(context);
    final artists = d == null
        ? info.artist
        : d.artists.map((a) => a.name).join(', ');
    final line = [
      if (artists != null && artists.isNotEmpty)
        artists
      else
        l10n.libraryInfoUnknownArtist,
      d?.album ?? info.album,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    final chips = d == null ? const <String>[] : _chips(d, l10n);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: TrackCover(
            coverKey: d?.coverKey ?? info.coverKey,
            seed: d?.coverSeed ?? info.coverSeed,
            size: CoverSize.thumb,
            dimension: side,
            radius: BorderRadius.circular(16),
          ),
        ),
        const KGap(KSpace.x4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  d?.title ?? info.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                line,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (chips.isNotEmpty) ...[
                const KGap(KSpace.x2),
                Wrap(
                  spacing: KSpace.x2,
                  runSpacing: KSpace.x1,
                  children: [for (final c in chips) KChip.tag(label: Text(c))],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static List<String> _chips(SongDetails d, AppLocalizations l10n) {
    final quality = [
      if (d.bitDepth != null) l10n.libraryInfoBitDepthValue(d.bitDepth!),
      if (d.sampleRate != null)
        l10n.libraryInfoSampleRateValue(
          formatKhz(d.sampleRate!, l10n.localeName),
        ),
    ].join(' · ');
    final duration = d.durationMs;
    return [
      if (d.format != null) d.format!,
      if (quality.isNotEmpty) quality,
      if (duration != null) formatInfoDuration(duration),
    ];
  }
}

/// The fixed head of the info box: [SongInfoHero] fed by the live details.
class SongInfoBoxHeader extends ConsumerWidget {
  const SongInfoBoxHeader({super.key, required this.info});

  final TrackInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SongInfoHero(
    info: info,
    details: ref.watch(songDetailsProvider(info.id)).value,
  );
}
