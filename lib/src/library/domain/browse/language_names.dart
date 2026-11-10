/// A language name in its own language, English and Vietnamese.
typedef LanguageNames = ({String native, String en, String vi});

/// Names of [code] (ISO 639-3, lower case), or null for a code not in the
/// table. The UI shows `native`, plus ` · <localized>` when the localized
/// name differs.
LanguageNames? languageNameOf(String code) => _names[code.toLowerCase()];

const _names = <String, LanguageNames>{
  'vie': (native: 'Tiếng Việt', en: 'Vietnamese', vi: 'Tiếng Việt'),
  'eng': (native: 'English', en: 'English', vi: 'Tiếng Anh'),
  'jpn': (native: '日本語', en: 'Japanese', vi: 'Tiếng Nhật'),
  'kor': (native: '한국어', en: 'Korean', vi: 'Tiếng Hàn'),
  'cmn': (native: '中文', en: 'Chinese (Mandarin)', vi: 'Tiếng Quan Thoại'),
  'zho': (native: '中文', en: 'Chinese', vi: 'Tiếng Trung'),
  'fra': (native: 'Français', en: 'French', vi: 'Tiếng Pháp'),
  'deu': (native: 'Deutsch', en: 'German', vi: 'Tiếng Đức'),
  'spa': (native: 'Español', en: 'Spanish', vi: 'Tiếng Tây Ban Nha'),
  'ita': (native: 'Italiano', en: 'Italian', vi: 'Tiếng Ý'),
  'por': (native: 'Português', en: 'Portuguese', vi: 'Tiếng Bồ Đào Nha'),
  'rus': (native: 'Русский', en: 'Russian', vi: 'Tiếng Nga'),
  'tha': (native: 'ไทย', en: 'Thai', vi: 'Tiếng Thái'),
  'ind': (native: 'Bahasa Indonesia', en: 'Indonesian', vi: 'Tiếng Indonesia'),
  'msa': (native: 'Bahasa Melayu', en: 'Malay', vi: 'Tiếng Mã Lai'),
  'hin': (native: 'हिन्दी', en: 'Hindi', vi: 'Tiếng Hindi'),
  'ara': (native: 'العربية', en: 'Arabic', vi: 'Tiếng Ả Rập'),
  'tur': (native: 'Türkçe', en: 'Turkish', vi: 'Tiếng Thổ Nhĩ Kỳ'),
  'nld': (native: 'Nederlands', en: 'Dutch', vi: 'Tiếng Hà Lan'),
  'swe': (native: 'Svenska', en: 'Swedish', vi: 'Tiếng Thụy Điển'),
  'pol': (native: 'Polski', en: 'Polish', vi: 'Tiếng Ba Lan'),
  'ukr': (native: 'Українська', en: 'Ukrainian', vi: 'Tiếng Ukraina'),
  'ces': (native: 'Čeština', en: 'Czech', vi: 'Tiếng Séc'),
  'ell': (native: 'Ελληνικά', en: 'Greek', vi: 'Tiếng Hy Lạp'),
  'heb': (native: 'עברית', en: 'Hebrew', vi: 'Tiếng Do Thái'),
  'fil': (native: 'Filipino', en: 'Filipino', vi: 'Tiếng Philippines'),
  'tgl': (native: 'Tagalog', en: 'Tagalog', vi: 'Tiếng Tagalog'),
  'khm': (native: 'ភាសាខ្មែរ', en: 'Khmer', vi: 'Tiếng Khmer'),
  'lao': (native: 'ລາວ', en: 'Lao', vi: 'Tiếng Lào'),
  'mya': (native: 'မြန်မာဘာသာ', en: 'Burmese', vi: 'Tiếng Myanmar'),
  'ben': (native: 'বাংলা', en: 'Bengali', vi: 'Tiếng Bengal'),
  'tam': (native: 'தமிழ்', en: 'Tamil', vi: 'Tiếng Tamil'),
  'tel': (native: 'తెలుగు', en: 'Telugu', vi: 'Tiếng Telugu'),
  'urd': (native: 'اردو', en: 'Urdu', vi: 'Tiếng Urdu'),
  'fas': (native: 'فارسی', en: 'Persian', vi: 'Tiếng Ba Tư'),
  'hun': (native: 'Magyar', en: 'Hungarian', vi: 'Tiếng Hungary'),
  'ron': (native: 'Română', en: 'Romanian', vi: 'Tiếng Romania'),
  'dan': (native: 'Dansk', en: 'Danish', vi: 'Tiếng Đan Mạch'),
  'fin': (native: 'Suomi', en: 'Finnish', vi: 'Tiếng Phần Lan'),
  'nor': (native: 'Norsk', en: 'Norwegian', vi: 'Tiếng Na Uy'),
  'nob': (
    native: 'Norsk bokmål',
    en: 'Norwegian Bokmål',
    vi: 'Tiếng Na Uy (Bokmål)',
  ),
  'cat': (native: 'Català', en: 'Catalan', vi: 'Tiếng Catalan'),
  'lat': (native: 'Latina', en: 'Latin', vi: 'Tiếng Latinh'),
};
