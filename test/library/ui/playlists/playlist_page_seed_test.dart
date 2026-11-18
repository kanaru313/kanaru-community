import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/library/domain/playlists/playlist_ids.dart';
import 'package:kanaru/src/library/ui/playlists/playlist_page.dart';
import 'package:material_ui/material_ui.dart';

Future<AppLocalizations> _pump(WidgetTester tester, String uid) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PlaylistPage(uid: uid),
    ),
  );
  await tester.pump();
  return AppLocalizations.of(tester.element(find.byType(PlaylistPage)));
}

void main() {
  testWidgets('Favorites shows the Favorites title, not Playlists', (t) async {
    final l10n = await _pump(t, PlaylistUids.favorites);
    expect(find.text(l10n.libraryNavFavorites), findsWidgets);
    expect(find.text(l10n.navPlaylists), findsNothing);
    expect(find.text(l10n.appComingSoon), findsOneWidget);
  });

  testWidgets('an ordinary playlist shows the Playlists title', (t) async {
    final l10n = await _pump(t, '01HZZZZZZZZZZZZZZZZZZZZZZZ');
    expect(find.text(l10n.navPlaylists), findsWidgets);
    expect(find.text(l10n.libraryNavFavorites), findsNothing);
  });
}
