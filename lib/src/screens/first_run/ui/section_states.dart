import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// The loading state of a section: a small spinner (only for permission and
/// catalog reads, which can take a moment).
class SectionSpinner extends StatelessWidget {
  const SectionSpinner({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox.square(
      dimension: KSpace.x6,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
  );
}

/// The error state of a section: a line and a retry button.
class SectionLoadFailed extends StatelessWidget {
  const SectionLoadFailed({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SetupNote(
      child: Row(
        children: [
          Expanded(child: Text(l10n.scanSetupLoadFailed)),
          TextButton(onPressed: onRetry, child: Text(l10n.scanSetupRetry)),
        ],
      ),
    );
  }
}
