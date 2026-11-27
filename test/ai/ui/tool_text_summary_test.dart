import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';
import 'package:kanaru/src/ai/ui/tool_text.dart';

void main() {
  final en = AppLocalizationsEn();
  final vi = AppLocalizationsVi();

  test('a complete list shows shown / total without the hint', () {
    expect(
      toolSummary(en, 'search_library', '{"total":2,"items":["1|a","2|b"]}'),
      '2 / 2 songs',
    );
    expect(
      toolSummary(vi, 'search_library', '{"total":2,"items":["1|a","2|b"]}'),
      '2 / 2 bài',
    );
  });

  test('a list with more rows than returned says the AI can look further', () {
    expect(
      toolSummary(vi, 'search_library', '{"total":1284,"items":["1|a","2|b"]}'),
      '2 / 1.284 bài · AI có thể xem tiếp',
    );
  });

  test('a list without a total shows the count; other text its first line', () {
    expect(toolSummary(vi, 'search_library', '{"items":["1|a"]}'), '1 bài');
    expect(toolSummary(vi, 'search_library', 'Đã xong\nchi tiết'), 'Đã xong');
    expect(toolSummary(vi, 'search_library', ''), '');
  });

  test('a list of something else than songs does not say songs', () {
    const playlists = '{"total":5,"items":["0|Favorites|3","1|Gym|9"]}';
    expect(
      toolSummary(en, 'list_playlists', playlists),
      '2 / 5 items · the AI can look further',
    );
    expect(
      toolSummary(
        vi,
        'list_playlists',
        '{"total":2,"items":["0|A|3","1|B|9"]}',
      ),
      '2 / 2 mục',
    );
    expect(toolSummary(vi, 'list_playlists', '{"items":["0|A|3"]}'), '1 mục');
    expect(toolSummary(en, 'list_playlists', '{"items":["0|A|3"]}'), '1 item');
  });
}
