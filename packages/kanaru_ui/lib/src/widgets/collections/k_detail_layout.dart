import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../../tokens/k_space.dart';

/// Page of a library item (album, artist, genre): a [header] and list
/// [slivers].
///
/// Narrow (< [wideBreakpoint] px, measured on the page, not the window): the
/// header sits above the list in one scroll. Wide: a fixed left column of
/// [columnWidth] holds the header, aligned to the column bottom and scrolling
/// on its own when the window is short; the slivers scroll on the right.
///
/// [tint] washes the page background with a soft gradient (at most 18 % in
/// light, 24 % in dark), so the page takes the colour of a cover.
class KDetailLayout extends StatelessWidget {
  const KDetailLayout({
    super.key,
    required this.header,
    required this.slivers,
    this.tint,
  });

  final Widget header;
  final List<Widget> slivers;
  final Color? tint;

  /// Page width at which the two-column layout starts.
  static const double wideBreakpoint = 840;
  static const double columnWidth = 320;

  /// Whether the [header] below this layout sits in the wide left column.
  /// False outside a [KDetailLayout].
  static bool isWide(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DetailMode>()?.wide ?? false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideBreakpoint;
        Widget content = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: columnWidth,
                    child: LayoutBuilder(
                      builder: (context, column) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: column.maxHeight,
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: header,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: CustomScrollView(slivers: slivers)),
                ],
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: header),
                  ...slivers,
                ],
              );
        content = _DetailMode(wide: wide, child: content);
        final color = tint;
        if (color == null) return content;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: dark ? 0.24 : 0.18),
                color.withValues(alpha: 0),
              ],
            ),
          ),
          child: content,
        );
      },
    );
  }
}

/// Translucent, blurred background for bars that stay on top while the page
/// scrolls under them, so a [KDetailLayout] tint is not cut by a flat bar.
/// Blur costs GPU: use it on those bars only.
class KBlurredBar extends StatelessWidget {
  const KBlurredBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: KSpace.x4, sigmaY: KSpace.x4),
        child: ColoredBox(color: surface.withValues(alpha: 0.72), child: child),
      ),
    );
  }
}

/// Sliver that pins [child] (a bar of fixed [height]) over a [KBlurredBar].
class KStickyBarSliver extends StatelessWidget {
  const KStickyBarSliver({
    super.key,
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _BarDelegate(
        height: height,
        child: KBlurredBar(child: child),
      ),
    );
  }
}

class _BarDelegate extends SliverPersistentHeaderDelegate {
  _BarDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox(height: height, child: child);

  @override
  bool shouldRebuild(_BarDelegate old) =>
      height != old.height || child != old.child;
}

class _DetailMode extends InheritedWidget {
  const _DetailMode({required this.wide, required super.child});

  final bool wide;

  @override
  bool updateShouldNotify(_DetailMode old) => old.wide != wide;
}
