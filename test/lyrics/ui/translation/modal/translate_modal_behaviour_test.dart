import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations_vi.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_failure.dart';
import 'package:kanaru/src/lyrics/domain/translation/translation_status.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_credit_provider.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_settings.dart';
import 'package:kanaru/src/lyrics/state/translation/translation_view.dart';
import 'package:kanaru/src/lyrics/ui/translation/modal/translate_retranslate.dart';
import 'package:kanaru/src/media/domain/track_id.dart';
import 'package:kanaru_ui/kanaru_ui.dart';

import 'translate_modal_host.dart';

const _map = {'Line 1': 'Dòng 1'};
const _ready = TranslationView(
  status: TranslationStatus.ready(),
  map: _map,
  installId: 'google',
);

Finder _button(String tooltip) => find.byWidgetPredicate(
  (w) => w is KIconButton && w.tooltip == tooltip,
  description: 'icon button $tooltip',
);

void main() {
  for (final (shell, size) in [
    ('mobile', const Size(400, 800)),
    ('desktop', const Size(1400, 900)),
  ]) {
    group(shell, () {
      testWidgets('the song changing closes the modal and its pages', (
        tester,
      ) async {
        final host = TranslateHost();
        await host.turnOn();
        await host.open(tester, size: size, followsPlaying: true);
        await tester.tap(find.text('Default for every song'));
        await host.settle(tester);
        expect(find.text('Translation service'), findsOneWidget);
        host.play(const TrackId(2));
        await host.settle(tester);
        expect(find.text('Translation service'), findsNothing);
        expect(find.text('Translate lyrics'), findsNothing);
      });

      testWidgets('playback stopping closes it too', (tester) async {
        final host = TranslateHost();
        await host.open(tester, size: size, followsPlaying: true);
        host.play(null);
        await host.settle(tester);
        expect(find.text('Translate lyrics'), findsNothing);
      });

      testWidgets('a song menu’s modal stays on its song', (tester) async {
        final host = TranslateHost();
        await host.open(tester, size: size);
        host.play(const TrackId(2));
        await host.settle(tester);
        expect(find.text('Translate lyrics'), findsOneWidget);
      });

      testWidgets('Esc closes the page first, then the modal', (tester) async {
        final host = TranslateHost();
        await host.turnOn();
        await host.open(tester, size: size);
        await tester.tap(find.text('Default for every song'));
        await host.settle(tester);
        await host.esc(tester);
        expect(find.text('Translation service'), findsNothing);
        expect(find.text('Translate lyrics'), findsOneWidget);
        await host.esc(tester);
        expect(find.text('Translate lyrics'), findsNothing);
      });

      testWidgets('Back follows the same order', (tester) async {
        final host = TranslateHost();
        await host.turnOn();
        await host.open(tester, size: size);
        await tester.tap(find.text('Default for every song'));
        await host.settle(tester);
        await tester.binding.handlePopRoute();
        await host.settle(tester);
        expect(find.text('Translation service'), findsNothing);
        expect(find.text('Translate lyrics'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await host.settle(tester);
        expect(find.text('Translate lyrics'), findsNothing);
      });

      testWidgets('⚙ goes to Settings › Lyrics', (tester) async {
        final host = TranslateHost();
        await host.open(tester, size: size);
        await tester.tap(_button('Translation settings'));
        await host.settle(tester);
        expect(host.location, '/settings/lyrics');
        expect(find.text('Translate lyrics'), findsNothing);
      });

      testWidgets('✕ closes the modal', (tester) async {
        final host = TranslateHost();
        await host.open(tester, size: size);
        await tester.tap(_button('Close'));
        await host.settle(tester);
        expect(find.text('Translate lyrics'), findsNothing);
        expect(host.location, '/');
      });

      testWidgets('the switch turns translation on and off', (tester) async {
        final handle = tester.ensureSemantics();
        final host = TranslateHost();
        await host.open(tester, size: size);
        expect(host.container.read(translationOnProvider), isFalse);
        await tester.tap(find.byType(KSwitch));
        await host.settle(tester);
        expect(host.container.read(translationOnProvider), isTrue);
        expect(find.text('Default for every song'), findsOneWidget);
        await tester.tap(find.byType(KSwitch));
        await host.settle(tester);
        expect(host.container.read(translationOnProvider), isFalse);
        expect(find.text('Default for every song'), findsNothing);
        handle.dispose();
      });

      testWidgets('[Below line | Replace line] sets how it shows', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        final host = TranslateHost();
        await host.turnOn();
        host.setView(_ready);
        await host.open(tester, size: size);
        bool selected(String label) =>
            isSemantics(isSelected: true)
                .matches(tester.getSemantics(find.bySemanticsLabel(label)), {});
        expect(selected('Below line'), isTrue);
        await tester.tap(find.text('Replace line'));
        await host.settle(tester);
        expect(
          host.container.read(translationDisplayProvider),
          TranslationDisplay.replace,
        );
        expect(selected('Replace line'), isTrue);
        // The translation is the line now, the original small above it.
        expect(find.text('Dòng 1'), findsOneWidget);
        expect(find.text('Line 1'), findsOneWidget);
        handle.dispose();
      });

      testWidgets('the target button opens the page with the target on it', (
        tester,
      ) async {
        final host = TranslateHost();
        await host.open(tester, size: size);
        await tester.tap(find.text('Vietnamese'));
        await host.settle(tester);
        expect(find.text('Translate into'), findsOneWidget);
      });

      testWidgets('⟳ translates again in the background and says when done', (
        tester,
      ) async {
        final host = TranslateHost();
        await host.turnOn();
        host.setView(_ready);
        host.setCredit(
          const TranslationCredit(plugin: 'Google Translate', target: 'vi'),
        );
        await host.open(tester, size: size);
        await tester.tap(_button('Translate again'));
        await host.settle(tester);
        expect(host.calls, ['retranslate']);
        expect(find.text('Translate lyrics'), findsNothing);
        // The run starts, then the new translation is there.
        host.setView(
          const TranslationView(
            status: TranslationStatus.loading(0, 1, background: true),
            map: _map,
            installId: 'google',
          ),
        );
        await tester.pump();
        expect(find.textContaining('Translated again'), findsNothing);
        host.setView(_ready);
        await tester.pump();
        await tester.pump();
        expect(
          find.text('Translated again · Google Translate'),
          findsOneWidget,
        );
      });

      testWidgets('a run that fails says nothing; the waiting ends', (
        tester,
      ) async {
        final host = TranslateHost();
        await host.turnOn();
        host.setView(_ready);
        host.setCredit(
          const TranslationCredit(plugin: 'Google Translate', target: 'vi'),
        );
        await host.open(tester, size: size);
        await tester.tap(_button('Translate again'));
        await host.settle(tester);
        host.setView(
          const TranslationView(
            status: TranslationStatus.loading(0, 1, background: true),
            map: _map,
            installId: 'google',
          ),
        );
        await tester.pump();
        host.setView(
          const TranslationView(
            status: TranslationStatus.failed(
              // Fails like any run: the lyrics show it, no toast.
              TranslationFailure.network(),
            ),
          ),
        );
        await tester.pump();
        expect(find.textContaining('Translated again'), findsNothing);
        await tester.pump(retranslateStartWait);
      });
    });
  }

  testWidgets('the preview shows the sung line, else the first with text', (
    tester,
  ) async {
    final host = TranslateHost();
    await host.turnOn();
    host.setView(_ready);
    await host.open(tester);
    // The playing line stub says line 1, and the track plays here.
    expect(find.text('Line 1'), findsOneWidget);
    expect(find.text('Line 0'), findsNothing);
    host.play(const TrackId(2));
    await tester.pump();
    expect(find.text('Line 0'), findsOneWidget);
  });

  test('Vietnamese strings are the mockup’s', () {
    final vi = AppLocalizationsVi();
    expect(vi.lyricsTranslateTitle, 'Dịch lời');
    expect(
      vi.lyricsTranslateSourceDetected('Tiếng Việt'),
      'Tiếng Việt · tự nhận',
    );
    expect(vi.lyricsTranslateSourceAuto, 'Tự nhận');
    expect(vi.lyricsTranslateServiceScope, 'Mặc định cho mọi bài');
    expect(
      vi.lyricsTranslateNetworkTitle('DeepL'),
      'Không kết nối được tới DeepL',
    );
    expect(
      vi.lyricsTranslatePausedLine('21:05'),
      'Máy chủ báo quá nhiều yêu cầu (429) · Kanaru dịch lại sau 21:05',
    );
    expect(vi.lyricsTranslatePartialTitle(6, 16), 'Mới dịch được 6/16 dòng');
    expect(
      vi.lyricsTranslateSame('Tiếng Việt', 'Google Translate'),
      'Lời bài hát đã là Tiếng Việt (theo Google Translate)',
    );
    expect(
      vi.lyricsTranslateServiceSent,
      'Lời, tên bài và nghệ sĩ được gửi tới plugin khi dịch.',
    );
    expect(
      vi.lyricsTranslateScopePro,
      'Chọn dịch vụ riêng cho bài hoặc hàng đợi: tính năng Pro',
    );
    expect(
      vi.lyricsTranslateNoteHelper('Gemini Translate'),
      'Lời dặn thêm cho mọi bài (lưu vào cài đặt của Gemini Translate).',
    );
    expect(vi.lyricsTranslateBarDiffTitle, 'Lựa chọn khác bản đang hiện');
  });
}
