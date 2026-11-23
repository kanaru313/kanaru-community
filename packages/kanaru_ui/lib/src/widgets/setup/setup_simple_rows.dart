import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_icon_size.dart';
import '../../tokens/k_space.dart';
import '../k_alert_dot.dart';
import '../k_gap.dart';
import 'setup_row_frame.dart';

/// A row that shows the current value of a choice and opens its picker when
/// tapped: optional leading icon, title, the value as the line under the title (with
/// an optional small [valueLeading] icon) and a chevron. Pass [anchorKey] to
/// let a desktop picker open anchored under the row.
///
/// [enabled] false dims the row, ignores taps and shows [disabledReason] in
/// place of the value. [comingSoon] dims it too and shows [soonLabel] where
/// the chevron was. [alert] puts a [KAlertDot] after the title; [alertLabel]
/// is what a screen reader adds to the row for it (the dot itself is silent).
class SetupValueRow extends StatelessWidget {
  const SetupValueRow({
    super.key,
    this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.valueLeading,
    this.anchorKey,
    this.enabled = true,
    this.disabledReason,
    this.comingSoon = false,
    this.soonLabel,
    this.alert = false,
    this.alertLabel,
  }) : assert(
         !alert || alertLabel != null,
         'a dot needs the words a screen reader says for it',
       );

  /// Leading icon; without it the row has no leading slot.
  final IconData? icon;
  final Widget title;
  final Widget value;
  final VoidCallback? onTap;

  /// Small icon (16 dp) before the value, for example a plugin's logo.
  final IconData? valueLeading;
  final GlobalKey? anchorKey;
  final bool enabled;

  /// Why the row is disabled; replaces the value line while [enabled] is false.
  final Widget? disabledReason;
  final bool comingSoon;
  final String? soonLabel;
  final bool alert;
  final String? alertLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reason = !enabled ? disabledReason : null;
    return KeyedSubtree(
      key: anchorKey,
      child: SetupRowFrame(
        leading: icon == null ? null : Icon(icon),
        title: alert ? _titleWithDot() : title,
        enabled: enabled,
        comingSoon: comingSoon,
        soonLabel: soonLabel,
        onTap: onTap,
        subtitle: reason ?? _valueLine(),
        trailing: Icon(KIcons.chevronRight, color: scheme.onSurfaceVariant),
      ),
    );
  }

  Widget _titleWithDot() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: title),
        const KGap(KSpace.x2),
        Semantics(label: alertLabel, child: const KAlertDot()),
      ],
    );
  }

  Widget _valueLine() {
    final leading = valueLeading;
    if (leading == null) {
      return DefaultTextStyle.merge(
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
        child: value,
      );
    }
    return Row(
      children: [
        Icon(leading, size: KIconSize.xs),
        const KGap(KSpace.x1),
        Expanded(
          child: DefaultTextStyle.merge(
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            child: value,
          ),
        ),
      ],
    );
  }
}

/// The "+ Add …" row at the end of a list: primary-coloured icon and label.
class SetupAddRow extends StatelessWidget {
  const SetupAddRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Widget label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: SetupRowFrame(
        leading: IconTheme.merge(
          data: IconThemeData(color: scheme.primary),
          child: Icon(icon),
        ),
        title: label,
        onTap: onTap,
        titleStyle: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// A line of explanation inside a setup card (empty list, missing
/// permission), with the card's padding.
class SetupNote extends StatelessWidget {
  const SetupNote({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(KSpace.x4),
      child: DefaultTextStyle.merge(
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: scheme.onSurfaceVariant),
        child: child,
      ),
    );
  }
}
