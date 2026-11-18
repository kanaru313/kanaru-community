import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/src/foundation/result.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/platform/domain/file_manager.dart';

final enL10n = AppLocalizationsEn();

MenuEnv menuEnv() =>
    MenuEnv(l10n: enL10n, canReveal: true, pathOf: (_) => null);

/// Ids of the rows of [groups], group by group.
List<List<MenuItemId>> idsOf(List<List<MenuItemSpec>> groups) => [
  for (final g in groups) [for (final r in g) r.id],
];

/// The row [id] of the menu's main page or of its "Advanced" page.
MenuItemSpec rowOf(MenuSpec spec, MenuItemId id) => [
  for (final g in spec.groups) ...g,
  for (final g in spec.advanced) ...g,
].singleWhere((r) => r.id == id, orElse: () => throw StateError('no $id'));

bool hasRow(MenuSpec spec, MenuItemId id) => [
  for (final g in spec.groups) ...g,
  for (final g in spec.advanced) ...g,
].any((r) => r.id == id);

/// A file manager that shows nothing (the menu loader reads `canReveal`).
class NoFileManager implements FileManager {
  @override
  bool get canReveal => false;

  @override
  Future<Result<void, FileManagerError>> reveal(String absolutePath) async =>
      const Ok(null);
}
