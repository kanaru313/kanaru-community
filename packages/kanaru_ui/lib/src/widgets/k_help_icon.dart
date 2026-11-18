import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../icons/k_icons.dart';
import '../layout/form_factor.dart';
import '../tokens/k_icon_size.dart';
import '../tokens/k_space.dart';
import 'anchored_panel_layout.dart';
import 'k_help_panel.dart';
import 'k_icon_button.dart';
import 'k_sheet.dart';

/// The ⓘ after a section title in Settings. Short [message]: a popover
/// anchored to the icon. Longer than [longMessageLength] characters: a bottom
/// sheet on mobile, an anchored panel with [title] on desktop.
///
/// Mobile opens on tap. Desktop opens on hover, click (pins it) or keyboard
/// focus + Enter. Esc, Back or a tap outside closes it.
class KHelpIcon extends StatefulWidget {
  const KHelpIcon({
    super.key,
    required this.message,
    required this.tooltip,
    this.title,
    this.closeLabel,
  });

  /// Longer messages open as a sheet / panel instead of a popover.
  static const int longMessageLength = 140;

  /// Width of the desktop panel and of the popover.
  static const double panelWidth = 360;

  final String message;

  /// Accessible name of the icon button (the caller localises it).
  final String tooltip;

  /// Heading of the sheet / panel; none for a popover.
  final String? title;

  /// Label of the sheet's close button; the Material one when null.
  final String? closeLabel;

  @override
  State<KHelpIcon> createState() => _KHelpIconState();
}

class _KHelpIconState extends State<KHelpIcon> with WidgetsBindingObserver {
  static const _hoverDelay = Duration(milliseconds: 120);
  static const _leaveDelay = Duration(milliseconds: 160);

  final _portal = OverlayPortalController();
  ScrollPosition? _scroll;
  Timer? _timer;
  bool _pinned = false;

  bool get _long => widget.message.length > KHelpIcon.longMessageLength;
  bool get _mobile => FormFactor.of(context) == FormFactor.mobile;

  void _open({required bool pin}) {
    _timer?.cancel();
    if (pin) _pinned = true;
    if (_portal.isShowing) {
      setState(() {});
      return;
    }
    _portal.show();
    HardwareKeyboard.instance.addHandler(_onKey);
    WidgetsBinding.instance.addObserver(this);
    _scroll = Scrollable.maybeOf(context)?.position;
    _scroll?.addListener(_close);
    setState(() {});
  }

  void _close() {
    _timer?.cancel();
    _pinned = false;
    if (!_portal.isShowing) return;
    _portal.hide();
    _scroll?.removeListener(_close);
    _scroll = null;
    HardwareKeyboard.instance.removeHandler(_onKey);
    WidgetsBinding.instance.removeObserver(this);
    setState(() {});
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
    }
    // Never consumed: dialogs or fields above still see Esc.
    return false;
  }

  @override
  void didChangeMetrics() => _close();

  void _hover(bool inside) {
    if (_mobile || _pinned) return;
    _timer?.cancel();
    _timer = Timer(inside ? _hoverDelay : _leaveDelay, () {
      if (!mounted) return;
      inside ? _open(pin: false) : _close();
    });
  }

  void _press() {
    if (_mobile && _long) {
      showKSheet<void>(
        context,
        builder: (_) => KHelpSheetBody(
          message: widget.message,
          title: widget.title,
          closeLabel: widget.closeLabel,
        ),
      );
    } else if (_portal.isShowing && _pinned) {
      _close();
    } else {
      _open(pin: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll?.removeListener(_close);
    HardwareKeyboard.instance.removeHandler(_onKey);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back closes the popover; apps without a `Router` (a bare test host)
  /// have no back dispatcher to listen to.
  Widget _closeOnBack(Widget child) {
    if (Router.maybeOf(context) == null) return child;
    return BackButtonListener(
      onBackButtonPressed: () async {
        _close();
        return true;
      },
      child: child,
    );
  }

  Widget _overlay(BuildContext _) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) return const SizedBox.shrink();
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    return Stack(
      children: [
        if (_pinned)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
            ),
          ),
        CustomSingleChildLayout(
          delegate: AnchoredPanelLayout(anchor),
          child: _closeOnBack(
            MouseRegion(
              onEnter: (_) => _timer?.cancel(),
              onExit: (_) => _hover(false),
              child: KHelpPopoverCard(
                message: widget.message,
                title: _long ? widget.title : null,
                maxWidth: KHelpIcon.panelWidth,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _overlay,
      child: MouseRegion(
        onEnter: (_) => _hover(true),
        onExit: (_) => _hover(false),
        child: KIconButton(
          icon: KIcons.help,
          size: KIconSize.xs,
          tooltip: widget.tooltip,
          padding: const EdgeInsets.all(KSpace.x2),
          onPressed: _press,
        ),
      ),
    );
  }
}
