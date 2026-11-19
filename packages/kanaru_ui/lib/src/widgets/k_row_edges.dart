import 'package:material_ui/material_ui.dart';

import '../layout/form_factor.dart';
import '../tokens/k_space.dart';

/// How the tint of a row (selected, hover, pressed, focus) meets the edges of
/// the surface that holds it. Never a rounded tint touching an edge.
enum KRowEdges {
  /// Tint spans the full width with square corners (mobile bottom sheets).
  fullBleed,

  /// Tint is rounded and kept [KSpace.x2] away from both side edges (dialogs,
  /// anchored panels, desktop menus).
  inset,
}

/// Tells the rows below which [KRowEdges] mode their surface wants. Provided
/// by the hosts (`showKSheet`, `showKDialog`, pickers, menus), read by the rows
/// of `kanaru_ui`; call sites never choose.
class KRowEdgesScope extends InheritedWidget {
  const KRowEdgesScope({super.key, required this.edges, required super.child});

  final KRowEdges edges;

  /// The mode of the nearest host, or null when none provides one (a row then
  /// keeps its own look).
  static KRowEdges? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KRowEdgesScope>()?.edges;

  @override
  bool updateShouldNotify(KRowEdgesScope old) => edges != old.edges;
}

/// Whether the surface around [context] is a bottom sheet (true) or a dialog /
/// panel (false). Decided by the host, not the shell width: `showKSheet` turns
/// into a dialog from 600 dp on any shell. Without a host the shell decides.
bool kHostIsSheet(BuildContext context) {
  final edges = KRowEdgesScope.maybeOf(context);
  if (edges != null) return edges == KRowEdges.fullBleed;
  return FormFactor.of(context) == FormFactor.mobile;
}

/// What a row does with the mode its host gave it (null = no host).
extension KRowEdgesLook on KRowEdges? {
  /// Gap between the row's tint and each side edge.
  double get sideGap => this == KRowEdges.inset ? KSpace.x2 : 0;

  /// Extra side padding of the content, so a full-bleed row's text lines up
  /// with an inset row's (gap + padding).
  double get contentExtra => this == KRowEdges.fullBleed ? KSpace.x2 : 0;

  /// Side padding for content that is not a row (banners, notes) so it keeps
  /// off the edges: the 16 dp axis of the surface minus the tint gap. Rows
  /// whose text must sit on that axis use it as their inner padding.
  double get axisInset => KSpace.x4 - sideGap;

  /// [rounded] for inset rows and rows without a host, square when full-bleed.
  BorderRadius corners(BorderRadius rounded) =>
      this == KRowEdges.fullBleed ? BorderRadius.zero : rounded;
}
