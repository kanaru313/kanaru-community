import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

/// Tells a page header whether the page's own name has scrolled out of
/// sight, so the header can show the name then (and stay empty before).
///
/// Wrap the page (header and content) in one host. The name in the content
/// is a [KDetailTitle]; the header reads [collapsedOf].
class KDetailTitleHost extends StatefulWidget {
  const KDetailTitleHost({super.key, required this.child});

  final Widget child;

  /// Whether the content's name is scrolled out of sight. False without a
  /// host. Registers [context] to rebuild when it changes.
  static bool collapsedOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_HostScope>()
          ?.notifier
          ?.value ??
      false;

  @override
  State<KDetailTitleHost> createState() => _KDetailTitleHostState();
}

class _KDetailTitleHostState extends State<KDetailTitleHost> {
  final ValueNotifier<bool> _collapsed = ValueNotifier(false);
  Object? _token;
  VoidCallback? _recompute;
  bool _wanted = false;
  bool _scheduled = false;

  /// The title that reports to this host replaces the previous one: on a
  /// remount the new title registers before the old one is disposed.
  void register(Object token, VoidCallback recompute) {
    _token = token;
    _recompute = recompute;
  }

  /// Drops [token] if it is still the registered one; the header then
  /// shows nothing.
  void unregister(Object token) {
    if (!identical(_token, token)) return;
    _token = null;
    _recompute = null;
    set(false);
  }

  /// Writes the collapsed state. While the tree is being built, laid out or
  /// finalized (`persistentCallbacks`) listeners must not run, so the write
  /// waits for the end of that frame, one callback per frame.
  void set(bool value) {
    _wanted = value;
    if (!_scheduled && value == _collapsed.value) return;
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      _collapsed.value = value;
      return;
    }
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) _collapsed.value = _wanted;
    });
  }

  bool _onMetrics(ScrollMetricsNotification n) {
    // Only vertical content moves the name; a horizontal shelf does not.
    if (n.metrics.axis == Axis.vertical) _recompute?.call();
    return false;
  }

  @override
  void dispose() {
    _collapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _HostScope(
      host: this,
      notifier: _collapsed,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _onMetrics,
        child: widget.child,
      ),
    );
  }
}

class _HostScope extends InheritedNotifier<ValueNotifier<bool>> {
  const _HostScope({
    required this.host,
    required ValueNotifier<bool> notifier,
    required super.child,
  }) : super(notifier: notifier);

  final _KDetailTitleHostState host;
}

/// Name of a detail page inside its content (hero, banner, grid heading).
/// Not exported: the owning widget passes [style] and colour, so call sites
/// of the app never style a name.
///
/// It tells the enclosing [KDetailTitleHost] when its bottom edge has
/// scrolled above the top of the vertical scroll area that holds it. The
/// threshold (`getOffsetToReveal`, cheap) is recomputed whenever the host
/// sees vertical scroll metrics change, which is every scrolled frame; each
/// scroll update then compares `pixels` with it.
class KDetailTitle extends StatefulWidget {
  const KDetailTitle(
    this.text, {
    super.key,
    required this.style,
    required this.maxLines,
  });

  final String text;
  final TextStyle style;
  final int maxLines;

  @override
  State<KDetailTitle> createState() => _KDetailTitleState();
}

class _KDetailTitleState extends State<KDetailTitle> {
  final Object _token = Object();
  _KDetailTitleHostState? _host;
  ScrollPosition? _position;
  double? _threshold;
  bool _recomputeScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final host = context.getInheritedWidgetOfExactType<_HostScope>()?.host;
    if (!identical(host, _host)) {
      _host?.unregister(_token);
      _host = host;
    }
    host?.register(_token, _recompute);
    final position = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (!identical(position, _position)) {
      _position?.removeListener(_evaluate);
      _position = position;
      position?.addListener(_evaluate);
    }
    _scheduleRecompute();
  }

  @override
  void didUpdateWidget(KDetailTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleRecompute();
  }

  @override
  void dispose() {
    _position?.removeListener(_evaluate);
    _host?.unregister(_token);
    super.dispose();
  }

  /// Layout is final only after the frame: measure then.
  void _scheduleRecompute() {
    if (_host == null || _position == null || _recomputeScheduled) return;
    _recomputeScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _recomputeScheduled = false;
      if (mounted) _recompute();
    });
  }

  /// Scroll offset at which the bottom of the name meets the top of the
  /// scroll area.
  void _recompute() {
    final box = context.findRenderObject();
    final position = _position;
    if (position == null || box is! RenderBox || !box.attached) return;
    if (!box.hasSize) return;
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null) return;
    _threshold = viewport.getOffsetToReveal(box, 0).offset + box.size.height;
    _evaluate();
  }

  void _evaluate() {
    // Only the title the host knows speaks for the page.
    if (!identical(_host?._token, _token)) return;
    final threshold = _threshold;
    final position = _position;
    if (threshold == null || position == null || !position.hasPixels) return;
    _host?.set(position.pixels >= threshold - 0.5);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        widget.text,
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      ),
    );
  }
}
