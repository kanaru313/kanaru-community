import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../media/domain/track_info.dart';

/// "Album · artist" and "format · sample rate · bitrate · plays" for the
/// current track.
class TrackInfoCard extends StatelessWidget {
  const TrackInfoCard({super.key, required this.info});

  final TrackInfo? info;

  @override
  Widget build(BuildContext context) {
    final i = info;
    if (i == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final who = [
      if (i.album != null) i.album!,
      if (i.artist != null) i.artist!,
    ].join(' · ');
    final tech = [
      ?i.format,
      if (i.sampleRate != null)
        l10n.playbackInfoSampleRate(_khz(i.sampleRate!)),
      if (i.bitrate != null) l10n.playbackInfoBitrate(i.bitrate!),
      l10n.playbackInfoPlays(i.playCount),
    ].join(' · ');
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: KRadius.lg,
        ),
        child: Padding(
          padding: const EdgeInsets.all(KSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: KSpace.x1,
            children: [
              if (who.isNotEmpty) Text(who, style: text.bodyMedium),
              Text(
                tech,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 44100 -> "44.1", 48000 -> "48".
  static String _khz(int hz) {
    final k = hz / 1000;
    return k == k.roundToDouble() ? '${k.round()}' : k.toStringAsFixed(1);
  }
}
