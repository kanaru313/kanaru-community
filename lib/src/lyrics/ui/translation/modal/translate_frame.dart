import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../media/domain/track_id.dart';

/// What the pages of one open "Dịch lời" modal share: the track, whether the
/// modal follows the playing song, and the routes it is made of (the modal
/// and the sub-pages stacked over it), so any page can close them all.
class TranslateModalControl {
  TranslateModalControl({
    required this.trackId,
    required this.followsPlaying,
    required this.navigator,
  });

  final TrackId trackId;
  final bool followsPlaying;
  final NavigatorState navigator;

  final List<ModalRoute<Object?>> _routes = [];
  bool _closing = false;

  void _register(ModalRoute<Object?> route) {
    if (!_routes.contains(route)) _routes.add(route);
  }

  void _unregister(ModalRoute<Object?> route) => _routes.remove(route);

  /// Closes the sub-pages and the modal, the topmost first. False when it is
  /// already closing, so a caller never acts twice.
  bool closeAll() {
    if (_closing || !navigator.mounted) return false;
    _closing = true;
    for (final route in _routes.reversed.toList()) {
      if (!route.isActive) continue;
      route.isCurrent ? navigator.pop() : navigator.removeRoute(route);
    }
    return true;
  }
}

/// Shows [content] as one page of the modal: a bottom sheet on the mobile
/// shell, a dialog of [KLayout.dialog] on the desktop shell, over every
/// navigator. The first page is the modal, later ones stack over it (the
/// parent stays dimmed below); Esc and Back close the topmost.
Future<void> showTranslateFrame(
  BuildContext context,
  TranslateModalControl control,
  WidgetBuilder content,
) {
  Widget framed(BuildContext context) =>
      _FrameScope(control: control, child: content(context));
  if (FormFactor.of(context) == FormFactor.desktop) {
    return showKDialog<void>(
      context,
      maxWidth: KLayout.dialog,
      // The 440 dp cap already leaves room to the window edges, so the
      // dialog's own side inset must not shrink it.
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(vertical: KSpace.x6),
        child: framed(context),
      ),
    );
  }
  return showKSheet<void>(context, useRootNavigator: true, builder: framed);
}

/// Names the page for screen readers and tells the control about its route.
class _FrameScope extends StatefulWidget {
  const _FrameScope({required this.control, required this.child});

  final TranslateModalControl control;
  final Widget child;

  @override
  State<_FrameScope> createState() => _FrameScopeState();
}

class _FrameScopeState extends State<_FrameScope> {
  ModalRoute<Object?>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      _route = route;
      widget.control._register(route);
    }
  }

  @override
  void dispose() {
    final route = _route;
    if (route != null) widget.control._unregister(route);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: widget.child,
  );
}
