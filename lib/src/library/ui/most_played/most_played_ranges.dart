import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/history/history_ranges.dart';
import '../../state/history/history_providers.dart';
import '../../state/history/most_played_selection.dart';
import '../browse/library_list_scaffold.dart';
import 'most_played_labels.dart';
import 'range_dialog/history_range_dialog.dart';

/// The range chips above the list, one row that scrolls sideways: Hôm nay,
/// 7 ngày, 30 ngày, 6 tháng, 1 năm, Tất cả, Tuỳ chọn…. The chosen one is
/// tinted. Tuỳ chọn… is dim while nothing was ever played (no day to pick) and
/// otherwise opens the range dialog; leaving it with Huỷ keeps the chip that
/// was chosen.
class MostPlayedRangeChips extends ConsumerStatefulWidget {
  const MostPlayedRangeChips({super.key});

  @override
  ConsumerState<MostPlayedRangeChips> createState() =>
      _MostPlayedRangeChipsState();
}

class _MostPlayedRangeChipsState extends ConsumerState<MostPlayedRangeChips> {
  /// Key of the chosen chip, to scroll it into view.
  final _selectedKey = GlobalKey();
  MostPlayedPreset? _shown;

  static const _order = [
    MostPlayedPreset.today,
    MostPlayedPreset.days7,
    MostPlayedPreset.days30,
    MostPlayedPreset.months6,
    MostPlayedPreset.year,
    MostPlayedPreset.all,
    MostPlayedPreset.custom,
  ];

  Future<void> _pickCustom() async {
    final range = ref.read(mostPlayedRangeProvider);
    final start = range.customStart;
    final end = range.customEndInclusive;
    final picked = await showHistoryRangeDialog(
      context,
      initial: start == null || end == null ? null : (start: start, end: end),
    );
    if (picked == null || !mounted) return;
    final notifier = ref.read(mostPlayedRangeProvider.notifier);
    notifier.set(
      ref.read(mostPlayedRangeProvider).withCustom(picked.start, picked.end),
    );
  }

  /// Brings the chosen chip on screen when the choice changed (also on the
  /// first frame: the page may open on "Tuỳ chọn…", off to the right).
  void _revealSelected(MostPlayedPreset preset) {
    if (_shown == preset) return;
    _shown = preset;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _selectedKey.currentContext;
      if (!mounted || chip == null) return;
      final instant = MediaQuery.disableAnimationsOf(context);
      unawaited(
        Scrollable.ensureVisible(
          chip,
          alignment: 0.5,
          duration: instant ? Duration.zero : KMotion.normal,
          curve: KMotion.emphasized,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(mostPlayedRangeProvider);
    // No play at all: nothing to pick a day from. Unknown yet counts as some.
    final noPlays = ref.watch(
      historyBoundsProvider.select((b) => b.hasValue && b.value == null),
    );
    _revealSelected(range.preset);
    final gutter = libraryBarGutter(context);
    return Semantics(
      container: true,
      label: l10n.historyMostPlayedRangesLabel,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.fromSTEB(
          gutter,
          KSpace.x1,
          gutter,
          KSpace.x1,
        ),
        child: Row(
          children: [
            for (final preset in _order) ...[
              KChip(
                key: preset == range.preset ? _selectedKey : null,
                label: Text(mostPlayedPresetLabel(l10n, preset)),
                selected: preset == range.preset,
                enabled: preset != MostPlayedPreset.custom || !noPlays,
                onTap: preset == MostPlayedPreset.custom
                    ? () => unawaited(_pickCustom())
                    : () => ref
                          .read(mostPlayedRangeProvider.notifier)
                          .set(range.withPreset(preset)),
              ),
              const SizedBox(width: KSpace.x2),
            ],
          ],
        ),
      ),
    );
  }
}
