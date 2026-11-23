import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// Header of the picker and its preview page: ← back, the title, ✕ close.
class PickerHeader extends StatelessWidget {
  const PickerHeader({
    super.key,
    required this.title,
    required this.backTooltip,
    required this.onBack,
    required this.onClose,
  });

  final String title;
  final String backTooltip;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(KSpace.x2),
    child: Row(
      children: [
        KIconButton(
          icon: KIcons.back,
          tooltip: backTooltip,
          padding: const EdgeInsets.all(KSpace.x3),
          onPressed: onBack,
        ),
        const KGap(KSpace.x2),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        KIconButton(
          icon: KIcons.close,
          tooltip: AppLocalizations.of(context).lyricsModalClose,
          padding: const EdgeInsets.all(KSpace.x3),
          onPressed: onClose,
        ),
      ],
    ),
  );
}
