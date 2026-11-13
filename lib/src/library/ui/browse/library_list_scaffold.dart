import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/browse/song_scope.dart';
import '../../domain/library_tabs.dart';
import '../../domain/scan_status.dart';
import '../../state/browse/song_list_providers.dart';
import '../../state/library_tabs_providers.dart';
import '../../state/scan_providers.dart';
import '../library_locations.dart';
import 'library_empty_state.dart';
import 'library_labels.dart';
import 'library_navigation.dart';
import 'scan_banner.dart';

/// Side gutter of the library pages on the current shell.
double libraryGutter(BuildContext context) =>
    FormFactor.of(context) == FormFactor.desktop
    ? KLayout.gutterDesktop
    : KLayout.gutterMobile;

/// Side gutter of a sliver of [KMediaCard] rows: none on mobile (the flat row
/// pads itself to line up with the headers), the desktop gutter around cards.
double libraryRowGutter(BuildContext context) =>
    FormFactor.of(context) == FormFactor.desktop ? KLayout.gutterDesktop : 0;

/// Frame of one of the six list pages.
///
/// A root page: [PageHeader] without a back button, so the shell's header
/// scope shows its own slots. Mobile adds the sub-tab row (tap or a drag of
/// more than 60 px changes list) and the title reads "Library"; desktop
/// titles the page with the list name and has no tab row. Under the header a
/// scan banner shows while a scan runs. A library with no track at all shows
/// the empty state in place of [child].
///
/// Switching list replaces the page without a transition. Only the body
/// slides in, from the side the new tab lies on; the header and tab row stay
/// still and the tab row keeps its scroll offset.
class LibraryListScaffold extends ConsumerStatefulWidget {
  const LibraryListScaffold({
    super.key,
    required this.tab,
    required this.child,
  });

  final LibraryTab tab;
  final Widget child;

  @override
  ConsumerState<LibraryListScaffold> createState() =>
      _LibraryListScaffoldState();
}

class _LibraryListScaffoldState extends ConsumerState<LibraryListScaffold>
    with SingleTickerProviderStateMixin {
  /// Drag distance that counts as a swipe.
  static const double _swipeDistance = 60;

  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: KMotion.normal,
    value: 1,
  );
  bool _started = false;
  double _slideFrom = 0;
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    final previous = ref.read(lastLibraryTabProvider);
    final visible = ref.read(libraryTabsProvider).visible;
    final from = previous == null ? -1 : visible.indexOf(previous);
    final to = visible.indexOf(widget.tab);
    if (from >= 0 && to >= 0 && from != to) {
      _slideFrom = to > from ? 1 : -1;
    }
    // Provider state is not written while the tree builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(lastLibraryTabProvider.notifier).visit(widget.tab);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    if (mobile && _slideFrom != 0 && !MediaQuery.disableAnimationsOf(context)) {
      _slide.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  void _goTo(LibraryTab tab) {
    if (tab != widget.tab) context.go(LibraryLocations.list(tab));
  }

  void _swipeEnd() {
    final distance = _drag;
    _drag = 0;
    if (distance.abs() <= _swipeDistance) return;
    final visible = ref.read(libraryTabsProvider).visible;
    final index = visible.indexOf(widget.tab);
    if (index < 0) return;
    // Dragging left reveals the next tab.
    final target = index + (distance < 0 ? 1 : -1);
    if (target < 0 || target >= visible.length) return;
    _goTo(visible[target]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mobile = FormFactor.of(context) == FormFactor.mobile;
    final gutter = libraryGutter(context);
    final visible = ref.watch(libraryTabsProvider.select((c) => c.visible));
    final total = ref.watch(songCountProvider(const SongScope.all()));
    final scanning = ref.watch(
      scanStatusProvider.select((s) => s.value is ScanRunning),
    );
    final empty = total.value == 0 && !scanning;

    Widget body;
    if (empty) {
      body = const LibraryEmptyState();
    } else if (total.hasError && !total.hasValue) {
      body = Center(
        child: Text(
          l10n.libraryLoadFailed,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    } else if (!total.hasValue && !scanning) {
      // Not known yet: draw nothing rather than a list that may be replaced
      // by the empty state a moment later.
      body = const SizedBox.shrink();
    } else {
      body = widget.child;
    }
    if (mobile) {
      // A mouse needs a real drag distance before the swipe wins, so the
      // jitter of a click does not eat the tap on a row; touch keeps the
      // device's own slop, set here because RawGestureDetector does not.
      body = RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: {
          KSwipeDragRecognizer:
              GestureRecognizerFactoryWithHandlers<KSwipeDragRecognizer>(
                KSwipeDragRecognizer.new,
                (r) => r
                  ..gestureSettings = MediaQuery.maybeGestureSettingsOf(context)
                  ..onStart = ((_) => _drag = 0)
                  ..onUpdate = ((d) => _drag += d.delta.dx)
                  ..onEnd = ((_) => _swipeEnd())
                  ..onCancel = (() => _drag = 0),
              ),
        },
        child: body,
      );
    }
    final slide = _slideFrom == 0
        ? body
        : ClipRect(
            child: FadeTransition(
              opacity: _slide,
              child: SlideTransition(
                position: Tween(
                  begin: Offset(_slideFrom * 0.25, 0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(_slide),
                child: body,
              ),
            ),
          );

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: PageHeader(
            title: mobile ? l10n.navLibrary : libraryTabLabel(l10n, widget.tab),
          ),
        ),
        if (mobile)
          KSubTabBar(
            labels: [for (final t in visible) libraryTabLabel(l10n, t)],
            selectedIndex: visible.indexOf(widget.tab),
            onSelected: (i) => _goTo(visible[i]),
            initialOffset: ref.read(subTabOffsetProvider),
            onOffsetChanged: (o) =>
                ref.read(subTabOffsetProvider.notifier).update(o),
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: const ScanBanner(),
        ),
        Expanded(child: slide),
      ],
    );
  }
}
