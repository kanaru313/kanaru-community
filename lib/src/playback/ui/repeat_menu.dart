import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart' hide RepeatMode;

import '../../../l10n/gen/app_localizations.dart';
import '../domain/repeat_mode.dart';

/// The icon glyph of a repeat mode.
KRepeatGlyph repeatGlyph(RepeatMode mode) => switch (mode) {
  RepeatMode.off => KRepeatGlyph.off,
  RepeatMode.one => KRepeatGlyph.one,
  RepeatMode.all => KRepeatGlyph.all,
  RepeatMode.allShuffled => KRepeatGlyph.allShuffled,
};

/// Text of a repeat mode, for the menu rows and the button tooltip. While a
/// counted repeat runs ([times] above 0) it stands for the mode.
String repeatLabel(AppLocalizations l10n, RepeatMode mode, int times) {
  if (times > 0) return l10n.playbackRepeatTimes(times);
  return switch (mode) {
    RepeatMode.off => l10n.playbackRepeatOff,
    RepeatMode.one => l10n.playbackRepeatOne,
    RepeatMode.all => l10n.playbackRepeatAll,
    RepeatMode.allShuffled => l10n.playbackRepeatAllShuffled,
  };
}

/// The rows of the repeat menu, in this order: stop at the end, repeat this
/// song, repeat it N more times (with a minus and a plus), repeat the queue,
/// repeat it reshuffled every pass. Rows are [SelectionRow]s: value left,
/// primary check right, tonal fill when selected.
///
/// [mode] and [times] are the player's; [draft] is the number the counted row
/// arms with while no count runs. [stopped] dims the counted row and its
/// stepper: a count armed while stopped would be dropped at once.
class RepeatMenuRows extends StatelessWidget {
  const RepeatMenuRows({
    super.key,
    required this.mode,
    required this.times,
    required this.stopped,
    required this.draft,
    required this.onMode,
    required this.onCount,
    required this.onStep,
  });

  /// Space between two rows, so the tonal fills of neighbours do not touch.
  static const _gap = 2.0;
  static const _maxWidth = 340.0;

  final RepeatMode mode;
  final int times;
  final bool stopped;
  final int draft;

  /// A mode row was chosen.
  final ValueChanged<RepeatMode> onMode;

  /// The counted row was chosen, with the number it shows.
  final ValueChanged<int> onCount;

  /// The minus or plus was pressed, with the new number.
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final counting = times > 0;
    final shown = counting ? times : draft;

    Widget modeRow(RepeatMode m) => SelectionRow(
      leading: KRepeatIcon(glyph: repeatGlyph(m), size: 24, menu: true),
      title: Text(repeatLabel(l10n, m, 0)),
      selected: !counting && mode == m,
      onTap: () => onMode(m),
    );

    final countedRow = SelectionRow(
      leading: KRepeatIcon(glyph: KRepeatGlyph.counted, count: shown, size: 24),
      title: Row(
        children: [
          Expanded(child: Text(repeatLabel(l10n, mode, shown))),
          KCountStepper(
            value: shown,
            max: maxRepeatTimes,
            enabled: !stopped,
            color: counting ? scheme.onSecondaryContainer : null,
            decreaseTooltip: l10n.playbackRepeatFewer,
            increaseTooltip: l10n.playbackRepeatMore,
            onChanged: onStep,
          ),
        ],
      ),
      selected: counting,
      enabled: !stopped,
      onTap: () => onCount(shown),
    );

    return KMenuWidth(
      maxWidth: _maxWidth,
      child: Padding(
        padding: const EdgeInsets.all(KSpace.x2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            modeRow(RepeatMode.off),
            const SizedBox(height: _gap),
            modeRow(RepeatMode.one),
            const SizedBox(height: _gap),
            countedRow,
            const SizedBox(height: _gap),
            modeRow(RepeatMode.all),
            const SizedBox(height: _gap),
            modeRow(RepeatMode.allShuffled),
          ],
        ),
      ),
    );
  }
}
