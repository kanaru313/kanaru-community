import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/conversation/parts.dart';
import '../../state/chat_attachments.dart';
import 'chip_labels.dart';

/// The context chips of the message being written: the attached ones (with a
/// ×; struck when their tool group is off) and the suggestions the user may
/// attach with a tap.
class ContextChips extends ConsumerWidget {
  const ContextChips({super.key, required this.struck});

  /// Attached chips that cannot be sent.
  final List<ChipPart> struck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chips = ref.watch(chatAttachmentsProvider);
    final notifier = ref.read(chatAttachmentsProvider.notifier);
    final suggested = [
      for (final s in chips.suggestions)
        if (!chips.attached.any((a) => sameChip(a, s))) s,
    ];
    if (chips.attached.isEmpty && suggested.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: KSpace.x2,
      runSpacing: KSpace.x2,
      children: [
        for (final chip in chips.attached)
          KContextChip(
            label: chipLabel(l10n, chip),
            icon: chipIcon(chip.kind),
            state: struck.any((s) => sameChip(s, chip))
                ? KContextChipState.struck
                : KContextChipState.attached,
            // The body of an attached chip does nothing; the × removes it.
            onTap: () {},
            onRemove: () => notifier.detach(chip),
            removeLabel: l10n.aiChatChipRemove(chipLabel(l10n, chip)),
            struckHint: l10n.aiChatChipStruckHint,
          ),
        for (final chip in suggested)
          KContextChip(
            label: chipLabel(l10n, chip),
            icon: chipIcon(chip.kind),
            state: KContextChipState.suggested,
            onTap: () => notifier.attach(chip),
          ),
      ],
    );
  }
}
