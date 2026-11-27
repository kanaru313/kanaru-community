import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/state/browse/song_list_providers.dart'
    show trackRowLoaderProvider;
import '../../../media/domain/cover_files.dart';
import '../../../media/domain/track_id.dart';
import '../../../media/domain/track_info.dart';
import '../../../playback/ui/track_cover.dart';
import '../../domain/conversation/track_ref_snapshot.dart';
import '../chat_row_extent.dart';
import '../markdown/chat_markdown_model.dart' show chatListMaxRows;

final _log = Logger('ai.track_rows_preview');

/// A list of up to this many songs shows all of them; a longer one shows the
/// first [_shortRows] and a "+N bài" button.
const int _showAllUpTo = 6;
const int _shortRows = 5;

/// Left edge of the card's text (round icon plus gap) on the desktop shell;
/// the phone lists use the whole card width.
double _textIndent(BuildContext context) =>
    FormFactor.of(context) == FormFactor.desktop ? KIconSize.lg + KSpace.x3 : 0;

double _buttonHeight(BuildContext context) =>
    FormFactor.of(context) == FormFactor.desktop ? KSpace.x7 : KSpace.x8;

/// The songs of a card as compact rows (cover 40, title, artist): the whole
/// list up to six songs, else five and "+N bài" that opens the rest. Rows
/// only show; nothing in them is tappable. Once every song shows, a list of
/// more than eight rows sits in a box eight rows tall with its own scroll
/// (rows built as they come into view).
class TrackRowsPreview extends ConsumerStatefulWidget {
  const TrackRowsPreview({
    super.key,
    required this.tracks,
    this.indent = true,
    this.showAll = false,
  });

  final List<TrackRefSnapshot> tracks;

  /// Show every song at once, without the "+N bài" button (a result list).
  final bool showAll;

  /// Line the list up with the card's text on the desktop shell.
  final bool indent;

  @override
  ConsumerState<TrackRowsPreview> createState() => _TrackRowsPreviewState();
}

class _TrackRowsPreviewState extends ConsumerState<TrackRowsPreview> {
  bool _all = false;

  /// Library rows of the songs shown, read in one query per batch (a card
  /// never keeps a live watch per row). Ids already read are not read again.
  final Map<int, TrackInfo> _infos = {};
  final Set<int> _asked = {};

  /// Ids whose read finished: only these can be "gone" (no row). A read
  /// that failed leaves its ids unknown and is tried again on the next load.
  final Set<int> _read = {};

  bool get _whole =>
      widget.showAll || _all || widget.tracks.length <= _showAllUpTo;

  int get _shownCount => _whole ? widget.tracks.length : _shortRows;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TrackRowsPreview old) {
    super.didUpdateWidget(old);
    _load();
  }

  /// Songs read per query when a long list shows whole.
  static const int _batch = 200;

  Future<void> _load() async {
    final ids = [
      for (final t in widget.tracks.take(_shownCount))
        // A row without a song (a gone queue entry) has no id to read.
        if (t.trackId > 0 && _asked.add(t.trackId)) TrackId(t.trackId),
    ];
    if (ids.isEmpty) return;
    // Captured before the await: the card may be gone when it returns.
    final loader = ref.read(trackRowLoaderProvider);
    for (var i = 0; i < ids.length; i += _batch) {
      final chunk = ids.sublist(i, math.min(i + _batch, ids.length));
      try {
        final rows = await loader(chunk);
        if (!mounted) return;
        setState(() {
          for (final r in rows) {
            _infos[r.id.value] = r;
          }
          _read.addAll(chunk.map((i) => i.value));
        });
      } on Object catch (e, s) {
        // Rows keep the text the engine stored; only covers are missing. The
        // ids stay unknown (not "gone") and are asked again on the next load.
        _log.warning('reading the card songs failed: ${e.runtimeType}', e, s);
        _asked.removeAll(chunk.map((i) => i.value));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tracks = widget.tracks;
    final shown = _shownCount;
    final rest = tracks.length - shown;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: KSpace.x2 + 2,
        start: widget.indent ? _textIndent(context) : 0,
      ),
      child: Semantics(
        container: true,
        label: l10n.aiChatCardTrackList(tracks.length),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KCappedList(
              itemCount: shown,
              maxVisible: chatListMaxRows,
              gap: chatListGap,
              rowExtent: chatSongRowExtent(
                context,
                cover: KIconSize.xl,
                vertical: KSpace.x1,
              ),
              itemBuilder: (context, i) => _SongLine(
                track: tracks[i],
                info: _infos[tracks[i].trackId],
                loaded: _read.contains(tracks[i].trackId),
              ),
            ),
            if (rest > 0)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () {
                    setState(() => _all = true);
                    _load();
                  },
                  style: TextButton.styleFrom(
                    minimumSize: Size(0, _buttonHeight(context)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l10n.aiChatCardMoreTracks(rest)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A folded song list: one line "N bài đã thêm ▾" that opens
/// [TrackRowsPreview] under it.
class TrackListFold extends StatefulWidget {
  const TrackListFold({super.key, required this.label, required this.tracks});

  final String label;
  final List<TrackRefSnapshot> tracks;

  @override
  State<TrackListFold> createState() => _TrackListFoldState();
}

class _TrackListFoldState extends State<TrackListFold> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final instant = MediaQuery.disableAnimationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            top: KSpace.x2,
            // Never negative: on the phone the label starts at the card edge.
            start: math.max(0, _textIndent(context) - KSpace.x2),
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(
              button: true,
              expanded: _open,
              excludeSemantics: true,
              label: widget.label,
              onTap: () => setState(() => _open = !_open),
              child: TextButton(
                onPressed: () => setState(() => _open = !_open),
                style: TextButton.styleFrom(
                  minimumSize: Size(0, _buttonHeight(context)),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  // The label lines up with the card text: the tap shape's inset
                  // only exists where the row is indented.
                  padding: EdgeInsetsDirectional.only(
                    start: _textIndent(context) > 0 ? KSpace.x2 : 0,
                    end: KSpace.x2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.label),
                    const SizedBox(width: KSpace.x1 / 2),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: instant ? Duration.zero : KMotion.fast,
                      child: Icon(
                        KIcons.collapse,
                        size: KIconSize.sm,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_open) TrackRowsPreview(tracks: widget.tracks),
      ],
    );
  }
}

/// One song: its cover, title and artist. The text is what the engine
/// stored (what the call listed or changed); the cover comes from the library
/// while the song is still there. A song stored by id only (a replaced queue)
/// takes its text from the library too.
class _SongLine extends StatelessWidget {
  const _SongLine({
    required this.track,
    required this.info,
    required this.loaded,
  });

  final TrackRefSnapshot track;

  /// The song's library row; null while it loads or when it left the library.
  final TrackInfo? info;

  /// Whether this song's library read finished (no row is then "gone").
  final bool loaded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final stored = track.title.isNotEmpty;
    final title = stored
        ? track.title
        : (info?.title ?? (loaded ? l10n.aiChatCardTrackGone : ''));
    final artist = stored ? track.artist : (info?.artist ?? '');
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KSpace.x1 + 2,
        vertical: KSpace.x1,
      ),
      child: Row(
        children: [
          TrackCover(
            coverKey: info?.coverKey,
            seed: info?.coverSeed ?? '${track.trackId}',
            size: CoverSize.thumb,
            dimension: KIconSize.xl,
            radius: KRadius.xs,
          ),
          const SizedBox(width: KSpace.x3 - 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (artist.isNotEmpty)
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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
