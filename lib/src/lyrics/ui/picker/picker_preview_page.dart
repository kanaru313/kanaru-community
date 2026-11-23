import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/online/lyrics_candidate.dart';
import '../../domain/online/online_search_state.dart';
import '../online/plugin_avatar.dart';
import 'picker_actions.dart';
import 'picker_view.dart';
import 'picker_header.dart';
import 'picker_preview.dart';
import 'picker_result_detail.dart';

/// Opens "Xem trước" over the list (touch shells): a full-height sheet. It
/// completes with the result chosen by [Dùng lời này], or null when the user
/// went back (← , Back, a drag down or ✕ of the sheet).
Future<PickedLyrics?> showPickerPreviewPage(
  BuildContext context, {
  required TrackId trackId,
  required ResultRef ref,
  required LyricsCandidate fallback,
  required String sourceName,
  required Duration? songDuration,
}) => showKSheet<PickedLyrics>(
  context,
  useRootNavigator: true,
  fixedHeight: true,
  maxHeightFraction: 1,
  builder: (_) => PickerPreviewPage(
    trackId: trackId,
    resultRef: ref,
    fallback: fallback,
    sourceName: sourceName,
    songDuration: songDuration,
  ),
);

/// The preview page: ← "Xem trước" ✕, the result's picture, title and the
/// line "LRCLIB · Đồng bộ · artist · 4:12 khớp", the whole lyrics, and at the
/// foot "Chỉ áp dụng cho bài này" over a full-width [Dùng lời này] that is on
/// once the lyrics are there.
class PickerPreviewPage extends ConsumerWidget {
  const PickerPreviewPage({
    super.key,
    required this.trackId,
    required this.resultRef,
    required this.fallback,
    required this.sourceName,
    required this.songDuration,
  });

  final TrackId trackId;
  final ResultRef resultRef;

  /// The result as the list had it; used while the search no longer has it.
  final LyricsCandidate fallback;
  final String sourceName;
  final Duration? songDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final candidate =
        ref.watch(
          pickerViewProvider(trackId)
              .select((v) => v.find(resultRef)?.match.candidate),
        ) ??
        fallback;
    final usable = candidate.body?.isUsable ?? false;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PickerHeader(
          title: l10n.lyricsPickerPreview,
          backTooltip: l10n.lyricsPickerPreviewBackLabel,
          onBack: () => Navigator.of(context).pop(),
          onClose: () => Navigator.of(context).pop(),
        ),
        _Source(
          candidate: candidate,
          sourceName: sourceName,
          songDuration: songDuration,
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Expanded(
          child: PickerPreview(
            key: ValueKey(candidate.ref),
            trackId: trackId,
            candidate: candidate,
            compact: false,
            plainNote: true,
            padding: const EdgeInsets.fromLTRB(
              KSpace.x6,
              KSpace.x3,
              KSpace.x6,
              KSpace.x4,
            ),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x4,
            KSpace.x3,
            KSpace.x4,
            KSpace.x4,
          ),
          child: Column(
            spacing: KSpace.x2,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.lyricsPickerFootNote,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              KModalButton(
                label: l10n.lyricsPickerUse,
                onPressed: usable
                    ? () => Navigator.of(context)
                          .pop((candidate: candidate, providerName: sourceName))
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Source extends StatelessWidget {
  const _Source({
    required this.candidate,
    required this.sourceName,
    required this.songDuration,
  });

  final LyricsCandidate candidate;
  final String sourceName;
  final Duration? songDuration;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final body = candidate.body;
    final kind = body == null
        ? null
        : body.syncedLrc != null
        ? l10n.lyricsKindSynced
        : l10n.lyricsKindPlain;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KSpace.x6,
        KSpace.x2,
        KSpace.x6,
        KSpace.x3,
      ),
      child: Row(
        spacing: KSpace.x4,
        children: [
          PluginAvatar(
            providerId: candidate.providerId,
            name: sourceName,
            size: KIconSize.md,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Two lines at most: the page's fixed parts must leave room
                // for the lyrics at large text on a short phone.
                Text(
                  candidate.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                DefaultTextStyle.merge(
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  child: PickerResultDetail(
                    candidate: candidate,
                    songDuration: songDuration,
                    lead: [sourceName, ?kind],
                    showAlbum: false,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
