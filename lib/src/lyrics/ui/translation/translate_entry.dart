/// The entry points to the "Dịch lời" modal that Now Playing places: the
/// mobile lyrics-screen button, the desktop pill, the ⋮ item's second line and
/// the toggle (right click, `T`). The screens only place these widgets; what
/// they show comes from `translateEntryProvider`.
library;

export 'modal/translate_modal.dart' show showTranslateModal;
export 'translate_button.dart' show TranslateButton;
export 'translate_entry_state.dart'
    show TranslateEntryState, translateEntryProvider;
export 'translate_menu_item.dart' show translateMenuAvailableProvider;
export 'translate_pill.dart' show TranslatePill;
export 'translate_toggle.dart'
    show
        TranslateOpener,
        openTranslateModalForPlaying,
        toggleTranslation,
        toggleTranslationNow;
