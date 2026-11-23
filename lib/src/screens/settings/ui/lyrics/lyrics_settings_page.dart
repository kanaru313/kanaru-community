import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../settings_routes.dart';
import '../settings_scaffold.dart';
import 'lyrics_display_section.dart';
import 'lyrics_find_section.dart';
import 'lyrics_soon_sections.dart';
import 'lyrics_sources_section.dart';

/// Settings › Lyrics: live pickers and switches, the online sources, and a
/// "coming soon" row for everything that waits for the engine.
///
/// `?focus=sources` scrolls to the online sources and pulses them once.
class LyricsSettingsPage extends StatefulWidget {
  const LyricsSettingsPage({super.key});

  @override
  State<LyricsSettingsPage> createState() => _LyricsSettingsPageState();
}

class _LyricsSettingsPageState extends State<LyricsSettingsPage> {
  /// Always built (first section): finds the page's scrollable.
  final _topKey = GlobalKey();
  final _sourcesKey = GlobalKey();
  final _sourcesPulse = GlobalKey<SetupSectionPulseState>();
  Timer? _settle;

  /// The location already revealed, so a rebuild never scrolls again.
  String? _handled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    if (uri.queryParameters['focus'] != 'sources') return;
    final location = uri.toString();
    if (_handled == location) return;
    _handled = location;
    _settle?.cancel();
    // The page may still be sliding in: wait for the first frame and a beat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _settle = Timer(KMotion.focusSettle, () => unawaited(_reveal()));
    });
  }

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  /// The list builds rows lazily: scroll down until the section exists.
  Future<BuildContext?> _targetContext() async {
    for (var i = 0; i < 40 && mounted; i++) {
      final target = _sourcesKey.currentContext;
      if (target != null) return target;
      final top = _topKey.currentContext;
      if (top == null || !top.mounted) return null;
      final position = Scrollable.maybeOf(top)?.position;
      if (position == null || position.pixels >= position.maxScrollExtent) {
        return null;
      }
      position.jumpTo(
        (position.pixels + position.viewportDimension / 2).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      await WidgetsBinding.instance.endOfFrame;
    }
    return null;
  }

  Future<void> _reveal() async {
    final target = await _targetContext();
    if (target == null || !mounted || !target.mounted) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    await Scrollable.ensureVisible(
      target,
      alignment: 0.1,
      duration: reduce ? Duration.zero : KMotion.slow,
      curve: KMotion.emphasized,
    );
    if (mounted) _sourcesPulse.currentState?.pulse();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsScaffold(
      title: l10n.settingsRootLyrics,
      parentPath: SettingsPaths.root,
      children: [
        KeyedSubtree(key: _topKey, child: const LyricsDisplaySection()),
        const LyricsFindSection(),
        KeyedSubtree(
          key: _sourcesKey,
          child: SetupSectionPulse(
            key: _sourcesPulse,
            child: const LyricsSourcesSection(),
          ),
        ),
        ...lyricsSoonSections(context),
      ],
    );
  }
}
