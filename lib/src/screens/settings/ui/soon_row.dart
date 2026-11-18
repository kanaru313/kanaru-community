import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';

/// A row for a setting that is not built yet: dimmed, "Coming soon" label,
/// not tappable.
class SoonRow extends StatelessWidget {
  const SoonRow({
    super.key,
    required this.icon,
    required this.title,
    this.desc,
  });

  final IconData icon;
  final Widget title;

  /// The line under the title; none for a self-explanatory row.
  final String? desc;

  @override
  Widget build(BuildContext context) {
    final line = desc;
    return SetupValueRow(
      icon: icon,
      title: title,
      value: line == null ? const SizedBox.shrink() : Text(line),
      onTap: null,
      comingSoon: true,
      soonLabel: AppLocalizations.of(context).appComingSoon,
    );
  }
}
