import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../layout/form_factor.dart';
import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_space.dart';
import 'k_fab_menu_parts.dart';

/// One pill of a [KFabMenu]. A null [onPressed] or `enabled: false` dims it
/// and makes it inert. [trailing] is for a badge such as `ProBadge`.
class KFabMenuItem {
  const KFabMenuItem({
    required this.icon,
    required this.label,
    this.onPressed,
    this.enabled = true,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final Widget? trailing;
}

/// Opens and closes a [KFabMenu] from outside (a shortcut, a test). `true` =
/// open. The caller owns and disposes it.
class KFabMenuController extends ValueNotifier<bool> {
  KFabMenuController() : super(false);

  void open() => value = true;
  void close() => value = false;
}

/// A floating action button at the bottom end of [child] that opens a stack of
/// pills. Open: a 40 % scrim covers [child] only, the pills rise from the
/// button one after another (the first of [items] is the nearest).
///
/// Closes on the ✕, the scrim, an item (closes, then runs it), Back, Esc, when
/// the tab it sits in stops ticking, and when the menu is disposed. Back and
/// Esc only act while it is open, its route is the current one and no modal
/// sits on the root navigator; Esc also yields to a focused text field.
class KFabMenu extends StatefulWidget {
  const KFabMenu({
    super.key,
    required this.child,
    required this.items,
    required this.openTooltip,
    required this.closeTooltip,
    this.icon = KIcons.add,
    this.controller,
  });

  /// End padding a scrolling list needs so its last row clears the button.
  static const double listEndPadding = 88;

  final Widget child;
  final List<KFabMenuItem> items;
  final String openTooltip;
  final String closeTooltip;
  final IconData icon;
  final KFabMenuController? controller;

  @override
  State<KFabMenu> createState() => _KFabMenuState();
}

const double _pillHeightMobile = 56;
const double _pillHeightDesktop = 52;

/// Pills slide this far up while they fade in.
const double _riseDistance = 16;
const double _enterScale = 0.85;
const double _scrimOpacity = 0.4;

class _KFabMenuState extends State<KFabMenu>
    with SingleTickerProviderStateMixin {
  final FocusNode _fabFocus = FocusNode(
    debugLabel: 'KFabMenu button',
    canRequestFocus: false,
    skipTraversal: true,
  );
  final FocusNode _pillsFocus = FocusNode(
    debugLabel: 'KFabMenu pills',
    canRequestFocus: false,
    skipTraversal: true,
  );
  bool _handlingKeys = false;
  late final AnimationController _anim = AnimationController(vsync: this);
  KFabMenuController? _ownController;
  late KFabMenuController _controller = _resolveController();

  KFabMenuController _resolveController() =>
      widget.controller ?? (_ownController ??= KFabMenuController());

  bool get _open => _controller.value;

  Duration get _total =>
      KMotion.normal + KMotion.stagger * (widget.items.length - 1).clamp(0, 99);

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _anim.value = _open ? 1 : 0;
    _syncKeyHandler();
  }

  @override
  void didUpdateWidget(KFabMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_onChanged);
      _controller = _resolveController();
      _controller.addListener(_onChanged);
      _syncKeyHandler();
      _sync();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A tab that stops ticking (switched away) closes the menu. Done after the
    // frame: the controller's other listeners may rebuild their widgets.
    if (!TickerMode.valuesOf(context).enabled &&
        (_open || !_anim.isDismissed)) {
      _anim.value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !TickerMode.valuesOf(context).enabled) {
          _controller.close();
        }
      });
    }
  }

  @override
  void dispose() {
    _setKeyHandler(false);
    _fabFocus.dispose();
    _pillsFocus.dispose();
    _controller.removeListener(_onChanged);
    _ownController?.dispose();
    _anim.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    final focusPills =
        _open &&
        _fabFocus.hasFocus &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final restoreFab = !_open && _pillsFocus.hasFocus;
    _syncKeyHandler();
    setState(_sync);
    if (focusPills || restoreFab) {
      // The pills exist (or are gone) only after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Pills read top-down with the first item nearest the button, so the
        // first enabled item is the last focusable pill.
        final candidates = (focusPills ? _pillsFocus : _fabFocus)
            .traversalDescendants
            .where((n) => n.canRequestFocus);
        (focusPills ? candidates.lastOrNull : candidates.firstOrNull)
            ?.requestFocus();
      });
    }
  }

  /// The Esc handler exists only while the menu is open.
  void _syncKeyHandler() => _setKeyHandler(_open);

  void _setKeyHandler(bool on) {
    if (on == _handlingKeys) return;
    _handlingKeys = on;
    if (on) {
      HardwareKeyboard.instance.addHandler(_onKey);
    } else {
      HardwareKeyboard.instance.removeHandler(_onKey);
    }
  }

  void _sync() {
    final target = _open ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _anim.value = target;
      return;
    }
    _anim.duration = _total;
    _open ? _anim.forward() : _anim.reverse();
  }

  /// Whether Back / Esc belongs to this menu right now.
  bool get _ownsDismissal =>
      mounted &&
      _open &&
      ModalRoute.of(context)?.isCurrent != false &&
      !(Navigator.maybeOf(context, rootNavigator: true)?.canPop() ?? false);

  bool _dismiss() {
    if (!_ownsDismissal) return false;
    _controller.close();
    return true;
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.escape) return false;
    final focus = FocusManager.instance.primaryFocus;
    if (focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) {
      return false;
    }
    return _dismiss();
  }

  void _choose(KFabMenuItem item) {
    _controller.close();
    item.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = FormFactor.of(context) == FormFactor.desktop;
    final margin = desktop ? KLayout.gutterDesktop : KLayout.gutterMobile;
    final bottom = margin + MediaQuery.paddingOf(context).bottom;
    final pillHeight = desktop ? _pillHeightDesktop : _pillHeightMobile;
    final stack = Stack(
      fit: StackFit.passthrough,
      children: [
        // Behind the scrim the page is neither read nor reachable by Tab.
        ExcludeFocus(
          excluding: _open,
          child: ExcludeSemantics(excluding: _open, child: widget.child),
        ),
        AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            if (_anim.isDismissed && !_open) return const SizedBox.shrink();
            return Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _controller.close,
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.scrim.withValues(
                    alpha: _scrimOpacity * _anim.value.clamp(0.0, 1.0),
                  ),
                ),
              ),
            );
          },
        ),
        PositionedDirectional(
          end: margin,
          bottom: bottom,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AnimatedBuilder(
                animation: _anim,
                builder: (context, _) => _anim.isDismissed && !_open
                    ? const SizedBox.shrink()
                    : Focus(focusNode: _pillsFocus, child: _pills(pillHeight)),
              ),
              Focus(
                focusNode: _fabFocus,
                child: FabMenuButton(
                  icon: widget.icon,
                  open: _open,
                  tooltip: _open ? widget.closeTooltip : widget.openTooltip,
                  onPressed: () =>
                      _open ? _controller.close() : _controller.open(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    // Without a Router above (a plain Navigator app, a test host) there is no
    // back dispatcher to join; the Esc handler and the scrim still work.
    if (Router.maybeOf(context) == null) return stack;
    return BackButtonListener(
      onBackButtonPressed: () async => _dismiss(),
      child: stack,
    );
  }

  Widget _pills(double height) {
    final n = widget.items.length;
    final totalMs = _total.inMicroseconds;
    Widget pill(int i) {
      final item = widget.items[i];
      final begin = (KMotion.stagger * i).inMicroseconds / totalMs;
      final end = begin + KMotion.normal.inMicroseconds / totalMs;
      final t = _anim.drive(
        CurveTween(
          curve: Interval(begin, end.clamp(0.0, 1.0), curve: Curves.easeOut),
        ),
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: KSpace.x3),
        child: FadeTransition(
          opacity: t,
          child: SlideTransition(
            position: t.drive(
              Tween(begin: Offset(0, _riseDistance / height), end: Offset.zero),
            ),
            child: ScaleTransition(
              scale: t.drive(Tween(begin: _enterScale, end: 1.0)),
              alignment: Alignment.centerRight,
              child: FabMenuPill(
                icon: item.icon,
                label: item.label,
                height: height,
                enabled: item.enabled && item.onPressed != null,
                trailing: item.trailing,
                onTap: () => _choose(item),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [for (var i = n - 1; i >= 0; i--) pill(i)],
    );
  }
}
