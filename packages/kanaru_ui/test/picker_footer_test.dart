import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'support/host.dart';

Widget _footer() => Column(
  mainAxisAlignment: MainAxisAlignment.end,
  mainAxisSize: MainAxisSize.min,
  children: [
    PickerFooter(
      buttons: [
        TextButton(onPressed: () {}, child: const Text('Cancel')),
        const FilledButton(onPressed: null, child: Text('Save')),
      ],
    ),
  ],
);

void main() {
  testWidgets('desktop footer: 24 sides, 12 top, 16 bottom', (tester) async {
    useWindow(tester, const Size(1300, 800));
    await tester.pumpWidget(host(_footer()));
    final band = tester.getRect(find.byType(PickerFooter));
    final save = tester.getRect(find.byType(FilledButton));
    expect(band.right - save.right, KSpace.x6);
    // The button is 40 dp inside a 48 dp tap target: 12 + 16 band padding.
    expect(band.bottom - save.bottom, KSpace.x4);
  });

  testWidgets('mobile footer keeps its compact band', (tester) async {
    useWindow(tester, const Size(400, 800));
    await tester.pumpWidget(host(_footer()));
    final band = tester.getRect(find.byType(PickerFooter));
    final save = tester.getRect(find.byType(FilledButton));
    expect(band.right - save.right, KSpace.x4);
    expect(band.bottom - save.bottom, KSpace.x1);
  });

  testWidgets('disabled filled button keeps the theme colours', (tester) async {
    await tester.pumpWidget(host(_footer()));
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(button.style, isNull);
  });
}
