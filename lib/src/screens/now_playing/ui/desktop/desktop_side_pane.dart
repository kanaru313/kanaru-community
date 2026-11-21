import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../lyrics/ui/lyrics_body.dart';
import '../../state/desktop_view.dart';

/// Second column of the split body (or the only one): the lyrics, titled like
/// a tab but with no other tab (the queue lives in the shell's right panel).
class DesktopSidePane extends ConsumerWidget {
  const DesktopSidePane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 12, 0),
          child: SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: DefaultTabController(
                length: 1,
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  tabs: [Tab(text: l10n.playbackTabLyrics)],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: LyricsBody(
            surface: KLyricsSurface.tab,
            coverColumnShown: ref.watch(coverColumnShownProvider),
          ),
        ),
      ],
    );
  }
}
