import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../media/domain/track_id.dart';
import '../../domain/online/lyrics_candidate.dart';
import '../../domain/online/online_search_state.dart';
import '../../state/online/online_search_provider.dart';
import 'picker_lyrics_text.dart';
import 'picker_source_notes.dart';

/// The lyrics of one result, fetched on demand: its own when the search
/// answered with them, else a `lyrics` run of its plugin (loading, failed and
/// "no lyrics" show instead of the text). The fetch starts when the result
/// first shows and again when another result takes its place; its state lives
/// in the search, so it survives this widget.
class PickerPreview extends ConsumerStatefulWidget {
  const PickerPreview({
    super.key,
    required this.trackId,
    required this.candidate,
    required this.compact,
    this.plainNote = false,
    this.padding = EdgeInsets.zero,
  });

  final TrackId trackId;
  final LyricsCandidate candidate;
  final bool compact;
  final bool plainNote;
  final EdgeInsetsGeometry padding;

  @override
  ConsumerState<PickerPreview> createState() => _PickerPreviewState();
}

class _PickerPreviewState extends ConsumerState<PickerPreview> {
  @override
  void initState() {
    super.initState();
    _ensure();
  }

  @override
  void didUpdateWidget(PickerPreview old) {
    super.didUpdateWidget(old);
    if (old.candidate.ref != widget.candidate.ref) _ensure();
  }

  /// Starts the fetch after this frame: it writes provider state, which must
  /// not happen while the tree builds.
  void _ensure() {
    final candidate = widget.candidate;
    if (candidate.body?.isUsable ?? false) return;
    final notifier = ref.read(onlineSearchProvider(widget.trackId).notifier);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(notifier.fetchLyrics(candidate));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final candidate = widget.candidate;
    final body = candidate.body;
    if (body != null && body.hasLyrics) {
      return PickerLyricsText(
        body: body,
        compact: widget.compact,
        plainNote: widget.plainNote,
        padding: widget.padding,
      );
    }
    if (body != null && body.instrumental) {
      return _Note(
        icon: KIcons.lyricsNote,
        message: l10n.lyricsPickerPreviewInstrumental,
        padding: widget.padding,
      );
    }
    final fetch = ref.watch(
      onlineSearchProvider(widget.trackId)
          .select((s) => s.bodyFetches[candidate.ref]),
    );
    return switch (fetch?.phase) {
      BodyFetchPhase.failed => _Note(
        icon: KIcons.offline,
        message: l10n.lyricsPickerPreviewFailed,
        padding: widget.padding,
        error: true,
      ),
      BodyFetchPhase.missing => _Note(
        icon: KIcons.lyricsNote,
        message: l10n.lyricsPickerPreviewMissing,
        padding: widget.padding,
      ),
      _ => Padding(
        padding: widget.padding,
        child: Align(
          alignment: Alignment.topCenter,
          child: PickerLoadingNote(label: l10n.lyricsPickerPreviewLoading),
        ),
      ),
    };
  }
}

class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.message,
    required this.padding,
    this.error = false,
  });

  final IconData icon;
  final String message;
  final EdgeInsetsGeometry padding;
  final bool error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Align(
      alignment: Alignment.topCenter,
      child: KInlineNotice(
        icon: icon,
        message: message,
        tone: error ? KInlineNoticeTone.error : KInlineNoticeTone.normal,
      ),
    ),
  );
}
