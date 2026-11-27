import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/plugins/domain/package/plugin_kind.dart';
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
}
