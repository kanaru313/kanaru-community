import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations.dart';
import 'package:kanaru/src/ai/domain/settings/builtin_templates.dart';
import 'package:kanaru/src/ai/domain/variables/variable_catalog.dart';
import 'package:kanaru/src/screens/settings/ui/ai/ai_catalog_labels.dart';

void main() {
  final known = {for (final v in variableCatalog) v.name};
  final token = RegExp(r'\{\{([^{}]*)\}\}');

  for (final code in ['en', 'vi']) {
    final l10n = lookupAppLocalizations(Locale(code));

    test('$code: every builtin template has a label and a body', () {
      for (final key in BuiltinTemplateKeys.all) {
        final text = builtinTemplateText(l10n, key);
        expect(text, isNotNull, reason: key);
        expect(text!.label.trim(), isNotEmpty, reason: key);
        expect(text.body.trim(), isNotEmpty, reason: key);
        for (final m in token.allMatches(text.body)) {
          expect(known, contains(m.group(1)), reason: '$key: ${m.group(0)}');
        }
      }
    });

    test('$code: every variable has a description', () {
      for (final v in variableCatalog) {
        expect(variableDescription(l10n, v).trim(), isNotEmpty, reason: v.name);
      }
    });
  }

  test('bodies carry the variables the labels promise', () {
    final l10n = lookupAppLocalizations(const Locale('vi'));
    expect(
      builtinTemplateText(l10n, BuiltinTemplateKeys.explainLyrics)!.body,
      'Giải nghĩa lời bài {{now_playing}}: {{lyrics}}',
    );
    expect(
      builtinTemplateText(l10n, BuiltinTemplateKeys.moodPlaylist)!.body,
      'Tạo playlist cho tâm trạng: {{input}}',
    );
    expect(variableToken(variableCatalog.first), '{{now_playing}}');
  });

  test('an unknown key has no text', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(builtinTemplateText(l10n, 'custom_1'), isNull);
  });
}
