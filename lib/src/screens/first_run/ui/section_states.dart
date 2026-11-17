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

/// The error state of a section: a line and a retry button. [message]
/// replaces the generic "could not load this section" line.
class SectionLoadFailed extends StatelessWidget {
  const SectionLoadFailed({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SetupNote(
      child: Row(
        children: [
          Expanded(child: Text(message ?? l10n.scanSetupLoadFailed)),
          TextButton(onPressed: onRetry, child: Text(l10n.scanSetupRetry)),
        ],
      ),
    );
  }
}
