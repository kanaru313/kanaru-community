import 'package:flutter_test/flutter_test.dart';
import 'package:kanaru/l10n/gen/app_localizations_en.dart';
import 'package:kanaru/src/ai/domain/conversation/parts.dart';
import 'package:kanaru/src/ai/domain/conversation/track_ref_snapshot.dart';
import 'package:kanaru/src/ai/ui/composer/chip_labels.dart';

final _l10n = AppLocalizationsEn();

void main() {
  test('a cut selection chip shows the real count, not the ids sent', () {
    const chip = ChipPart(
      kind: ChipKind.songs,
      label: '250',
      tracks: [
        TrackRefSnapshot(trackId: 1, title: ''),
        TrackRefSnapshot(trackId: 2, title: ''),
      ],
    );

    expect(chipLabel(_l10n, chip), _l10n.aiChatChipSongs(250));
  });

  test('a whole selection chip counts its ids', () {
    const chip = ChipPart(
      kind: ChipKind.songs,
      tracks: [
        TrackRefSnapshot(trackId: 1, title: ''),
        TrackRefSnapshot(trackId: 2, title: ''),
      ],
    );

    expect(chipLabel(_l10n, chip), _l10n.aiChatChipSongs(2));
  });

  test('the now playing chip names the song when it is known', () {
    const chip = ChipPart(kind: ChipKind.nowPlaying, label: 'Lạc trôi');

    expect(chipLabel(_l10n, chip), 'Now playing: Lạc trôi');
  });

  test('the now playing chip falls back to its plain name', () {
    const bare = ChipPart(kind: ChipKind.nowPlaying);
    const empty = ChipPart(kind: ChipKind.nowPlaying, label: '');

    expect(chipLabel(_l10n, bare), _l10n.aiChatChipNowPlaying);
    expect(chipLabel(_l10n, empty), _l10n.aiChatChipNowPlaying);
  });
}
