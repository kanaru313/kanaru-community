import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_models.dart';
import '../../state/history/history_providers.dart';
import '../../state/history/history_year_selection.dart';
import 'history_bar.dart';
import 'history_calendar_dialog.dart';
import 'history_filter.dart';
import 'history_hero.dart';
import 'history_notice.dart';
import 'history_page_frame.dart';
import 'history_year_timeline.dart';
import 'history_timeline_controller.dart';
import 'history_timeline_scroll.dart';

/// The History page once there are plays: the hero, the bar with its jump
/// and filter, and the timeline or, while a query is typed, the matches.
class HistoryContent extends ConsumerStatefulWidget {
  const HistoryContent({
    super.key,
    required this.years,
    required this.overview,
  });

  /// Years with plays, newest first; never empty.
  final List<int> years;
  final HistoryOverview overview;

  @override
  ConsumerState<HistoryContent> createState() => HistoryContentState();
}

class HistoryContentState extends ConsumerState<HistoryContent> {
  final _timeline = HistoryTimelineController();
  final _query = TextEditingController();

  /// Anchors the bar, which sits in the page's scroll view: gives access to
  /// that view's scroll position from outside it.
  final _barKey = GlobalKey();

  bool _filterOpen = false;

  /// What the list is filtered by (trimmed); empty = the timeline shows.
  String _applied = '';

  /// The reader's place when the filter started showing results (the play
  /// under the bar, else the page offset), and what the timeline that comes
  /// back is put back by (taken once).
  HistoryAnchor? _savedAnchor;
  double? _savedPixels;
  HistoryRestore? _restore;

  /// A change of a non-empty query waits for typing to pause.
  Timer? _typing;

  @override
  void dispose() {
    _typing?.cancel();
    _query.dispose();
    super.dispose();
  }

  ScrollPosition? get _position {
    final bar = _barKey.currentContext;
    return bar == null ? null : Scrollable.maybeOf(bar)?.position;
  }

  /// Entering and leaving the filter apply at once; a change of the query
  /// in between waits 180 ms for the next key.
  void _onQuery(String text) {
    final next = text.trim();
    _typing?.cancel();
    if (next == _applied) return;
    if (_applied.isEmpty || next.isEmpty) {
      _apply(next);
    } else {
      _typing = Timer(const Duration(milliseconds: 180), () {
        if (mounted) _apply(next);
      });
    }
  }

  void _apply(String next) {
    if (next == _applied) return;
    final entering = _applied.isEmpty;
    final leaving = next.isEmpty;
    if (entering) {
      _savedAnchor = _timeline.captureAnchor();
      _savedPixels = _position?.pixels;
    }
    setState(() {
      if (entering) {
        _restore = null;
      } else if (leaving) {
        _restore = HistoryRestore(anchor: _savedAnchor, pixels: _savedPixels);
        _savedAnchor = null;
        _savedPixels = null;
      }
      _applied = next;
    });
    if (entering) scrollHistoryBarIntoView(_barKey);
  }

  void _toggleFilter() {
    if (_filterOpen) {
      _query.clear();
      _onQuery('');
    }
    setState(() => _filterOpen = !_filterOpen);
  }

  void _yearChanged() {
    _typing?.cancel();
    _query.clear();
    setState(() {
      _applied = '';
      _savedAnchor = null;
      _savedPixels = null;
      _restore = null;
    });
  }

  Future<void> _jump(int year, List<HistoryPlay> plays) async {
    final picked = await pickHistoryDay(context, year, plays);
    if (picked != null && mounted) _timeline.jumpToDay(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final years = widget.years;
    final shown = ref.watch(historyShownYearProvider) ?? years.first;
    // Switching year starts a new list: the filter text goes.
    ref.listen(historyShownYearProvider, (prev, next) {
      if (prev != next) _yearChanged();
    });
    final plays = ref.watch(historyYearProvider(shown));
    // The hero's cover is the newest year's, whichever year is shown.
    final newest = shown == years.first
        ? plays
        : ref.watch(historyYearProvider(years.first));
    final older = years.where((y) => y < shown).firstOrNull;
    final list = plays.value;
    return HistoryPageFrame.layout(
      title: l10n.historyTitle,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HistoryRecordingNotice(),
          HistoryHero(overview: widget.overview, plays: newest.value),
        ],
      ),
      slivers: [
        SliverToBoxAdapter(
          child: HistoryBar(
            key: _barKey,
            years: years,
            year: shown,
            plays: list?.length,
            onYear: (y) =>
                ref.read(historySelectedYearProvider.notifier).select(y),
            // The jump goes to a day bar: the filter's flat list has none.
            onJump: list == null || _applied.isNotEmpty
                ? null
                : () => unawaited(_jump(shown, list)),
            onFilter: _toggleFilter,
            filterOpen: _filterOpen,
            filterField: KFilterField(
              controller: _query,
              hint: l10n.historyFilterHint('$shown'),
              onChanged: _onQuery,
              onClose: () => setState(() => _filterOpen = false),
            ),
          ),
        ),
        if (_applied.isNotEmpty)
          HistoryFilterList(year: shown, query: _applied)
        else
          historyYearTimeline(
            context,
            ref,
            plays,
            shown,
            older,
            controller: _timeline,
            restore: _restore,
          ),
      ],
    );
  }
}
