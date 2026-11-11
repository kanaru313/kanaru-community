import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/menus/menu_model.dart';
import 'package:kanaru/src/library/ui/menus/selection_menu.dart';
import 'package:kanaru/src/media/domain/play_context.dart';

import 'menu_fixtures.dart';

MenuSpec _menu({bool allFavorite = false, int count = 4}) => buildSelectionMenu(
  SelectionMenuData(
    ids: trackIds(count),
    durationMs: 720000,
    allFavorite: allFavorite,
  ),
  env(),
);

void main() {
  test('header, rows and queue ids', () {
    final spec = _menu();
    expect(spec.header.title, '4 songs selected');
    expect(spec.header.subtitle, '12 min');
    expect(rowIds(spec.groups), [
      MenuItemId.shuffle,
      MenuItemId.favorite,
      MenuItemId.ai,
      MenuItemId.advanced,
    ]);
    expect(rowIds(spec.advanced), [MenuItemId.hide, MenuItemId.delete]);
    expect(spec.queueIds, trackIds(4));
    expect(rowOf(spec, MenuItemId.delete).subtitle, '4 files');
    expect(rowOf(spec, MenuItemId.ai).pro, isTrue);
  });

  test('shuffle plays the selection in a selection context', () {
    final action = rowOf(_menu(), MenuItemId.shuffle).action as PlayAction;
    expect(action.shuffle, isTrue);
    expect(action.ids, trackIds(4));
    expect(action.context.kind, PlayContextKind.selection);
  });

  test('favorite adds, or removes when all are favorites', () {
    expect(
      rowOf(_menu(), MenuItemId.favorite).action,
      MenuAction.favorite(trackIds(4), on: true),
    );
    final all = rowOf(_menu(allFavorite: true), MenuItemId.favorite);
    expect(all.action, MenuAction.favorite(trackIds(4), on: false));
    expect(all.title, 'Remove from favorites');
  });
}
