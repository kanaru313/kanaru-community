import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../lyrics/state/online/lyrics_sources_provider.dart';
import '../../settings_routes.dart';
import '../settings_scaffold.dart';
import 'lyrics_display_section.dart';
import 'lyrics_find_section.dart';
import 'lyrics_soon_sections.dart';
import 'lyrics_sources_section.dart';
import 'lyrics_translation_section.dart';

/// Settings › Lyrics: live pickers and switches, the online sources, the
/// translation defaults, and a "coming soon" row for everything that waits
/// for the engine.
///
/// `?focus=sources` scrolls to the online sources and `?focus=translation` to
/// the translation block, pulsing it once; on desktop the keyboard focus
/// moves to its first row.
class LyricsSettingsPage extends ConsumerStatefulWidget {
  const LyricsSettingsPage({super.key});

  @override
  ConsumerState<LyricsSettingsPage> createState() => _LyricsSettingsPageState();
}

/// One beat of a wait loop.
const _beat = Duration(milliseconds: 50);

/// Beats to wait for the sources rows (about two seconds).
const _rowsBeats = 40;

/// Steps of the scroll down to a lazily built section.
const _scrollSteps = 60;

/// Beats at the end of the list before it is believed to be the end.
const _endBeats = 3;

class _LyricsSettingsPageState extends ConsumerState<LyricsSettingsPage> {
  /// Always built (first section): finds the page's scrollable.
  final _topKey = GlobalKey();
  final _sourcesKey = GlobalKey();
  final _sourcesPulse = GlobalKey<SetupSectionPulseState>();
  final _translationKey = GlobalKey();
  final _translationPulse = GlobalKey<SetupSectionPulseState>();

  /// The block the location asks for (`focus` value): its key and pulse.
  String _focus = '';
  Timer? _settle;

  /// Counts the reveals: a newer one makes an older, still running one stop.
  int _generation = 0;

  /// The location already revealed, so a rebuild never scrolls again.
  String? _handled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uri = GoRouterState.of(context).uri;
    final focus = uri.queryParameters['focus'] ?? '';
    if (focus != 'sources' && focus != 'translation') {
      // A later visit with the param on this same page scrolls again.
      _handled = null;
      return;
    }
    final location = uri.toString();
    if (_handled == location) return;
    _handled = location;
    _focus = focus;
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
  Future<BuildContext?> _targetContext(GlobalKey key, int generation) async {
    // Rows that just appeared have not been laid out yet: the end of the list
    // is only believed after a few beats at it.
    var atEnd = 0;
    ScrollPosition? position;
    for (var i = 0; i < _scrollSteps && mounted; i++) {
      if (generation != _generation) return null;
      final target = key.currentContext;
      if (target != null) return target;
      // The first section scrolls out of the lazy list: keep its scrollable.
      final top = _topKey.currentContext;
      if (position == null && top != null && top.mounted) {
        position = Scrollable.maybeOf(top)?.position;
      }
      if (position == null) return null;
      if (position.pixels >= position.maxScrollExtent) {
        if (++atEnd > _endBeats) return null;
        await Future<void>.delayed(_beat);
        continue;
      }
      atEnd = 0;
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

  /// The sources rows decide the height of everything under them: scroll only
  /// once they exist (a page with no plugin stream value still goes on after
  /// about two seconds).
  Future<void> _waitForRows(int generation) async {
    for (var i = 0; i < _rowsBeats && mounted; i++) {
      if (generation != _generation) return;
      if (ref.read(lyricsSourcesLoadedProvider)) return;
      await Future<void>.delayed(_beat);
    }
  }

  Future<void> _reveal() async {
    final generation = ++_generation;
    bool stale() => !mounted || generation != _generation;
    final sources = _focus == 'sources';
    // The sources rows sit above the translation block: their height moves it.
    await _waitForRows(generation);
    if (stale()) return;
    final target = await _targetContext(
      sources ? _sourcesKey : _translationKey,
      generation,
    );
    if (!mounted || target == null || stale() || !target.mounted) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    await Scrollable.ensureVisible(
      target,
      alignment: 0.1,
      duration: reduce ? Duration.zero : KMotion.slow,
      curve: KMotion.emphasized,
    );
    if (!mounted || stale() || !target.mounted) return;
    (sources ? _sourcesPulse : _translationPulse).currentState?.pulse();
    if (FormFactor.of(context) == FormFactor.desktop) _focusFirstRow(target);
  }

  /// Desktop: the keyboard focus goes to the first focusable row of the block.
  void _focusFirstRow(BuildContext block) {
    for (final node in FocusScope.of(block).traversalDescendants) {
      final context = node.context;
      if (context == null) continue;
      var inside = false;
      context.visitAncestorElements((e) {
        inside = e == block;
        return !inside;
      });
      if (inside) {
        node.requestFocus();
        return;
      }
    }
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
        lyricsWhereSection(context),
        KeyedSubtree(
          key: _translationKey,
          child: SetupSectionPulse(
            key: _translationPulse,
            child: const LyricsTranslationSection(),
          ),
        ),
        lyricsSpeechSection(context),
      ],
    );
  }
}
