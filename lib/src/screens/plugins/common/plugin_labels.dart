import '../../../../l10n/gen/app_localizations.dart';
import '../../../library/domain/browse/language_names.dart';
import '../../../plugins/domain/install/repo_results.dart';
import '../../../plugins/domain/net/address_rules.dart';
import '../../../plugins/domain/package/plugin_kind.dart';
import '../../../plugins/state/store_filter.dart';

/// The kinds the store filters by, in list order. Translation and AI
/// translation are one entry ("Dịch"): the store does not tell them apart.
enum StoreKindGroup {
  lyrics({PluginKind.lyrics}),
  translate({PluginKind.translate, PluginKind.aiTranslate}),
  streaming({PluginKind.streaming}),
  aiChat({PluginKind.aiChat}),

  /// Last in every list; a cosmetic kind (see [isCosmetic]).
  seekbar({PluginKind.seekbar});

  const StoreKindGroup(this.kinds);

  final Set<PluginKind> kinds;

  /// Whether the kind only restyles the app: the store hides its
  /// uninstalled plugins until asked.
  bool get isCosmetic => cosmeticPluginKinds.containsAll(kinds);

  static StoreKindGroup? of(PluginKind? kind) {
    for (final group in values) {
      if (kind != null && group.kinds.contains(kind)) return group;
    }
    return null;
  }
}

String kindGroupLabel(AppLocalizations l10n, StoreKindGroup group) =>
    switch (group) {
      StoreKindGroup.lyrics => l10n.pluginsKindLyrics,
      StoreKindGroup.translate => l10n.pluginsKindTranslate,
      StoreKindGroup.streaming => l10n.pluginsKindStreaming,
      StoreKindGroup.aiChat => l10n.pluginsKindAiChat,
      StoreKindGroup.seekbar => l10n.pluginsKindSeekbar,
    };

/// One line saying what the kind is (the tooltip of its filter chip).
String kindGroupHelp(AppLocalizations l10n, StoreKindGroup group) =>
    switch (group) {
      StoreKindGroup.lyrics => l10n.pluginsKindHelpLyrics,
      StoreKindGroup.translate => l10n.pluginsKindHelpTranslate,
      StoreKindGroup.streaming => l10n.pluginsKindHelpStreaming,
      StoreKindGroup.aiChat => l10n.pluginsKindHelpAiChat,
      StoreKindGroup.seekbar => l10n.pluginsKindHelpSeekbar,
    };

/// The kind as a "Plugin …" noun phrase (install subtitle, plugin page).
String? kindPluginLabel(AppLocalizations l10n, PluginKind? kind) {
  final group = StoreKindGroup.of(kind);
  return switch (group) {
    StoreKindGroup.lyrics => l10n.pluginsKindNounLyrics,
    StoreKindGroup.translate => l10n.pluginsKindNounTranslate,
    StoreKindGroup.streaming => l10n.pluginsKindNounStreaming,
    StoreKindGroup.aiChat => l10n.pluginsKindNounAiChat,
    StoreKindGroup.seekbar => l10n.pluginsKindNounSeekbar,
    null => null,
  };
}

/// The kind chip of a row; null for a kind this app does not know.
String? kindLabel(AppLocalizations l10n, PluginKind? kind) {
  final group = StoreKindGroup.of(kind);
  return group == null ? null : kindGroupLabel(l10n, group);
}

/// A language key as a chip label: its own name plus the app-language name.
String languageLabel(AppLocalizations l10n, String code) {
  final names = languageNameOf(code);
  if (names == null) return code;
  final localized = l10n.localeName == 'vi' ? names.vi : names.en;
  return localized == names.native
      ? names.native
      : '${names.native} · $localized';
}

/// Why a repository's last fetch failed, a short phrase.
String repoLoadReason(AppLocalizations l10n, String? errorKind) {
  final error = RepoError.values.where((e) => e.name == errorKind).firstOrNull;
  return switch (error) {
    RepoError.network ||
    RepoError.timeout ||
    RepoError.cancelled ||
    null => l10n.pluginsLoadReasonNetwork,
    RepoError.badStatus => l10n.pluginsLoadReasonNotFound,
    RepoError.notACatalog ||
    RepoError.invalidUrl => l10n.pluginsLoadReasonInvalid,
    RepoError.tooLarge => l10n.pluginsLoadReasonTooLarge,
    RepoError.blocked || RepoError.needsHttps => l10n.pluginsLoadReasonBlocked,
    RepoError.duplicate ||
    RepoError.storageFailed => l10n.pluginsLoadReasonStorage,
  };
}

/// Whether a stored failure kind says the network was the problem.
bool isNetworkFailure(String? errorKind) =>
    errorKind == RepoError.network.name || errorKind == RepoError.timeout.name;

/// The line under the URL field for a failed add.
String addRepoFailureText(AppLocalizations l10n, RepoAddFailed failed) =>
    switch (failed.error) {
      RepoError.invalidUrl => l10n.pluginsAddErrInvalidUrl,
      RepoError.needsHttps => l10n.pluginsAddErrNeedsHttps,
      RepoError.duplicate => l10n.pluginsAddErrDuplicate,
      RepoError.network ||
      RepoError.timeout ||
      RepoError.cancelled => l10n.pluginsAddErrNetwork,
      RepoError.badStatus => l10n.pluginsAddErrNotFound,
      RepoError.notACatalog ||
      RepoError.tooLarge => l10n.pluginsAddErrBadFormat,
      RepoError.blocked =>
        failed.reason == null
            ? l10n.pluginsAddErrBlocked
            : l10n.pluginsAddErrBlockedReason(_problem(l10n, failed.reason!)),
      RepoError.storageFailed => l10n.pluginsAddErrStorage,
    };

String _problem(AppLocalizations l10n, AddressProblem problem) =>
    switch (problem) {
      AddressProblem.invalidUrl => l10n.pluginsAddErrInvalidUrl,
      AddressProblem.userInfo => l10n.pluginsAddressUserInfo,
      AddressProblem.publicNeedsHttps => l10n.pluginsAddErrNeedsHttps,
      AddressProblem.localFromPublic => l10n.pluginsAddressLocalFromPublic,
      AddressProblem.refusedAddress => l10n.pluginsAddressRefused,
      AddressProblem.mixedAddresses => l10n.pluginsAddressMixed,
      AddressProblem.localNameOnPublic => l10n.pluginsAddressLocalNamePublic,
    };
