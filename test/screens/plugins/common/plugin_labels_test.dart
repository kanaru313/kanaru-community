import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
import 'package:kanaru/src/plugins/state/store_filter.dart';
import 'package:kanaru/src/screens/plugins/common/plugin_labels.dart';

void main() {
  test('ai-chat row has the Trò chuyện AI chip', () async {
    final vi = await AppLocalizations.delegate.load(const Locale('vi'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(kindLabel(vi, PluginKind.aiChat), 'Trò chuyện AI');
    expect(kindLabel(en, PluginKind.aiChat), 'AI chat');
  });

  test('kind noun phrase keeps the AI acronym', () async {
    final vi = await AppLocalizations.delegate.load(const Locale('vi'));
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(kindPluginLabel(vi, PluginKind.aiChat), 'Plugin AI');
    expect(kindPluginLabel(en, PluginKind.aiChat), 'AI plugin');
    expect(kindPluginLabel(vi, PluginKind.lyrics), 'Plugin lời bài');
    expect(kindPluginLabel(vi, null), isNull);
  });

  test('every kind has a chip label and help', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    for (final kind in PluginKind.values) {
      expect(kindLabel(en, kind), isNotNull, reason: kind.wire);
    }
    for (final g in StoreKindGroup.values) {
      expect(kindGroupHelp(en, g), isNotEmpty);
    }
  });

  test(
    'seek bar is the last kind, cosmetic, with its label, noun and help',
    () async {
      final vi = await AppLocalizations.delegate.load(const Locale('vi'));
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(StoreKindGroup.values.last, StoreKindGroup.seekbar);
      expect(StoreKindGroup.seekbar.isCosmetic, isTrue);
      expect(StoreKindGroup.values.where((g) => g.isCosmetic), [
        StoreKindGroup.seekbar,
      ]);
      expect(kindLabel(vi, PluginKind.seekbar), 'Thanh tua');
      expect(kindLabel(en, PluginKind.seekbar), 'Seek bar');
      expect(kindPluginLabel(vi, PluginKind.seekbar), 'Plugin thanh tua');
      expect(kindPluginLabel(en, PluginKind.seekbar), 'Seek bar plugin');
      expect(
        kindGroupHelp(vi, StoreKindGroup.seekbar),
        'Đổi cách vẽ thanh tua ở Now Playing và màn lời.',
      );
    },
  );

  test('the default Loại chips are exactly the functional kinds', () {
    final functional = {
      for (final g in StoreKindGroup.values)
        if (!g.isCosmetic) ...g.kinds,
    };
    expect(defaultStoreKinds, functional);
    expect(defaultStoreKinds, isNot(contains(PluginKind.seekbar)));
  });
}
