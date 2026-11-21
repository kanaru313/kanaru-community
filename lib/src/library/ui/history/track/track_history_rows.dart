import 'dart:async';

import 'package:flutter/services.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/history/history_models.dart';
import '../../browse/library_list_scaffold.dart' show libraryBarGutter;
import '../history_labels.dart';
import '../history_remove_toast.dart';
import 'track_history_labels.dart';

/// Height of a play's row; the header row above them is the small one.
const double _rowHeight = 48;
const double _headerHeight = 32;

/// Widest figures the two number columns must hold (`00:00`, `0:00:00`).
const String _timeSample = '00:00';
const String _listenedSample = '0:00:00';

/// The plays of one song as a table, newest first: the count line, the
/// header row `Day · Time · Listened`, then one row per play. Rows are 48 dp
/// with the delete button at their end (the only thing a play can do).
Widget trackHistoryRows(List<HistoryPlay> plays, DateTime today) =>
    SliverList.builder(
      // The count line and the header row come before the plays.
      itemCount: plays.length + 2,
      findChildIndexCallback: (key) {
        if (key is! ValueKey<String>) return null;
        final i = plays.indexWhere((p) => p.uid == key.value);
        return i < 0 ? null : i + 2;
      },
      itemBuilder: (context, i) => switch (i) {
        0 => _CountLine(count: plays.length),
        1 => const _HeaderRow(),
        _ => TrackHistoryRow(
          key: ValueKey(plays[i - 2].uid),
          play: plays[i - 2],
          today: today,
        ),
      },
    );

/// `3 plays, newest first`.
class _CountLine extends StatelessWidget {
  const _CountLine({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      alignment: AlignmentDirectional.centerStart,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: libraryBarGutter(context),
      ),
      child: Text(
        AppLocalizations.of(context).historyTrackListHeader(count),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The three column names, drawn on the same grid as the rows.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ExcludeSemantics(
      child: _Grid(
        minHeight: _headerHeight,
        day: _Cell(l10n.historyTrackColDay, style),
        time: _Cell(l10n.historyTrackColTime, style, end: true),
        listened: _Cell(l10n.historyTrackColListened, style, end: true),
        action: const SizedBox.shrink(),
      ),
    );
  }
}

/// One play of the song: its day, the time it began and how long it was
/// listened to, then a button that removes it (the merged Undo toast, as on
/// the History page). The Delete key does the same from the row.
class TrackHistoryRow extends StatelessWidget {
  const TrackHistoryRow({super.key, required this.play, required this.today});

  final HistoryPlay play;

  /// The local day the page is on, which names the day of the play.
  final DateTime today;

  void _remove(BuildContext context) =>
      unawaited(removeHistoryPlay(context, play));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final time = historyClock(l10n, play.playedAt);
    final base = theme.textTheme.bodyMedium;
    final figures = base?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.delete) {
          _remove(context);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      // One label for the row; the delete button keeps its own node.
      child: Semantics(
        container: true,
        label: trackPlayLabel(l10n, play),
        child: _Grid(
          minHeight: _rowHeight,
          border: BorderSide(color: theme.colorScheme.outlineVariant),
          day: ExcludeSemantics(
            child: _Cell(
              trackPlayDay(l10n, play.playedAt, today),
              base?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          time: ExcludeSemantics(child: _Cell(time, figures, end: true)),
          listened: ExcludeSemantics(
            child: _Cell(
              trackPlayListened(play.listenedMs) ?? '',
              figures?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              end: true,
            ),
          ),
          action: KIconButton(
            tooltip: l10n.historyMenuRemovePlay,
            semanticLabel: l10n.historyTrackRemovePlayLabel(
              time,
              historyDate(play.playedAt),
            ),
            icon: KIcons.delete,
            size: KIconSize.sm,
            padding: const EdgeInsets.all(KSpace.x2),
            onPressed: () => _remove(context),
          ),
        ),
      ),
    );
  }
}

/// A text cell that stays on one line.
class _Cell extends StatelessWidget {
  const _Cell(this.text, this.style, {this.end = false});

  final String text;
  final TextStyle? style;
  final bool end;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: style,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    softWrap: false,
    textAlign: end ? TextAlign.end : TextAlign.start,
  );
}

/// The columns of the table: the day takes what the others leave.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.minHeight,
    required this.day,
    required this.time,
    required this.listened,
    required this.action,
    this.border,
  });

  final double minHeight;
  final BorderSide? border;
  final Widget day;
  final Widget time;
  final Widget listened;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final gutter = libraryBarGutter(context);
    final widths = _numberColumns(context);
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: gutter),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: border == null ? null : Border(bottom: border!),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Row(
            children: [
              Expanded(child: day),
              const SizedBox(width: KSpace.x2),
              SizedBox(width: widths.time, child: time),
              const SizedBox(width: KSpace.x2),
              SizedBox(width: widths.listened, child: listened),
              const SizedBox(width: KSpace.x2),
              // Fixed so the header's empty cell lines the columns up.
              SizedBox(width: 40, child: Center(child: action)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widths of the Time and Listened columns, measured with the text scaler in
/// force so a figure or a column name never gets cut: the Day column gives way
/// instead. Rows and header use the same widths, so the columns line up.
({double time, double listened}) _numberColumns(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  final figures = theme.textTheme.bodyMedium?.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  final head = theme.textTheme.labelMedium;
  double widest(List<(String, TextStyle?)> items) {
    var width = 0.0;
    for (final (text, style) in items) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      width = width < painter.width ? painter.width : width;
      painter.dispose();
    }
    // Rounded up: a fraction short of the text would ellipsise it.
    return width.ceilToDouble() + 1;
  }

  return (
    time: widest([(_timeSample, figures), (l10n.historyTrackColTime, head)]),
    listened: widest([
      (_listenedSample, figures),
      (l10n.historyTrackColListened, head),
    ]),
  );
}
