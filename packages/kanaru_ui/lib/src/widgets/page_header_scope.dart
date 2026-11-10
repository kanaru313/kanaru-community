import 'package:material_ui/material_ui.dart';

/// Lets a shell add trailing widgets (for example the desktop search icon) to
/// every `PageHeader` below it without each page passing them.
class PageHeaderScope extends InheritedWidget {
  const PageHeaderScope({
    super.key,
    required this.trailing,
    required super.child,
  });

  final List<Widget> trailing;

  static PageHeaderScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageHeaderScope>();

  @override
  bool updateShouldNotify(PageHeaderScope oldWidget) =>
      !identical(trailing, oldWidget.trailing);
}
