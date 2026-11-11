import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/library/ui/folders/folder_back.dart';
import 'package:kanaru/src/library/ui/folders/folder_locations.dart';

FolderLocation _at(String key) => FolderLocation(sourceUid: 's', key: key);

Future<bool> _canPop(
  WidgetTester tester, {
  required FolderLocation entry,
  required FolderLocation current,
  required FolderLocation? parent,
}) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: FolderBackGuard(
        parent: parent,
        entry: entry,
        current: current,
        filterOpen: false,
        child: const SizedBox(),
      ),
    ),
  );
  return tester
      .widget<PopScope<Object?>>(find.byWidgetPredicate((w) => w is PopScope))
      .canPop;
}

void main() {
  testWidgets('a page opened at a music folder root climbs, then leaves', (
    tester,
  ) async {
    final root = _at('');
    // Deep inside: Back climbs (the page does not pop).
    expect(
      await _canPop(tester, entry: root, current: _at('X/Y'), parent: _at('X')),
      isFalse,
    );
    // Back at the root level it was opened at: the page leaves.
    expect(
      await _canPop(tester, entry: root, current: root, parent: null),
      isTrue,
    );
    expect(
      await _canPop(
        tester,
        entry: root,
        current: root,
        parent: FolderLocation.top,
      ),
      isTrue,
    );
  });
}
