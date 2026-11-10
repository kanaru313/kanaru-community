import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';
import 'setup_row_frame.dart';

/// One permission of a [PermissionCard].
class PermissionRowData {
  const PermissionRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.stateLabel,
  });

  final IconData icon;
  final Widget title;
  final Widget subtitle;
  final bool granted;

  /// Spoken state, for example "Granted" or "Not granted".
  final String stateLabel;
}

/// The permission group of the first-run page: a row per permission with a
/// state circle (empty, or a check on the primary colour), then the action
/// button and a note. When [collapsed] it shrinks to one line, [collapsedLabel],
/// with a check.
class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.rows,
    required this.action,
    this.note,
    this.collapsed = false,
    this.collapsedLabel,
  }) : assert(
         !collapsed || collapsedLabel != null,
         'a collapsed card needs a collapsedLabel',
       );

  final List<PermissionRowData> rows;

  /// Usually a full-width filled button.
  final Widget action;
  final Widget? note;
  final bool collapsed;

  /// The single line of the collapsed card, without the check.
  final Widget? collapsedLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: scheme.surfaceContainerLow,
      shape: KShape.of(KRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: reduce ? Duration.zero : KMotion.normal,
        alignment: Alignment.topCenter,
        child: collapsed ? _collapsed(context) : _expanded(context),
      ),
    );
  }

  Widget _collapsed(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SetupRowFrame(
      leading: Icon(KIcons.check, color: scheme.primary),
      title: collapsedLabel!,
    );
  }

  Widget _expanded(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const KGap(KSpace.x1),
        for (final row in rows)
          SetupRowFrame(
            leading: Icon(row.icon),
            title: row.title,
            subtitle: row.subtitle,
            trailing: Semantics(
              label: row.stateLabel,
              child: _StateCircle(granted: row.granted),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KSpace.x4,
            KSpace.x2,
            KSpace.x4,
            0,
          ),
          child: action,
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x4,
              KSpace.x2,
              KSpace.x4,
              0,
            ),
            child: DefaultTextStyle.merge(
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              child: note!,
            ),
          ),
        const KGap(KSpace.x3),
      ],
    );
  }
}

class _StateCircle extends StatelessWidget {
  const _StateCircle({required this.granted});

  final bool granted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: KSpace.x7 - KSpace.x1,
      child: granted
          ? DecoratedBox(
              decoration: ShapeDecoration(
                shape: KShape.of(KRadius.full),
                color: scheme.primary,
              ),
              child: Icon(KIcons.check, size: 18, color: scheme.onPrimary),
            )
          : DecoratedBox(
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  borderRadius: KRadius.full,
                  side: BorderSide(color: scheme.outline, width: 2),
                ),
              ),
            ),
    );
  }
}
