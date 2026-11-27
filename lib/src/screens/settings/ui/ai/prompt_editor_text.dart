import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../ai/domain/settings/tool_groups.dart';
import '../../../../ai/domain/variables/template_analysis.dart';
import '../../../../ai/domain/variables/variable_catalog.dart';
import 'ai_catalog_labels.dart';

/// The sample value a variable shows in the preview (the song Lạc trôi, never
/// the playing song). Long data is a short tag, not pasted.
String promptSampleText(AppLocalizations l10n, AiVariable variable) =>
    switch (variable) {
      AiVariable.nowPlaying => l10n.aiSetEdSampleNowPlaying,
      AiVariable.title => l10n.aiSetEdSampleTitle,
      AiVariable.artist => l10n.aiSetEdSampleArtist,
      AiVariable.album => l10n.aiSetEdSampleAlbum,
      AiVariable.lyrics => l10n.aiSetEdSampleLyrics,
      AiVariable.queue => l10n.aiSetEdSampleQueue,
      AiVariable.input => l10n.aiSetEdSampleInput,
    };

/// The Settings name of a tool group, as the Tools block shows it.
String promptToolGroupName(AppLocalizations l10n, AiToolGroup group) =>
    switch (group) {
      AiToolGroup.nowPlaying => l10n.aiSetToolNowPlaying,
      AiToolGroup.queue => l10n.aiSetToolQueue,
      AiToolGroup.librarySearch => l10n.aiSetToolLibrarySearch,
      AiToolGroup.lyrics => l10n.aiSetToolLyrics,
      AiToolGroup.trackInfo => l10n.aiSetToolTrackInfo,
      AiToolGroup.listeningStats => l10n.aiSetToolListeningStats,
      AiToolGroup.playlists => l10n.aiSetToolPlaylists,
      AiToolGroup.playControl => l10n.aiSetToolPlayControl,
      AiToolGroup.queueEdit => l10n.aiSetToolQueueEdit,
      AiToolGroup.playlistCreate => l10n.aiSetToolPlaylistCreate,
      AiToolGroup.playlistEdit => l10n.aiSetToolPlaylistEdit,
    };

/// What the line under the Prompt field says about the variables: an error
/// (unknown variable, red, Save off), a warning (tool group off, yellow, Save
/// on) or nothing.
sealed class PromptLine {
  const PromptLine();
}

class PromptLineError extends PromptLine {
  const PromptLineError(this.text);
  final String text;
}

class PromptLineWarning extends PromptLine {
  const PromptLineWarning(this.text);
  final String text;
}

/// An error beats a warning; [bypass] is the "variables still sent when the
/// tool is off" switch.
PromptLine? promptLine(
  AppLocalizations l10n,
  TemplateAnalysis analysis, {
  required bool bypass,
}) {
  final unknown = _distinct(analysis.unknown.map((s) => '{{${s.name}}}'));
  if (unknown.isNotEmpty) {
    return PromptLineError(
      l10n.aiSetEdUnknown(
        unknown.join(', '),
        variableCatalog.map(variableToken).join(' '),
      ),
    );
  }
  final off = analysis.groupOff.toList();
  if (off.isEmpty) return null;
  final names = _distinct(off.map((s) => variableToken(s.variable!)))
      .join(', ');
  final groups = _distinct(
    off.map((s) => '“${promptToolGroupName(l10n, s.variable!.group!)}”'),
  ).join(', ');
  final setting = l10n.aiSetVarBypassTitle;
  return PromptLineWarning(
    bypass
        ? l10n.aiSetEdGroupOffBypass(names, groups, setting)
        : l10n.aiSetEdGroupOff(names, groups, setting),
  );
}

List<String> _distinct(Iterable<String> items) => items.toSet().toList();
