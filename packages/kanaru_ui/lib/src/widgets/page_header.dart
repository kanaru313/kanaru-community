import '../icons/k_icons.dart';

import 'package:material_ui/material_ui.dart';

import '../tokens/k_layout.dart';
import '../tokens/k_motion.dart';
import '../tokens/k_space.dart';
import 'k_detail_title.dart';
import 'page_header_scope.dart';
import 'k_icon_button.dart';

/// Header of every page: `[<]` (child pages only), title, spacer, actions.
/// Root pages pass no [onBack], so the back button is hidden and the
/// enclosing [PageHeaderScope]'s `leading` and `rootTrailing` show instead.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.actions = const [],
    this.backTooltip,
    this.titleInContent = false,
    this.shellActions = true,
  });

  final String title;

  /// Goes up to the parent page. Null on a root page.
  final VoidCallback? onBack;
  final List<Widget> actions;
  final String? backTooltip;

  /// The page shows its name in its content; the header shows [title] only
  /// while that name is scrolled out of sight (see [KDetailTitleHost]) and
  /// stays empty otherwise.
  final bool titleInContent;

  /// False: the page shows only [actions], none of the enclosing
  /// [PageHeaderScope]'s `trailing` / `rootTrailing` (pages whose header holds
  /// their own search and source buttons). The root page's `leading` stays.
  final bool shellActions;

  @override
  Widget build(BuildContext context) {
    final scope = PageHeaderScope.of(context);
    final isRoot = onBack == null;
    return SizedBox(
      height: KLayout.minTarget + KSpace.x2,
      child: Row(
        spacing: KSpace.x2,
        children: [
          if (isRoot && scope?.leading != null) scope!.leading!,
          if (!isRoot)
            KIconButton(
              icon: KIcons.back,
              tooltip:
                  backTooltip ??
                  MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: onBack,
            ),
          Expanded(
            child: titleInContent
                ? _CollapsingTitle(
                    title: title,
                    show: KDetailTitleHost.collapsedOf(context),
                  )
                : Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _style(context),
                  ),
          ),
          ...actions,
          if (shellActions) ...?scope?.trailing,
          if (isRoot && shellActions) ...?scope?.rootTrailing,
        ],
      ),
    );
  }
}

TextStyle? _style(BuildContext context) =>
    Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w700);

/// Title that fades in (and rises 4 dp) when [show] turns true and out when
/// it turns false. While hidden after the fade it builds no [Text], so the
/// hidden name is not in the tree at all.
class _CollapsingTitle extends StatefulWidget {
  const _CollapsingTitle({required this.title, required this.show});

  final String title;
  final bool show;

  @override
  State<_CollapsingTitle> createState() => _CollapsingTitleState();
}

class _CollapsingTitleState extends State<_CollapsingTitle>
    with TickerProviderStateMixin {
  /// Distance the title rests below its place while hidden.
  static const double _rise = KSpace.x1;

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: KMotion.fast,
    value: widget.show ? 1 : 0,
  );

  // Unbounded: the snappy spring overshoots.
  late final AnimationController _offset = AnimationController.unbounded(
    vsync: this,
    value: widget.show ? 0 : _rise,
  );

  @override
  void didUpdateWidget(_CollapsingTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.show == widget.show) return;
    final show = widget.show;
    if (MediaQuery.disableAnimationsOf(context)) {
      _fade.value = show ? 1 : 0;
    } else {
      _fade.animateTo(
        show ? 1 : 0,
        duration: KMotion.fast,
        curve: KMotion.emphasized,
      );
    }
    KSpring.animateTo(context, _offset, show ? 0 : _rise, KSpring.snappy);
  }

  @override
  void dispose() {
    _fade.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fade, _offset]),
      builder: (context, _) {
        if (!widget.show && _fade.value == 0) return const SizedBox.shrink();
        return ExcludeSemantics(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Opacity(
              opacity: _fade.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, _offset.value),
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _style(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
