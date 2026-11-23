import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/online/lyrics_candidate.dart';
import 'picker_format.dart';

/// "4:12 khớp · artist · album"; the difference is "khớp" in `primary`, or
/// "+5 s" / "−5 s" in bold `error` with a tooltip saying it may be another
/// version. Parts that are unknown are left out. [lead] words ("LRCLIB",
/// "Đồng bộ") come first, and [showAlbum] false drops the album (the preview
/// page).
class PickerResultDetail extends StatelessWidget {
  const PickerResultDetail({
    super.key,
    required this.candidate,
    required this.songDuration,
    this.lead = const [],
    this.showAlbum = true,
    this.maxLines = 1,
  });

  final LyricsCandidate candidate;
  final Duration? songDuration;
  final List<String> lead;
  final bool showAlbum;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final length = candidate.duration;
    final delta = resultDelta(length, songDuration);
    final segments = <InlineSpan>[
      for (final word in lead) TextSpan(text: word),
      if (length != null)
        TextSpan(
          children: [
            TextSpan(text: formatTrackLength(length)),
            if (delta != null) ...[
              const TextSpan(text: ' '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: PickerDeltaLabel(delta: delta),
              ),
            ],
          ],
        ),
      for (final word in [candidate.artist, if (showAlbum) candidate.album])
        if (word != null && word.trim().isNotEmpty) TextSpan(text: word),
    ];
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const TextSpan(text: ' · '),
            segments[i],
          ],
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// The difference of one result's length against the song's, with its
/// tooltip. Tabular figures so the digits do not jump between rows.
class PickerDeltaLabel extends StatelessWidget {
  const PickerDeltaLabel({super.key, required this.delta});

  final ResultDelta delta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (
      String text,
      String tip,
      Color color,
      FontWeight weight,
    ) = switch (delta.kind) {
      ResultDeltaKind.match => (
        l10n.lyricsPickerDeltaMatch,
        l10n.lyricsPickerDeltaMatchTip,
        scheme.primary,
        FontWeight.w600,
      ),
      ResultDeltaKind.longer => (
        l10n.lyricsPickerDeltaLonger(delta.seconds),
        l10n.lyricsPickerDeltaLongerTip(delta.seconds),
        scheme.error,
        FontWeight.w700,
      ),
      ResultDeltaKind.shorter => (
        l10n.lyricsPickerDeltaShorter(delta.seconds),
        l10n.lyricsPickerDeltaShorterTip(delta.seconds),
        scheme.error,
        FontWeight.w700,
      ),
    };
    return Tooltip(
      message: tip,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: weight,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
