import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/screens/first_run/ui/folder_actions.dart';
import 'package:flutter/widgets.dart' show Locale;

void main() {
  test('baseName falls back to the path for /', () {
    expect(baseName('/'), '/');
    expect(baseName('/a/b/'), 'b');
    expect(baseName('/a/b'), 'b');
  });

  test('topLevelPicks puts parents first and drops nested picks', () {
    expect(
      topLevelPicks(['/m/Rock', '/m', '/x/y', '/x/y/z', '/mm']),
      unorderedEquals(['/m', '/x/y', '/mm']),
    );
    expect(topLevelPicks(['/m/Rock', '/m']).first, '/m');
    expect(topLevelPicks(const []), isEmpty);
  });

  test('English counts use plurals', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.scanSetupFolderSongs(1), '1 song');
    expect(en.scanSetupFolderSongs(2), '2 songs');
    expect(
      en.scanSetupFoldersHintCount(1),
      'Kanaru scans these folders · about 1 song',
    );
    expect(
      lookupAppLocalizations(const Locale('vi')).scanSetupFolderSongs(1),
      '1 bài',
    );
  });
}
