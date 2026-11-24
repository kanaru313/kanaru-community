import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kanaru_ui/kanaru_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../l10n/gen/app_localizations.dart';
import '../../../../lyrics/domain/translation/translation_language.dart';
import '../../../../lyrics/state/translation/translation_commands.dart';
import '../../../../lyrics/state/translation/translation_engine_providers.dart'
    show translationAppLanguageProvider;
import '../../../../lyrics/state/translation/translation_services_provider.dart';
import '../../../../lyrics/state/translation/translation_settings.dart';
import '../../../../lyrics/ui/translation/modal/translate_service_row.dart'
    show TranslateServiceIcon;
import '../../../../lyrics/ui/translation/translation_language_name.dart';
import '../../../../plugins/domain/package/translate_spec.dart'
    show translationLanguageCodes;
import '../../../../plugins/state/plugin_run_provider.dart'
    show pluginPauseProvider;
import '../../../../plugins/state/plugin_store_providers.dart'
    show pluginConfigStatusProvider;

/// The visible caption under a picker title (no ⓘ in pickers).
class _PickerCaption extends StatelessWidget {
  const _PickerCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(KSpace.x4, 0, KSpace.x4, KSpace.x2),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      child: Text(text),
    ),
  );
}

/// "Dịch vụ dịch mặc định": the line under the title is the chosen plugin's
/// icon and name, "Chưa chọn" when none is (also when the chosen plugin was
/// removed), and in red the full sentence of its problem. A tap opens the
/// installed translate plugins as icon rows; the choice applies at once.
class TranslationServiceRow extends ConsumerStatefulWidget {
  const TranslationServiceRow({super.key});

  @override
  ConsumerState<TranslationServiceRow> createState() =>
      _TranslationServiceRowState();
}

class _TranslationServiceRowState extends ConsumerState<TranslationServiceRow> {
  final _anchor = GlobalKey();

  Future<void> _pick(TranslateServices services) async {
    // Taken before the await: the picker may outlive this row.
    final commands = ref.read(translationCommandsProvider);
    final l10n = AppLocalizations.of(context);
    final current = services.current?.installId;
    final chosen = await showSelectionPicker<String>(
      context,
      anchor: _anchor,
      anchorAlign: KAnchorAlign.end,
      title: Text(l10n.lyricsSettingsTrService),
      header: _PickerCaption(l10n.lyricsTranslateServiceSent),
      selected: current,
      options: [
        for (final s in services.all)
          SelectionOption<String>(
            value: s.installId,
            leading: TranslateServiceIcon(service: s),
            title: Text(s.name),
            subtitle: s.ai ? Text(l10n.lyricsTranslateAiTag) : null,
          ),
      ],
    );
    if (chosen != null && chosen != current) await commands.setService(chosen);
  }

  /// The sentence for what is wrong with plugin [id], null when it is fine.
  String? _problem(AppLocalizations l10n, String id) {
    final status = ref.watch(pluginConfigStatusProvider(id));
    final paused = ref.watch(pluginPauseProvider(id));
    final value = status.value;
    if (status.hasError || (value != null && value.manifest == null)) {
      return l10n.pluginsPageBrokenTitle;
    }
    if (value != null && value.missingRequired.isNotEmpty) {
      return l10n.pluginsPageNeedsConfigBody(
        value.missingRequired.map((f) => f.title).join(', '),
      );
    }
    if (paused != null) {
      // Minutes left, rounded up, at least 1 (as the plugin page's band).
      final seconds = paused.difference(DateTime.now()).inSeconds;
      return l10n.pluginsPausedTitle(seconds <= 60 ? 1 : (seconds / 60).ceil());
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final async = ref.watch(translateServicesProvider);
    // Loading or a read error shows no value and does not open: "unknown"
    // must not read as "none".
    final services = async.value;
    final service = services?.current;
    final problem = service == null ? null : _problem(l10n, service.installId);
    return SetupValueRow(
      anchorKey: _anchor,
      icon: KIcons.extension,
      title: Text(l10n.lyricsSettingsTrService),
      value: services == null
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (service == null)
                  Text(l10n.lyricsSettingsTrServiceNone)
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TranslateServiceIcon(
                        service: service,
                        size: KIconSize.xs,
                      ),
                      const KGap(KSpace.x1),
                      Flexible(child: Text(service.name)),
                    ],
                  ),
                if (problem != null)
                  Text(problem, style: TextStyle(color: scheme.error)),
              ],
            ),
      // Nothing installed: an empty picker would say nothing; "Thêm dịch vụ
      // dịch" below is the way forward.
      onTap: services == null || services.none ? null : () => _pick(services),
    );
  }
}

/// "Ngôn ngữ dịch mặc định": the language songs without their own are
/// translated into. "Theo ngôn ngữ ứng dụng" (stored as no value) is first.
class TranslationTargetRow extends ConsumerStatefulWidget {
  const TranslationTargetRow({super.key});

  @override
  ConsumerState<TranslationTargetRow> createState() =>
      _TranslationTargetRowState();
}

class _TranslationTargetRowState extends ConsumerState<TranslationTargetRow> {
  final _anchor = GlobalKey();

  /// Stands for "follow the app language": a picker cannot return null.
  static const _followApp = '';

  Future<void> _pick(String? current, String appCode) async {
    final commands = ref.read(translationTargetProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final chosen = await showSelectionPicker<String>(
      context,
      anchor: _anchor,
      anchorAlign: KAnchorAlign.end,
      title: Text(l10n.lyricsSettingsTrTarget),
      header: _PickerCaption(l10n.lyricsSettingsTrTargetCaption),
      selected: current ?? _followApp,
      options: [
        SelectionOption<String>(
          value: _followApp,
          title: Text(
            l10n.lyricsSettingsTrTargetAppNamed(
              translationLanguageName(l10n, appCode),
            ),
          ),
        ),
        for (final code in translationLanguageCodes)
          SelectionOption<String>(
            value: code,
            title: Text(translationLanguageName(l10n, code)),
          ),
      ],
    );
    if (chosen == null || chosen == (current ?? _followApp)) return;
    await commands.set(chosen == _followApp ? null : chosen);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(translationTargetProvider);
    final appCode = appTarget(ref.watch(translationAppLanguageProvider));
    return SetupValueRow(
      anchorKey: _anchor,
      icon: KIcons.language,
      title: Text(l10n.lyricsSettingsTrTarget),
      value: Text(translationLanguageName(l10n, current ?? appCode)),
      onTap: () => _pick(current, appCode),
    );
  }
}
