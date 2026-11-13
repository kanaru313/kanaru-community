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
/// It does not use `showKSheet`: that one switches to a dialog from 600 px
/// and is 640 wide, while this menu is a sheet up to the desktop form factor
/// and a 400 wide dialog above it.
///
/// A chosen row closes the menu first and then runs its callback, so the
/// callback may navigate.
///
/// [viaKeyboard] (opened with Menu, Shift+F10) focuses the first row at once.
/// Otherwise no row shows a focus ring until an arrow key is pressed: Linux
/// always reports the traditional highlight mode, so autofocus would draw a
/// ring on a menu opened with the mouse.
///
/// [initialPage] opens the menu already on that sub-page (normally one that
/// [root] reaches); Back from it returns to [root].
Future<void> showKLayeredMenu(
  BuildContext context, {
  required KMenuPage root,
  KMenuPage? initialPage,
  String? backTooltip,
  bool viaKeyboard = false,
}) {
  Widget body(BuildContext _) => _MenuBody(
    root: root,
    initialPage: initialPage,
    backTooltip: backTooltip,
    viaKeyboard: viaKeyboard,
  );
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
  const _MenuBody({
    required this.root,
    this.initialPage,
    this.backTooltip,
    this.viaKeyboard = false,
  });

  final KMenuPage root;
  final KMenuPage? initialPage;
  final String? backTooltip;
  final bool viaKeyboard;

  @override
  State<_MenuBody> createState() => _MenuBodyState();
}

class _MenuBodyState extends State<_MenuBody> {
  late final List<KMenuPage> _stack = [widget.root, ?widget.initialPage];

  /// Set when opened from the keyboard or once an arrow key was pressed; a
  /// pointer never sets it. Only then does a page focus its first row.
  late bool _keyboard = widget.viaKeyboard;

  /// Scroll offsets of the pages below the top one, so Back lands where the
  /// user left the parent page.
  late final List<double> _savedOffsets = [if (widget.initialPage != null) 0];

  /// The row that opened each page of the stack above the root (null for the
  /// header), so Back in keyboard mode focuses it again.
  late final List<KMenuRow?> _openedBy = [if (widget.initialPage != null) null];
  KMenuRow? _focusRow;
  final FocusNode _wrapper = FocusNode(debugLabel: 'KLayeredMenu');
  ScrollController _scroll = ScrollController();

  /// Controllers of left pages: their list may still be fading out.
  final List<ScrollController> _retired = [];

  KMenuPage get _page => _stack.last;

  void _push(KMenuPage page, {KMenuRow? from}) {
    setState(() {
      _openedBy.add(from);
      _focusRow = null;
      _savedOffsets.add(_scroll.hasClients ? _scroll.offset : 0);
      _retired.add(_scroll);
      _scroll = ScrollController();
      _stack.add(page);
    });
    _focusAfterNavigation();
  }

  void _back() {
    setState(() {
      _focusRow = _openedBy.removeLast();
      _retired.add(_scroll);
      _scroll = ScrollController(
        initialScrollOffset: _savedOffsets.removeLast(),
      );
      _stack.removeLast();
    });
    _focusAfterNavigation();
  }

