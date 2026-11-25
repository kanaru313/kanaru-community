import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../media/domain/track_info.dart';

/// "Album · artist" and "format · sample rate · bitrate · plays" for the
/// current track.
///
/// Always two lines of one line each at the current text scale, so the card
/// is as high for every song: a missing album and artist keeps an empty first
/// line. While the track's info is still [loading] the same box shows two
/// skeleton lines (hidden from screen readers); when no info comes (the track
/// row is gone, or reading it failed) both lines stay empty.
class TrackInfoCard extends StatelessWidget {
  const TrackInfoCard({super.key, required this.info, this.loading = false});

  /// The track's info; null while loading or when there is none.
  final TrackInfo? info;

  /// The info is still being read. Only drawn while [info] is null.
  final bool loading;

  /// Line height used when the theme's text style has none.
  static const double _fallbackLineHeight = KSkeletonLine.defaultLineHeight;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final scaler = MediaQuery.textScalerOf(context);
    final whoStyle = _withLineHeight(text.bodyMedium);
    final techStyle = _withLineHeight(text.bodySmall)
        .copyWith(color: scheme.onSurfaceVariant);
    final i = info;
    final Widget lines;
    if (i == null && loading) {
      lines = ExcludeSemantics(
        child: _Lines(
          first: KSkeletonLine(
            fontSize: whoStyle.fontSize!,
            lineHeight: whoStyle.height!,
            widthFactor: 0.6,
          ),
          second: KSkeletonLine(
            fontSize: techStyle.fontSize!,
            lineHeight: techStyle.height!,
            widthFactor: 0.4,
          ),
        ),
      );
    } else if (i == null) {
      lines = _Lines(
        first: _line('', whoStyle, scaler),
        second: _line('', techStyle, scaler),
      );
    } else {
      final l10n = AppLocalizations.of(context);
      final who = [?i.album, ?i.artist].join(' · ');
      final tech = [
        ?i.format,
        if (i.sampleRate != null)
          l10n.playbackInfoSampleRate(_khz(i.sampleRate!)),
        if (i.bitrate != null) l10n.playbackInfoBitrate(i.bitrate!),
        l10n.playbackInfoPlays(i.playCount),
      ].join(' · ');
      lines = _Lines(
        first: _line(who, whoStyle, scaler),
        second: _line(tech, techStyle, scaler),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: KRadius.lg,
        ),
        child: Padding(padding: const EdgeInsets.all(KSpace.x4), child: lines),
      ),
    );
  }

  /// [style] with an explicit font size and line height, so the line box
  /// below and the text drawn in it agree.
  static TextStyle _withLineHeight(TextStyle? style) {
    final base = style ?? const TextStyle();
    return base.copyWith(
      fontSize: base.fontSize ?? 14,
      height: base.height ?? _fallbackLineHeight,
    );
  }

  /// [value] on one line, ellipsized, in a box exactly one line of [style]
  /// high (the same box as a [KSkeletonLine] of that style).
  static Widget _line(String value, TextStyle style, TextScaler scaler) =>
      SizedBox(
        height: KSkeletonLine.extentOf(
          scaler,
          style.fontSize!,
          lineHeight: style.height!,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      );

  /// 44100 -> "44.1", 48000 -> "48".
  static String _khz(int hz) {
    final k = hz / 1000;
    return k == k.roundToDouble() ? '${k.round()}' : k.toStringAsFixed(1);
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: KSpace.x1,
    children: [first, second],
  );
}
