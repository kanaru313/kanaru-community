import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../icons/k_icons.dart';
import '../../layout/form_factor.dart';
import '../../tokens/k_motion.dart';
import '../../tokens/k_shape.dart';
import '../../tokens/k_space.dart';
import '../k_gap.dart';
import 'k_menu_row.dart';

export 'k_menu_row.dart'
    show KMenuButton, KMenuChip, KMenuPage, KMenuRow, KMenuTrailing;

/// Menu with pages: [root] first; a row with `opens` replaces the content
/// with that page under a `[←] title` row, and Back or Esc on a sub-page
/// returns to the page before instead of closing.
///
/// Mobile shell: bottom sheet (at most 85 % of the height, grip). Desktop
/// shell: centred dialog 400 wide and at most 640 tall over a 45 % barrier,
/// first row focused, arrow keys move between rows. Always on the root
/// navigator, whatever nested navigator [context] belongs to, so the app's
/// shortcut guard and Back handling see it as a modal.
///
/// A chosen row closes the menu first and then runs its callback, so the
/// callback may navigate.
Future<void> showKLayeredMenu(
  BuildContext context, {
  required KMenuPage root,
  String? backTooltip,
}) {
  Widget body(BuildContext _) =>
      _MenuBody(root: root, backTooltip: backTooltip);
  if (FormFactor.of(context) == FormFactor.mobile) {
    final height = MediaQuery.sizeOf(context).height * 0.85;
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: KShape.of(
        BorderRadius.vertical(top: KRadius.xl.topLeft),
        continuous: true,
      ),
      constraints: BoxConstraints(maxHeight: height),
      builder: body,
    );
  }
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierColor: const Color(0x73000000), // 45 %
    builder: (context) => Dialog(
      shape: KShape.of(KRadius.xl, continuous: true),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: KLayeredMenu.desktopWidth,
          maxHeight: KLayeredMenu.desktopMaxHeight,
        ),
        child: body(context),
      ),
    ),
  );
}

/// Sizes of the desktop dialog.
abstract final class KLayeredMenu {
  static const double desktopWidth = 400;
  static const double desktopMaxHeight = 640;
}

class _MenuBody extends StatefulWidget {
  const _MenuBody({required this.root, this.backTooltip});

  final KMenuPage root;
  final String? backTooltip;

  @override
  State<_MenuBody> createState() => _MenuBodyState();
}

class _MenuBodyState extends State<_MenuBody> {
  late final List<KMenuPage> _stack = [widget.root];

  KMenuPage get _page => _stack.last;

  void _back() => setState(_stack.removeLast);

  /// Closes the menu, then runs [effect] (a sub-page row has none).
  void _activate(KMenuRow row, VoidCallback effect) {
    final page = row.opens;
    if (page != null) {
      setState(() => _stack.add(page));
      return;
    }
    Navigator.of(context).pop();
    effect();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final page = _page;
    final sub = _stack.length > 1;
    final groups = [
      for (final g in page.groups)
        if (g.isNotEmpty) g,
    ];
    var first = true;
    final children = <Widget>[];
    for (var gi = 0; gi < groups.length; gi++) {
      if (gi > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KSpace.x4,
              vertical: KSpace.x1,
            ),
            child: Divider(
              height: 1,
              thickness: 1,
              color: scheme.outlineVariant,
            ),
          ),
        );
      }
      for (final row in groups[gi]) {
        final autofocus = first && row.active;
        if (autofocus) first = false;
        children.add(
          KMenuRowTile(
            row: row,
            autofocus: autofocus,
            onActivate: (effect) => _activate(row, effect),
          ),
        );
      }
    }
    return PopScope(
      canPop: !sub,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && sub) _back();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).maybePop(),
        },
        child: FocusTraversalGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sub)
                _SubPageTitle(
                  title: page.title ?? '',
                  backTooltip: widget.backTooltip,
                  onBack: _back,
                )
              else if (page.header != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    KSpace.x4,
                    KSpace.x2,
                    KSpace.x4,
                    KSpace.x2,
                  ),
                  child: page.header,
                ),
              Flexible(
                child: AnimatedSwitcher(
                  duration: KMotion.fast,
                  child: ListView(
                    key: ValueKey(_stack.length),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: KSpace.x1),
                    children: [
                      if (page.note != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            KSpace.x4,
                            KSpace.x1,
                            KSpace.x4,
                            KSpace.x3,
                          ),
                          child: Text(
                            page.note!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ...children,
                    ],
                  ),
                ),
              ),
              if (page.footer.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(KSpace.x4),
                  child: Row(
                    children: [
                      for (var i = 0; i < page.footer.length; i++) ...[
                        if (i > 0) const KGap(KSpace.x3),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              page.footer[i].onPressed();
                            },
                            icon: Icon(page.footer[i].icon),
                            label: Text(
                              page.footer[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubPageTitle extends StatelessWidget {
  const _SubPageTitle({
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
          IconButton(
            tooltip: backTooltip,
            onPressed: onBack,
            icon: const Icon(KIcons.back),
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
