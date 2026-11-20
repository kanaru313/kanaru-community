import 'dart:async';

import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../domain/history/history_models.dart';
import '../../../state/browse/selection_providers.dart';
import '../../browse/library_list_scaffold.dart' show libraryRowGutter;
import '../../menus/menu_model.dart';
import '../../menus/more_button.dart';
import '../../menus/open_menu.dart';
import '../history_remove_toast.dart';
import 'track_history_labels.dart';

/// Every play of one song as a list of rows, newest first.
Widget trackHistoryRows(List<HistoryPlay> plays, DateTime today) =>
    SliverList.builder(
      itemCount: plays.length,
      findChildIndexCallback: (key) {
        if (key is! ValueKey<String>) return null;
        final i = plays.indexWhere((p) => p.uid == key.value);
        return i < 0 ? null : i;
      },
      itemBuilder: (context, i) => Padding(
        key: ValueKey(plays[i].uid),
        padding: EdgeInsets.fromLTRB(
          libraryRowGutter(context),
          0,
          libraryRowGutter(context),
          KSpace.x1,
        ),
        child: TrackHistoryRow(play: plays[i], today: today),
      ),
    );

/// One play of the song: when it began and how long it was listened to.
///
/// A play is not playable, so a tap does nothing while no song is selected.
/// A long press selects the song (as a song row does), and every row of the
/// page then shows selected; a tap while something is selected toggles the
/// song. ⋮, right click, the Menu key and the Delete key remove the play (the
/// merged Undo toast).
class TrackHistoryRow extends ConsumerWidget {
  const TrackHistoryRow({super.key, required this.play, required this.today});

  final HistoryPlay play;

  /// The local day the page is on, which names the day of the play.
  final DateTime today;

  void _remove(BuildContext context) =>
      unawaited(removeHistoryPlay(context, play));

  void _menu(BuildContext context, {required bool viaKeyboard}) {
    final l10n = AppLocalizations.of(context);
    unawaited(
      openMenu(context, (container, env) async {
        return MenuSpec(
          header: MenuHeader(
            image: MenuImage.tile,
            tileIcon: KIcons.history,
            seed: play.uid,
            title: trackPlayWhen(env.l10n, play.playedAt, today),
          ),
          groups: [
            [
              MenuItemSpec(
                MenuItemId.delete,
                icon: KIcons.delete,
                title: l10n.historyMenuRemovePlay,
                danger: true,
                action: MenuAction.run((ctx) => removeHistoryPlay(ctx, play)),
              ),
            ],
          ],
        );
      }, viaKeyboard: viaKeyboard),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = play.track.id;
    final selected = ref.watch(isSelectedProvider(id));
    final selecting = ref.watch(hasSelectionProvider);
    final listened = trackPlayListened(l10n, play.listenedMs);
    final when = trackPlayWhen(l10n, play.playedAt, today);
    return KContextRegion(
      longPressOpens: false,
      onOpen: (at) => _menu(context, viaKeyboard: at == null),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.delete) {
            _remove(context);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onLongPress: selected
              ? null
              : () {
                  unawaited(HapticFeedback.selectionClick());
                  ref.read(librarySelectionProvider.notifier).toggle(id);
                },
          child: Semantics(
            // One node: the label says the whole row and the removal is a
            // custom action, so the row is not announced as a button that
            // does nothing. The ⋮ inside stays out of the way.
            excludeSemantics: true,
            label: [when, ?listened].join(', '),
            selected: selected,
            customSemanticsActions: {
              CustomSemanticsAction(label: l10n.historyMenuRemovePlay): () =>
                  _remove(context),
            },
            child: KListRow(
              selected: selected,
              // A row with no tap is not a keyboard stop, and the Delete and
              // Menu keys need one: the tap is a no-op unless selecting.
              onTap: () {
                if (selecting) {
                  ref.read(librarySelectionProvider.notifier).toggle(id);
                }
              },
              title: Text(when, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: listened == null ? null : Text(listened),
              trailing: LibraryMoreButton(
                onPressed: ({required viaKeyboard}) =>
                    _menu(context, viaKeyboard: viaKeyboard),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
