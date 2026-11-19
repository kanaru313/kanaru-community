import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/platform/ui/image_drop_target.dart';
import 'package:path/path.dart' as p;

void main() {
  test('first regular file wins; folders and missing paths are skipped', () {
    final tmp = Directory.systemTemp.createTempSync('drop_test');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final dir = Directory(p.join(tmp.path, 'folder'))..createSync();
    final file = File(p.join(tmp.path, 'a.png'))..createSync();

    final picked = firstDroppedFile([
      '',
      p.join(tmp.path, 'missing.png'),
      dir.path,
      file.path,
    ])!;
    expect(picked.file.path, file.path);
    expect(picked.name, 'a.png');
    expect(picked.temporary, isFalse);
    expect(firstDroppedFile([dir.path]), isNull);
  });

  testWidgets('off Linux it renders just the child', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ImageDropTarget(
          isLinux: false,
          onDrop: (_) {},
          child: const Text('child'),
        ),
      ),
    );
    expect(find.text('child'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ImageDropTarget),
        matching: find.byType(DropTarget),
      ),
      findsNothing,
    );
  });
  // The Linux DropTarget path needs the native desktop_drop plugin: not tested.
}
