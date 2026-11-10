import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Lets a shell add widgets to every `PageHeader` below it without each page
/// passing them: [trailing] on every page (for example the desktop search
/// icon), [leading] and [rootTrailing] only on root pages (no back button),
/// for example the mobile `[☰] Title [✦] [⚙]` header.
class PageHeaderScope extends InheritedWidget {
  const PageHeaderScope({
    super.key,
    this.trailing = const [],
    this.leading,
    this.rootTrailing = const [],
    required super.child,
  });

  /// Shown after the page's own actions on every page.
  final List<Widget> trailing;

  /// Shown before the title, only on a root page.
  final Widget? leading;

  /// Shown after [trailing], only on a root page.
  final List<Widget> rootTrailing;

  static PageHeaderScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageHeaderScope>();

  @override
  bool updateShouldNotify(PageHeaderScope oldWidget) =>
      !listEquals(trailing, oldWidget.trailing) ||
      leading != oldWidget.leading ||
      !listEquals(rootTrailing, oldWidget.rootTrailing);
}