  /// In keyboard mode a page change puts focus on a row of the new page once
  /// it is built: the row that opened the page on Back, else the first. The
  /// outgoing page may still hold focus while it fades, which makes a plain
  /// `autofocus` unreliable.
  void _focusAfterNavigation() {
    if (!_keyboard) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _focusRow;
      FocusNode? first;
      for (final d in _wrapper.descendants) {
        if (!d.canRequestFocus) continue;
        final tile = d.context?.findAncestorWidgetOfExactType<KMenuRowTile>();
        if (tile == null) continue;
        first ??= d;
        if (target != null && identical(tile.row, target)) {
          d.requestFocus();
          if (d.context != null) {
            Scrollable.ensureVisible(d.context!);
          }
          return;
        }
      }
      if (first != null) {
        first.requestFocus();
        if (first.context != null) {
          Scrollable.ensureVisible(first.context!);
        }
      }
    });
  }

  @override
  void dispose() {
    _wrapper.dispose();
    _scroll.dispose();
    for (final c in _retired) {
      c.dispose();
    }
    super.dispose();
  }

  /// Any navigation key makes the menu a keyboard one. An arrow with nothing
  /// focused inside (the wrapper holds focus) focuses the first row (Down) or
  /// the last built one (Up); with a row focused the default traversal moves
  /// from that row.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final down = key == LogicalKeyboardKey.arrowDown;
    final up = key == LogicalKeyboardKey.arrowUp;
    if (down || up || key == LogicalKeyboardKey.tab) _keyboard = true;
    if (!(down || up) || !node.hasPrimaryFocus) return KeyEventResult.ignored;
    final rows = [
      for (final d in node.descendants)
        if (d.canRequestFocus &&
            d.context?.findAncestorWidgetOfExactType<KMenuRowTile>() != null)
          d,
    ];
    if (rows.isEmpty) return KeyEventResult.ignored;
    (down ? rows.first : rows.last).requestFocus();
    return KeyEventResult.handled;
  }

  /// Closes the menu, then runs [effect] (a sub-page row has none).
  void _activate(KMenuRow row, VoidCallback effect) {
    final page = row.opens;
    if (page != null) {
      _push(page, from: row);
      return;
    }
    Navigator.of(context).pop();
    effect();
  }

  /// The header; a button with a `›` when it opens a page.
  Widget _header(KMenuPage page) {
    final opens = page.headerOpens;
    final header = page.header!;
    if (opens == null) return header;
    return InkWell(
      borderRadius: KRadius.sm,
      onTap: () => _push(opens),
      child: Row(
        children: [
          Expanded(child: header),
          Icon(
            KIcons.chevronRight,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final page = _page;
    final sub = _stack.length > 1;
    // Empty groups are skipped; their headings go with them.
    final groups = <List<KMenuRow>>[];
    final groupIndexTitles = <String?>[];
    for (var i = 0; i < page.groups.length; i++) {
      if (page.groups[i].isEmpty) continue;
      groups.add(page.groups[i]);
      groupIndexTitles.add(
        i < page.groupTitles.length ? page.groupTitles[i] : null,
      );
    }
    final target = (_focusRow?.active ?? false) ? _focusRow : null;
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
      final heading = gi < groupIndexTitles.length
          ? groupIndexTitles[gi]
          : null;
      if (heading != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KSpace.x4,
              KSpace.x2,
              KSpace.x4,
              KSpace.x1,
            ),
            child: Text(
              heading,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }
      for (final row in groups[gi]) {
        final autofocus =
            _keyboard &&
            row.active &&
            (target != null ? identical(row, target) : first);
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
        child: Focus(
          focusNode: _wrapper,
          autofocus: !_keyboard,
          onKeyEvent: _onKey,
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
                    child: _header(page),
                  ),
                Flexible(
                  child: AnimatedSwitcher(
                    duration: KMotion.fast,
                    // The page fading out must not hold focus or taps, or the
                    // new page's autofocus would be ignored.
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        for (final old in previous)
                          ExcludeFocus(child: IgnorePointer(child: old)),
                        ?current,
                      ],
                    ),
                    child: _body(page, children),
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
      ),
    );
  }

  /// Above this many rows a page is a lazy list in the space the dialog or
  /// sheet gives it, so a sub-page of hundreds of rows builds only the
  /// visible ones. A shorter page shrinks to its content.
  static const _lazyFrom = 24;

  Widget _body(KMenuPage page, List<Widget> rows) {
    final scheme = Theme.of(context).colorScheme;
    final items = <Widget>[
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
      ...rows,
    ];
    const padding = EdgeInsets.symmetric(vertical: KSpace.x1);
    if (items.length <= _lazyFrom) {
      return ListView(
        key: ValueKey(_stack.length),
        controller: _scroll,
        shrinkWrap: true,
        padding: padding,
        children: items,
      );
    }
    return ListView.builder(
      key: ValueKey(_stack.length),
      controller: _scroll,
      padding: padding,
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
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
