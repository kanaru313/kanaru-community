/// Limits on what a streaming plugin's `search`, `stream` and `autocomplete`
/// scripts may output. Lengths count Unicode code points unless noted.
library;

/// Most cards one search page keeps over all its sections.
const maxPageCards = 200;
const maxIdRunes = 200;
const maxTitleRunes = 300;
const maxArtistRunes = 200;
const maxSubtitleRunes = 300;
const maxSectionTitleRunes = 100;
const maxSections = 20;
const maxFilters = 20;
const maxFilterTitleRunes = 50;
const maxCardArtists = 10;

/// Longest believed duration (24 h).
const maxDurationMs = 86400000;

/// Longest `artworkUrl` or `webUrl`, in characters.
const maxLinkChars = 2000;

/// Largest `next`, stream `url` and filter `input`, in UTF-8 bytes.
const maxTokenBytes = 8 * 1024;

const maxStreamHeaders = 20;
const maxSuggestions = 10;
const maxSuggestionRunes = 200;

/// Longest search query a caller may send.
const maxQueryRunes = 2000;
