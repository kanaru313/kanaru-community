import 'package:flutter/widgets.dart';

/// What a [KOverlayPageScope] child is drawn as.
enum KOverlayKind {
  /// Full-screen page (window narrower than `KBreakpoints.compactSheet`).
  page,

  /// Centred box over a barrier.
  box,
}

/// Tells the content of `showKOverlayPage` whether it sits in a page or a box
/// and rebuilds it when the window crosses the breakpoint, so widgets such as
/// `KInfoGroup` / `KInfoRow` pick their surface and label width without
/// reading the window width themselves.
class KOverlayPageScope extends InheritedWidget {
  const KOverlayPageScope({
    super.key,
    required this.kind,
    required super.child,
  });

  final KOverlayKind kind;

  bool get isPage => kind == KOverlayKind.page;

  /// The kind of the nearest overlay page, or null outside one.
  static KOverlayKind? maybeKindOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KOverlayPageScope>()?.kind;

  @override
  bool updateShouldNotify(KOverlayPageScope oldWidget) =>
      kind != oldWidget.kind;
}
