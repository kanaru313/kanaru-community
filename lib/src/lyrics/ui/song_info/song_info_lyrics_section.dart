import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/lyrics.dart';
import '../../domain/lyrics_facts.dart';
import '../../domain/lyrics_status.dart';
import '../../state/stored_track_lyrics_provider.dart';
import '../../state/track_lyrics_providers.dart';
import '../../../library/state/info/song_details_providers.dart'
    show songInfoShowEmptyProvider;
import '../online/online_source_providers.dart';
import 'full_lyrics_data.dart';
import 'full_lyrics_page.dart';
import 'lyrics_preview_block.dart';
import 'lyrics_section_skeleton.dart';
import 'song_info_lyrics_labels.dart';

/// The "Lời bài hát" group of the song info page, drawn after Tags. It shows
/// what the track already has (`storedTrackLyricsProvider`: never a plugin or
/// a network request): the source row and a preview that opens the full
/// lyrics. A track whose file cannot be read (missing, remote) draws nothing,
/// or one "Không đọc được lời" row when the page shows empty fields.
class SongInfoLyricsSection extends ConsumerWidget {
  const SongInfoLyricsSection({super.key, required this.trackId});

  final int trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = TrackId(trackId);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(storedTrackLyricsProvider(id));
    // A file that cannot be read has no lyrics to show: the group appears
    // only with the info page's "empty fields" eye on.
    if (state is LyricsUnavailable && !ref.watch(songInfoShowEmptyProvider)) {
      return const SizedBox.shrink();
    }
    final facts = ref.watch(lyricsFactsProvider(id)).value;
    final rows = switch (state) {
      LyricsLoading() => [const LyricsSectionSkeleton()],
      LyricsShown(:final lyrics) => _withPreview(
        context,
        lyrics,
        facts,
        _source(l10n, ref, lyrics, facts),
      ),
      LyricsOff(:final available) => [
        _sourceRow(context, l10n.lyricsLabelOff),
        if (available != null)
          _preview(
            context,
            available,
            facts,
            _source(l10n, ref, available, facts),
          ),
      ],
      final LyricsInstrumental instrumental => [
        _sourceRow(
          context,
          lyricsInfoInstrumentalLabel(
            l10n,
            instrumental,
            removed: ref.watch(
              onlineSourceRemovedProvider(instrumental.ref.providerId),
            ),
          ),
        ),
      ],
      LyricsUnavailable() => [
        KInfoRow(
          label: l10n.lyricsInfoSourceRow,
          unknownText: l10n.lyricsInfoUnreadable,
        ),
      ],
      LyricsNone() ||
      LyricsSearching() ||
      LyricsNotFound() ||
      LyricsNoSource() ||
      LyricsLookupFailed() ||
      LyricsLookupPaused() => [_Empty(l10n: l10n)],
    };
    return KInfoGroup(
      title: l10n.lyricsInfoGroup,
      icon: KIcons.lyrics,
      children: rows,
    );
  }

  List<Widget> _withPreview(
    BuildContext context,
    Lyrics lyrics,
    LyricsFacts? facts,
    String source,
  ) => [
    _sourceRow(
      context,
      source,
      copy: lyrics.origin == LyricsOrigin.lrc ? _lrcName(facts) : null,
    ),
    _preview(context, lyrics, facts, source),
  ];

  Widget _preview(
    BuildContext context,
    Lyrics lyrics,
    LyricsFacts? facts,
    String source,
  ) => LyricsPreviewBlock(
    lyrics: lyrics,
    onOpen: () => showFullLyrics(
      context,
      FullLyricsData(
        lyrics: lyrics,
        songTitle: facts?.title ?? '',
        song: [
          facts?.title,
          facts?.artist,
        ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
        source: lyricsInfoStripSource(AppLocalizations.of(context), lyrics),
      ),
    ),
  );

  /// Only the `.lrc` file name can be copied ([copy]); the other sources are
  /// plain text, which `KInfoRow` does not offer to copy.
  Widget _sourceRow(BuildContext context, String value, {String? copy}) {
    final l10n = AppLocalizations.of(context);
    if (copy == null) {
      final style = Theme.of(context).textTheme.bodyMedium
          ?.copyWith(fontWeight: FontWeight.w500);
      return KInfoRow(
        label: l10n.lyricsInfoSourceRow,
        valueWidget: Semantics(
          label: '${l10n.lyricsInfoSourceRow}: $value',
          excludeSemantics: true,
          child: Text(value, style: style),
        ),
      );
    }
    return KInfoRow(
      label: l10n.lyricsInfoSourceRow,
      value: value,
      copyText: copy,
      onCopied: (text) =>
          showAppSnackBar(context, l10n.libraryInfoCopied(text)),
    );
  }

  String _source(
    AppLocalizations l10n,
    WidgetRef ref,
    Lyrics lyrics,
    LyricsFacts? facts,
  ) => lyricsInfoSourceLabel(
    l10n,
    lyrics,
    lrcName: _lrcName(facts),
    removed:
        lyrics.online != null &&
        ref.watch(onlineSourceRemovedProvider(lyrics.online!.providerId)),
  );

  static String? _lrcName(LyricsFacts? facts) {
    final locator = facts?.lrcLocator;
    if (locator == null || locator.isEmpty) return null;
    return locator.substring(locator.lastIndexOf('/') + 1);
  }
}

/// "Chưa có lời" and where to add some. No search button: opening the info
/// never looks anything up.
class _Empty extends StatelessWidget {
  const _Empty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KSpace.x4,
        vertical: KSpace.x3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.lyricsInfoNone, style: theme.textTheme.bodyMedium),
          Text(
            l10n.lyricsInfoNoneHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
