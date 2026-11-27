import '../chat_session.dart';
import 'composer_view.dart';

/// Sends [text] through [session] and records what a refusal leaves for the
/// composer to show: nothing was sent and the text stays where it was.
///
/// A blocked send (readiness) and a busy one need no note of their own: the
/// readiness notice is already on screen, and a busy turn keeps the text.
Future<SendResult> sendFromComposer({
  required ChatSessionController session,
  required ComposerSendNotice notice,
  required String text,
  bool shortVersion = false,
}) async {
  final result = await session.send(text, shortVersion: shortVersion);
  recordSendResult(notice, result);
  return result;
}

/// Records what [result] leaves for the composer to show. Split from
/// [sendFromComposer] so a caller that writes the field after a refusal can
/// record the note afterwards (editing the field ends the note).
void recordSendResult(ComposerSendNotice notice, SendResult result) {
  switch (result) {
    case SendSent():
      notice.clear();
    case SendMissingData(:final issues):
      notice.set(NoticeMissingData(issues));
    case SendOversize(:final variables):
      notice.set(NoticeOversize(variables));
    case SendFailed():
      notice.set(const NoticeSendFailed());
    case SendBlocked() || SendBusy():
      break;
  }
}
