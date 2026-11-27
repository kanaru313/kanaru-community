import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/state/chat_attachments.dart';
import 'package:kanaru/src/ai/state/chat_providers.dart';
import 'package:kanaru/src/ai/state/chat_session.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_inputs.dart';
import 'package:kanaru/src/ai/state/chat_view/composer_view.dart';

class _IdleSession extends ChatSessionController {
  @override
  ChatSessionState build() => const ChatSessionState();
}

void main() {
  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        chatSessionProvider.overrideWith(_IdleSession.new),
        chatPluginsProvider.overrideWithValue(const AsyncData([])),
        composerSettingsProvider.overrideWithValue(
          ComposerSettings(enabledGroups: const {}, varBypass: false),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('a suggestion is not part of the view, an attached chip is', () {
    final c = container();
    c.listen(composerViewProvider, (_, _) {});
    final notifier = c.read(chatAttachmentsProvider.notifier);
    // Every tool group is off, so a now-playing chip is struck.
    const chip = ChipPart(kind: ChipKind.nowPlaying);

    notifier.setSuggestions(const [chip]);
    expect(c.read(composerViewProvider).notice, isNull);

    notifier.attach(chip);
    expect(c.read(composerViewProvider).notice, isA<NoticeStruckChip>());
  });
}
