import 'package:go_router/go_router.dart';
import 'package:kanaru/kanaru.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

/// A small synthetic navigation for shell and router mechanics tests: no
/// built-in label or page text is involved.
///
/// Mobile bar: Alpha, Beta, Gamma (Gamma's `mobileOrder` puts it before Beta).
/// Sidebar bands: Alpha (0), Beta (1), Gamma + Soon (2), Gear (footer, pushed).
class NavFixture implements KanaruExtension {
  const NavFixture();

  @override
  String get id => 'nav-fixture';

  @override
  void register(ExtensionRegistry r) {
    NavItem item(
      String id,
      String path,
      int order, {
      bool mobileTab = true,
      bool footer = false,
      bool pushed = false,
      bool comingSoon = false,
      int? mobileOrder,
    }) => NavItem(
      id: id,
      path: path,
      icon: KIcons.placeholder,
      selectedIcon: KIcons.placeholder,
      label: (_) => id[0].toUpperCase() + id.substring(1),
      order: order,
      mobileTab: mobileTab,
      footer: footer,
      pushed: pushed,
      comingSoon: comingSoon,
      mobileOrder: mobileOrder,
    );
    GoRoute page(String path) => GoRoute(
      path: path,
      builder: (_, _) => Scaffold(
        body: Column(
          children: [
            PageHeader(title: 'header $path'),
            Text('page $path'),
          ],
        ),
      ),
    );

    r
      ..addNavItem(item('alpha', '/', 10))
      ..addNavItem(item('beta', '/beta', 110))
      ..addNavItem(item('gamma', '/gamma', 210, mobileOrder: 105))
      ..addNavItem(
        item('soon', '/soon', 220, mobileTab: false, comingSoon: true),
      )
      ..addNavItem(
        item(
          'gear',
          '/gear',
          900,
          mobileTab: false,
          footer: true,
          pushed: true,
        ),
      )
      ..addRoute(page('/'))
      ..addRoute(page('/beta'))
      ..addRoute(page('/gamma'))
      ..addRoute(page('/gear'))
      ..addRoute(page('/search'));
  }
}
