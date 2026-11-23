import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_icon_button.dart';
import 'k_menu_row.dart';

/// Header of a menu's root page. A plain widget when the page has no action;
/// else a button with a `›`: [KMenuPage.onHeaderTap] runs [onTap] and keeps
/// the menu open, [KMenuPage.headerOpens] shows that page through [onOpen].
class KMenuHeader extends StatelessWidget {
  const KMenuHeader({
    super.key,
    required this.page,
    required this.onOpen,
    required this.onTap,
  });

  final KMenuPage page;
  final void Function(KMenuPage page) onOpen;

  /// Runs [KMenuPage.onHeaderTap] with the menu's keyboard mode; null when the
  /// page has none.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final opens = page.headerOpens;
    final header = page.header!;
    final VoidCallback? tap =
        onTap ?? (opens == null ? null : () => onOpen(opens));
    if (tap == null) return header;
    return Semantics(
      button: true,
      hint: page.headerHint,
      child: InkWell(
        borderRadius: KRadius.sm,
        onTap: tap,
        child: Row(
          children: [
            Expanded(child: header),
            Icon(
              KIcons.chevronRight,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Alt+Enter on a root page with [KMenuPage.onHeaderTap] runs it as a
/// keyboard activation. Key repeat is ignored, so holding the keys opens the
/// target once.
Map<ShortcutActivator, VoidCallback> kMenuHeaderBindings({
  required KMenuPage page,
  required bool sub,
}) {
  final tap = page.onHeaderTap;
  if (sub || tap == null) return const {};
  return {
    const SingleActivator(
      LogicalKeyboardKey.enter,
      alt: true,
      includeRepeats: false,
    ): () =>
        tap(true),
  };
}

class KMenuSubPageTitle extends StatelessWidget {
  const KMenuSubPageTitle({
    super.key,
    required this.title,
    required this.onBack,
    this.backTooltip,
  });

  final String title;
  final VoidCallback onBack;
  final String? backTooltip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KSpace.x2),
      child: Row(
        children: [
          KIconButton(
            tooltip:
                backTooltip ??
                MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: onBack,
            icon: KIcons.back,
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
