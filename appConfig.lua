-- ----------------------------------------------------------------------------
--
-- appConfig - setup for the application
--
-- see:
-- # Blocks-11.0.0.txt
-- # Date: 2017-10-16, 24:39:00 GMT [KW]
-- # © 2017 Unicode®, Inc.
-- # For terms of use, see http://www.unicode.org/terms_of_use.html
-- #
-- # Unicode Character Database
-- # For documentation, see http://www.unicode.org/reports/tr44/
-- ----------------------------------------------------------------------------
--
-- ----------------------------------------------------------------------------
-- list of blocks to output when creating samples
-- set to false an entry to disable the block
-- Note: titles marked with a (*) are a continuation segment
-- and will display data only (no title repetition),
-- look at uniBlocks.lua for the physical division.
-- Warning: do not delete rows, disable them instead.
--          ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
-- Hint: to retrieve the corresponding document from the Unicode' ftp site
-- then use the Unicode hex value of the first segment (U+....)
--
-- Note: this is obviously not a 1:1 mapping of Blocks.txt from the
-- Unicode's Consortium, as the application details the physical
-- division of blocks and segments within each block, where a full
-- segment is 64 characters long (4 rows of 16 characters each).
--
local tUnicodeBlocks =
{
	-- 7 bits only
	--------------

	{true,		"Basic Latin"},
	{true,		"Basic Latin (*)"},

	-- c2-df block (2 bytes)
	------------------------

	{true,		"Latin-1 Supplement"},
	{true,		"Latin Extended-A"},
	{true,		"Latin Extended-B"},
	{true,		"Latin Extended-B (*)"},
	{true,		"IPA Extensions"},
	{true,		"IPA Extensions (*)"},
	{true,		"Spacing Modifier Letters"},
	{true,		"Spacing Modifier Letters (*)"},
	{true,		"Combining Diacritical Marks"},
	{true,		"Combining Diacritical Marks (*)"},
	{true,		"Greek and Coptic"},
	{true,		"Greek and Coptic (*)"},
	{true,		"Cyrillic"},
	{true,		"Cyrillic Supplement"},
	{true,		"Armenian"},
	{true,		"Armenian (*)"},
	{true,		"Armenian (*)"},
	{true,		"Hebrew"},										-- right to left
	{true,		"Hebrew (*)"},
	{true,		"Arabic"},										-- right to left
	{true,		"Arabic (*)"},
	{true,		"Syriac"},										-- right to left
	{true,		"Syriac (*)"},
	{true,		"Arabic Supplement"},							-- right to left
	{true,		"Thaana"},										-- right to left
	{true,		"NKo"},											-- right to left

	-- e0-ef block (3 bytes)
	------------------------

	{true,		"Samaritan"},
	{true,		"Mandaic"},
	{true,		"Syriac Supplement"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Arabic Extended-A"},
	{true,		"Devanagari"},
	{true,		"Bengali"},
	{true,		"Gurmukhi"},
	{true,		"Gujarati"},
	{true,		"Oriya"},
	{true,		"Tamil"},
	{true,		"Telugu"},
	{true,		"Kannada"},
	{true,		"Malayalam"},
	{true,		"Sinhala"},
	{true,		"Thai"},
	{true,		"Lao"},
	{true,		"Tibetan"},
	{true,		"Myanmar"},
	{true,		"Myanmar (*)"},
	{true,		"Georgian"},
	{true,		"Georgian (*)"},
	{true,		"Hangul Jamo"},
	{true,		"Ethiopic"},
	{true,		"Ethiopic Supplement"},
	{true,		"Cherokee"},
	{true,		"Cherokee (*)"},
	{true,		"Unified Canadian Aboriginal Syllabics"},
	{true,		"Ogham"},
	{true,		"Runic"},
	{true,		"Runic (*)"},
	{true,		"Tagalog"},
	{true,		"Hanunoo"},
	{true,		"Buhid"},
	{true,		"Tagbanwa"},
	{true,		"Khmer"},
	{true,		"Mongolian"},
	{true,		"Mongolian (*)"},
	{true,		"Unified Canadian Aboriginal Syllabics Extended"},
	{true,		"Unified Canadian Aboriginal Syllabics Extended (*)"},
	{true,		"Limbu"},
	{true,		"Limbu (*)"},
	{true,		"Tai Le"},
	{true,		"New Tai Lue"},
	{true,		"New Tai Lue (*)"},
	{true,		"Khmer Symbols"},
	{true,		"Buginese"},
	{true,		"Tai Tham"},
	{true,		"Tai Tham (*)"},
	{true,		"Tai Tham (*)"},
	{true,		"Combining Diacritical Marks Extended"},
	{true,		"Combining Diacritical Marks Extended (*)"},
	{true,		"Balinese"},
	{true,		"Sundanese"},
	{true,		"Batak"},
	{true,		"Lepcha"},
	{true,		"Lepcha (*)"},
	{true,		"Ol Chiki"},
	{true,		"Cyrillic Extended-C"},
	{true,		"Georgian Extended"},
	{true,		"Sundanese Supplement"},
	{true,		"Vedic Extensions"},
	{true,		"Phonetic Extensions"},
	{true,		"Phonetic Extensions Supplement"},
	{true,		"Combining Diacritical Marks Supplement"},
	{true,		"Latin Extended Additional"},
	{true,		"Greek Extended"},
	{true,		"General Punctuation"},
	{true,		"General Punctuation (*)"},
	{true,		"Superscripts and Subscripts"},
	{true,		"Superscripts and Subscripts (*)"},
	{true,		"Currency Symbols"},
	{true,		"Currency Symbols (*)"},
	{true,		"Combining Diacritical Marks for Symbols"},
	{true,		"Letterlike Symbols"},
	{true,		"Letterlike Symbols (*)"},
	{true,		"Number Forms"},
	{true,		"Number Forms (*)"},
	{true,		"Arrows"},
	{true,		"Arrows (*)"},
	{true,		"Mathematical Operators"},
	{true,		"Miscellaneous Technical"},
	{true,		"Control Pictures"},
	{true,		"Optical Character Recognition"},
	{true,		"Enclosed Alphanumerics"},
	{true,		"Enclosed Alphanumerics (*)"},
	{true,		"Box Drawing"},
	{true,		"Block Elements"},
	{true,		"Geometric Shapes"},
	{true,		"Geometric Shapes (*)"},
	{true,		"Miscellaneous Symbols"},
	{true,		"Dingbats"},
	{true,		"Miscellaneous Mathematical Symbols-A"},
	{true,		"Supplemental Arrows-A"},
	{true,		"Braille Patterns"},
	{true,		"Supplemental Arrows-B"},
	{true,		"Miscellaneous Mathematical Symbols-B"},
	{true,		"Supplemental Mathematical Operators"},
	{true,		"Miscellaneous Symbols and Arrows"},
	{true,		"Glagolitic"},
	{true,		"Glagolitic (*)"},
	{true,		"Latin Extended-c"},
	{true,		"Coptic"},
	{true,		"Georgian Supplement"},
	{true,		"Tifinagh"},
	{true,		"Tifinagh (*)"},
	{true,		"Ethiopic Extended"},
	{true,		"Ethiopic Extended (*)"},
	{true,		"Cyrillic Extended-A"},
	{true,		"Supplemental Punctuation"},
	{true,		"CJK Radicals Supplement"},
	{true,		"Kangxi Radicals"},
	{true,		"Kangxi Radicals (*)"},
	{true,		"Ideographic Description Characters"},
	{true,		"CJK Symbols and Punctuation"},
	{true,		"Hiragana"},
	{true,		"Hiragana (*)"},
	{true,		"Katakana"},
	{true,		"Katakana (*)"},
	{true,		"Bopomofo"},
	{true,		"Hangul Compatibility Jamo"},
	{true,		"Hangul Compatibility Jamo (*)"},
	{true,		"Hangul Compatibility Jamo (*)"},
	{true,		"Kanbun"},
	{true,		"Bopomofo Extended"},
	{true,		"CJK Strokes"},
	{true,		"Katakana Phonetic Extensions"},
	{true,		"Enclosed CJK Letters and Months"},
	{true,		"CJK Compatibility"},
	{true,		"CJK Unified Ideographs Extension A"},
	{true,		"CJK Unified Ideographs Extension A (*)"},
	{true,		"Yijing Hexagram Symbols"},
	{true,		"CJK Unified Ideographs"},
	{true,		"CJK Unified Ideographs (*)"},
	{true,		"Yi Syllables"},
	{true,		"Yi Syllables (*)"},
	{true,		"Yi Radicals"},
	{true,		"Yi Radicals (*)"},
	{true,		"Lisu"},
	{true,		"Vai"},
	{true,		"Cyrillic Extended-B"},
	{true,		"Cyrillic Extended-B (*)"},
	{true,		"Bamum"},
	{true,		"Bamum (*)"},
	{true,		"Modifier Tone Letters"},
	{true,		"Latin Extended-D"},
	{true,		"Latin Extended-D (*)"},
	{true,		"Syloti Nagri"},
	{true,		"Common Indic Number Forms"},
	{true,		"Phags-pa"},
	{true,		"Saurashtra"},
	{true,		"Saurashtra (*)"},
	{true,		"Devanagari Extended"},
	{true,		"Kayah Li"},
	{true,		"Rejang"},
	{true,		"Rejang (*)"},
	{true,		"Hangul Jamo Extended-A"},
	{true,		"Javanese"},
	{true,		"Javanese (*)"},
	{true,		"Myanmar Extended-B"},
	{true,		"Cham"},
	{true,		"Cham (*)"},
	{true,		"Myanmar Extended-A"},
	{true,		"Tai Viet"},
	{true,		"Tai Viet (*)"},
	{true,		"Meetei Mayek Extensions"},
	{true,		"Ethiopic Extended-A"},
	{true,		"Latin Extended-E"},
	{true,		"Latin Extended-E (*)"},
	{true,		"Cherokee Supplement"},
	{true,		"Cherokee Supplement (*)"},
	{true,		"Meetei Mayek"},
	{true,		"Hangul Syllables"},
	{true,		"Hangul Syllables (*)"},
	{true,		"Hangul Syllables (*)"},
	{true,		"Hangul Syllables (*)"},
	{true,		"Hangul Jamo Extended-B"},
	{true,		"Hangul Jamo Extended-B (*)"},
	{false,		"High Surrogates"},								-- not in RFC 3629
	{false,		"High Private Use Surrogates"},					-- not in RFC 3629
	{false,		"Low Surrogates"},								-- not in RFC 3629
	{true, 		"Private Use Area"},
	{true, 		"Private Use Area (*)"},
	{true,		"CJK Compatibility Ideographs"},
	{true,		"Alphabetic Presentation Forms"},				-- some right to left
	{true,		"Alphabetic Presentation Forms (*)"},			-- right to left
	{true,		"Arabic Presentation Forms-A"},					-- right to left
	{true,		"Arabic Presentation Forms-A (*)"},
	{true,		"Variation Selectors"},
	{true,		"Vertical Forms"},
	{true,		"Combining Half Marks"},
	{true,		"CJK Compatibility Forms"},
	{true,		"CJK Compatibility Forms (*)"},
	{true,		"Small Form Variants"},
	{true,		"Arabic Presentation Forms-B"},					-- right to left	
	{true,		"Arabic Presentation Forms-B (*)"},
	{true,		"Halfwidth and Fullwidth Forms"},
	{true,		"Halfwidth and Fullwidth Forms (*)"},
	{true,		"Specials"},

	-- f0-f4 block (4 bytes)
	------------------------

	{true,		"Linear B Syllabary"},
	{true,		"Linear B Ideograms"},
	{true,		"Aegean Numbers"},
	{true,		"Ancient Greek Numbers"},
	{true,		"Ancient Greek Numbers (*)"},
	{true,		"Ancient Symbols"},
	{true,		"Ancient Symbols (*)"},
	{true,		"Phaistos Disc"},
	{false,		"No_Block"},
	{true,		"Lycian"},
	{true,		"Carian"},
	{true,		"Carian (*)"},
	{true,		"Coptic Epact Numbers"},
	{true,		"Old Italic"},
	{true,		"Gothic"},
	{true,		"Gothic (*)"},
	{true,		"Old Permic"},
	{true,		"Ugaritic"},
	{true,		"Old Persian"},
	{true,		"Old Persian (*)"},
	{false,		"No_Block"},
	{true,		"Deseret"},
	{true,		"Deseret (*)"},
	{true,		"Shavian"},
	{true,		"Osmanya"},
	{true,		"Osage"},
	{true,		"Osage (*)"},
	{true,		"Elbasan"},
	{true,		"Caucasian Albanian"},
	{true,		"Caucasian Albanian (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Linear A"},
	{false,		"No_Block"},
	{true,		"Cypriot Syllabary"},
	{true,		"Imperial Aramaic"},							-- right to left
	{true,		"Palmyrene"},
	{true,		"Nabataean"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Hatran"},
	{true,		"Phoenician"},
	{true,		"Lydian"},
	{false,		"No_Block"},
	{true,		"Meroitic Hieroglyphs"},
	{true,		"Meroitic Cursive"},							-- right to left
	{true,		"Meroitic Cursive (*)"},
	{true,		"Kharoshthi"},									-- right to left
	{true,		"Kharoshthi (*)"},
	{true,		"Old South Arabian"},							-- right to left
	{true,		"Old North Arabian"},
	{false,		"No_Block"},
	{true,		"Manichaean"},
	{true,		"Avestan"},
	{true,		"Inscriptional Parthian"},						-- right to left
	{true,		"Inscriptional Pahlavi"},						-- right to left
	{true,		"Psalter Pahlavi"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Old Turkic"},									-- right to left
	{true,		"Old Turkic (*)"},
	{false,		"No_Block"},
	{true,		"Old Hungarian"},
	{true,		"Hanifi Rohingya"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Rumi Numeral Symbols"},
	{false,		"No_Block"},
	{true,		"Old Sogdian"},
	{true,		"Sogdian"},
	{true,		"Sogdian (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Brahmi"},
	{true,		"Kaithi"},
	{true,		"Kaithi (*)"},
	{true,		"Sora Sompeng"},
	{true,		"Chakma"},
	{true,		"Chakma (*)"},
	{true,		"Mahajani"},
	{true,		"Sharada"},
	{true,		"Sharada (*)"},
	{true,		"Sinhala Archaic Numbers"},
	{true,		"Khojki"},
	{true,		"Khojki (*)"},
	{true,		"Multani"},
	{true,		"Khudawadi"},
	{true,		"Khudawadi (*)"},
	{true,		"Grantha"},
	{false,		"No_Block"},
	{true,		"Newa"},
	{true,		"Tirhuta"},
	{true,		"Tirhuta (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Siddham"},
	{true,		"Modi"},
	{true,		"Modi (*)"},
	{true,		"Mongolian Supplement"},
	{true,		"Takri"},
	{true,		"Takri (*)"},
	{false,		"No_Block"},
	{true,		"Ahom"},
	{false,		"No_Block"},
	{true,		"Dogra"},
	{true,		"Dogra (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Warang Citi"},
	{true,		"Warang Citi (*)"},
	{false,		"No_Block"},
	{true,		"Zanabazar Square"},
	{true,		"Zanabazar Square (*)"},
	{true,		"Soyombo"},
	{true,		"Soyombo (*)"},
	{false,		"No_Block"},
	{true,		"Pau Cin Hau"},
	{false,		"No_Block"},
	{true,		"Bhaiksuki"},
	{true,		"Bhaiksuki (*)"},
	{true,		"Marchen"},
	{true,		"Marchen (*)"},
	{false,		"No_Block"},
	{true,		"Masaram Gondi"},
	{true,		"Masaram Gondi (*)"},
	{true,		"Gunjala Gondi"},
	{true,		"Gunjala Gondi (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{false,		"No_Block (*)"},
	{true,		"Makasar"},
	{false,		"No_Block"},
	{true,		"Cuneiform"},
	{true,		"Cuneiform Numbers and Punctuation"},
	{true,		"Early Dynastic Cuneiform"},
	{true,		"Early Dynastic Cuneiform (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Egyptian Hieroglyphs"},
	{true,		"Egyptian Hieroglyphs (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{false,		"No_Block (*)"},
	{true,		"Anatolian Hieroglyphs"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{false,		"No_Block (*)"},
	{true,		"Bamum Supplement"},
	{true,		"Mro"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{false,		"No_Block (*)"},
	{true,		"Bassa Vah"},
	{true,		"Pahawh Hmong"},
	{true,		"Pahawh Hmong (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Medefaidrin"},
	{true,		"Medefaidrin (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Miao"},
	{true,		"Miao (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Ideographic Symbols and Punctuation"},
	{true,		"Tangut"},
	{true,		"Tangut (*)"},
	{true,		"Tangut Components"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Kana Supplement"},
	{true,		"Kana Extended-A"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Nushu"},
	{true,		"Nushu (*)"},
	{false,		"No_Block"},
	{true,		"Duployan"},
	{true,		"Duployan (*)"},
	{true,		"Shorthand Format Controls"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{false,		"No_Block (*)"},
	{true,		"Byzantine Musical Symbols"},
	{true,		"Musical Symbols"},
	{true,		"Ancient Greek Musical Notation"},
	{true,		"Ancient Greek Musical Notation (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{false,		"No_Block (*)"},
	{true,		"Mayan Numerals"},
	{false,		"No_Block"},
	{true,		"Tai Xuan Jing Symbols"},
	{true,		"Tai Xuan Jing Symbols (*)"},
	{true,		"Counting Rod Numerals"},
	{false,		"No_Block"},
	{true,		"Mathematical Alphanumeric Symbols"},
	{true,		"Sutton SignWriting"},
	{true,		"Sutton SignWriting (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Glagolitic Supplement"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"Mende Kikakui"},
	{true,		"Mende Kikakui (*)"},
	{false,		"No_Block"},
	{true,		"Adlam"},
	{true,		"Adlam (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{false,		"No_Block (*)"},
	{true,		"Indic Siyaq Numbers"},
	{true,		"Indic Siyaq Numbers (*)"},
	{false,		"No_Block"},
	{true,		"Arabic Mathematical Alphabetic Symbols"},
	{false,		"No_Block"},
	{true,		"Mahjong Tiles"},
	{true,		"Domino Tiles"},
	{true,		"Domino Tiles (*)"},
	{true,		"Domino Tiles (*)"},
	{true,		"Playing Cards"},
	{true,		"Playing Cards (*)"},
	{true,		"Enclosed Alphanumeric Supplement"},
	{true,		"Enclosed Ideographic Supplement"},
	{true,		"Miscellaneous Symbols and Pictographs"},
	{true,		"Emoticons"},
	{true,		"Emoticons (*)"},
	{true,		"Ornamental Dingbats"},
	{true,		"Transport and Map Symbols"},
	{true,		"Alchemical Symbols"},
	{true,		"Geometric Shapes Extended"},
	{true,		"Supplemental Arrows-C"},
	{true,		"Supplemental Symbols and Pictographs"},
	{true,		"Chess Symbols"},
	{true,		"Chess Symbols (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{true,		"CJK Unified Ideographs Extension B"},
	{true,		"CJK Unified Ideographs Extension B (*)"},
	{true,		"CJK Unified Ideographs Extension B (*)"},
	{false,		"No_Block"},
	{true,		"CJK Unified Ideographs Extension C"},
	{true,		"CJK Unified Ideographs Extension C (*)"},
	{true,		"CJK Unified Ideographs Extension D"},
	{true,		"CJK Unified Ideographs Extension D (*)"},
	{true,		"CJK Unified Ideographs Extension E"},
	{true,		"CJK Unified Ideographs Extension E (*)"},
	{true,		"CJK Unified Ideographs Extension E (*)"},
	{true,		"CJK Unified Ideographs Extension E (*)"},
	{true,		"CJK Unified Ideographs Extension F"},
	{true,		"CJK Unified Ideographs Extension F (*)"},
	{true,		"CJK Unified Ideographs Extension F (*)"},
	{true,		"CJK Unified Ideographs Extension F (*)"},
	{true,		"CJK Unified Ideographs Extension F (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{false,		"No_Block (*)"},
	{true,		"CJK Compatibility Ideographs Supplement"},
	{true,		"CJK Compatibility Ideographs Supplement (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{false,		"No_Block (*)"},
	{false,		"No_Block (*)"},
	{false,		"No_Block (*)"},
	{false,		"No_Block (*)"},
	{true,		"Tags"},
	{false,		"No_Block"},
	{true,		"Variation Selectors Supplement"},
	{true,		"Variation Selectors Supplement (*)"},
	{false,		"No_Block"},
	{false,		"No_Block (*)"},
	{false,		"Supplementary Private Use Area-A"},
	{false,		"Supplementary Private Use Area-B"},
	{false,		"Supplementary Private Use Area-B (*)"},
	{true,		"Non-characters"},
}

-- ----------------------------------------------------------------------------
-- helper: these is a listing of some fonts installed on my laptop
-- so if I want to test a new font I just change the index in selected entry.
-- Note: characters in the 'Private Use Area' really depend on current font.
-- Hint: testing Latin-B, Arrows, Symbols, Shapes will give an idea of correctness.
-- Note: a star * marks a failure on primary tests.
--
local tPreferFont =
{
	"Source Code Pro",				--  1 falls short on Latin B
	"Gentium Book Basic",			--  2 falls long on Latin B
	"David Libre",					--  3 falls long on Latin B
	"EmojiOne Color",				--  4 often prints below baseline
	"Microsoft Sans Serif",			--  5 falls short on Supplemental Arrows
	"Lucida Sans Unicode",			--  6 falls long on Phonetic Extensions
	"DejaVu Sans Mono",				--  7 ok
	"Noto Mono",					--  8 falls short on Latin B
	"Trebuchet MS",					--  9 falls short on Latin B
	"Liberation Sans",				-- 10 ok, fails on Greek Extended + has leading
	"Courier New",					-- 11 too bad on Latin B first row
	"Frank Ruehl CLM",				-- 12 nice + leading
	"Alef",							-- 13 seldom falls really short
	"Amiri",						-- 14 odd behaviour, really bad
	"Ebrima",						-- 15 nice, falls really short, slow loupe
	"Gadugi",						-- 16 falls short on Latin B
	"MusicM",						-- 17 really bad display
	"MS Gothic",					-- 18 falls very long on Latin B
	"Arial Unicode MS",				-- 19 ok
	"Rubik",						-- 20 fat, *
	"Segoe UI",						-- 21 falls short on Arrows
	"Tahoma",						-- 22 ok
	"Times New Roman",				-- 23 ok + leading
	"Trebuchet MS",					-- 24 falls short on Latin B
	"Verdana",						-- 25 falls very long on Latin B
	"Unifont",						-- 26 harsh + leading + nl
	"Batang",						-- 27 fails on Cyrillic Extended A + leading + nl
	"Gulim",						-- 28 ok + leading + nl
	"MingLiU",						-- 29 many Mathematical Alphanumeric Symbols undefined + leading
	"MS Mincho",					-- 30 thin, falls very long
	"SimHei",						-- 31 slow drawing, Greek and Cyrillic wide spacing
	"SimSun",						-- 32 Greek wide spacing
	"Caladea",						-- 33 slightly oblique, text's extent really wrong
	"Calibri",						-- 34 fails on many Arrows
	"Cambria",						-- 35 ok
	"Candara",						-- 36 *
	"Consolas",						-- 37 mono-spaced, *
	"Constantia",					-- 38 *
	"Corbel",						-- 39 *, lacks many Arrows
	"David CLM",					-- 40 *
	"Datum",						-- 41 *, + leading
	"Gabriola",						-- 42 really bad, inconsistent
	"Georgia",						-- 43 often falls short on many characters
	"Gungsuh",						-- 44 ok but odd behaviour if treated, fat, + leading + nl
	"Linux Biolinum G",				-- 45 ok, fails on Blocks
	"MS PMincho",					-- 46 fails short on Latin B
	"Miriam Mono CLM",				-- 47 narrow Latin 1, mostly mono-spaced
	"Nachlieli CLM",				-- 48 *
	"Reem Kufi",					-- 49 *
	"Rubik",						-- 50 *
	"Scheherazade",					-- 51 inconsistent
	"Sitka",						-- 52 fails on Number Forms
	"Sylfaen",						-- 53 *
	
}

-- ----------------------------------------------------------------------------
-- list of known codepages for the testfiles
-- (all testfiles provided are Latin I or such ...)
-- Hint: to display properly text with box drawing characters use  a mono-spaced font
--
local tKnowCPs =
{
	{"Windows",	  1252},			-- usually ok (test file 1,2,3,4,6,7,8)
	{"OEM",		   437},			-- lines and blocks (test file 5,a,b,c,d)
	{"ISO",		885901},			-- Euro currency symbol not defined
}

-- ----------------------------------------------------------------------------
-- parameters for the application
-- if modified and the application is running then call refresh settings
--
-- Hint: it's a wise choice to select the loupe's font name the same as per "TextFont".
-- Note: memory garbage collection set to Generational won't release much memory.
-- Note: memory is forced to be fully recollected upon a file read.
--
local tSetupInf =
{
	-- importing the file
	--
	["InFile"]		= "testfiles\\__Test_1.txt",		-- import file name
	["ReadMode"]	= "r",								-- r/rb
	["AutoLoad"]	= true,								-- load at startup time
	["Codepage"]  	= tKnowCPs[1],						-- desired encoding

	-- saving the file
	--
	["OutFile"]		= "testfiles\\__Test_out.txt",		-- output file name
	["WriteMode"]	= "w",								-- w/wb/a  with + option

	-- checking validity
	--
	["Pedantic"]	= false,							-- trace each line error
	["AutoCheck"]	= false,							-- check validity at load time

	-- samples file creation
	--
	["OnlyGroups"]	= false,							-- compact output, show group's names only
	["AlignByCols"]	= 16,								-- number of columns when not in compact mode
	["ByBlocksRow"] = tUnicodeBlocks,					-- table listing the Unicode blocks enabled
	["SamplesFile"]	= "testfiles\\__Test_xx.txt",		-- output file name

	-- display
	--
	["ByteFont"]	= {12, tPreferFont[7]},				-- left display (codes)
	["TextFont"]	= {19, tPreferFont[47]},			-- right display (text)
	["FontStep"]	= 1,								-- note: wxFont ignores decimals
	["Columns"]		= 16,								-- format number of columns
	["Interleave"]	= true,								-- highlight even columns
	["WheelMult"]	= 10,								-- override o.s. mouse wheel's scroll
	["Format"]		= "Hex",							-- Oct/Dec/Hex
	["HideSpaces"]	= true,								-- hide bytes of value 0x20 (space)
	["Underline"]	= true,								-- underline bytes below 0x20
	["ColourCodes"]	= true,								-- highlight Unicode bytes group
	["TabSize"]		= 4,								-- convert tab to 'n' chars (left pane)
	["Scheme"]		= "Dark",							-- colour scheme - White/Light/Dark/Black

	-- edit
	--
	["CopyOption"]	= "Select",							-- Byte/UTF_8/Word/Line/Select
--	["PasteOption"] = "Discard",						-- (ignored) handling of errors - Discard/Convert/Plain
--	["SelectOption"]= "Free",							-- (ignored) selection mode - Line/Free

	-- magnify
	--
	["Loupe"]		= {200, tPreferFont[47]},			-- font for the magnifying window
	["UseNames"]	= "Docs\\NamesList.txt",			-- names' file (comment line to disable)
	
	-- extra
	--
	["TimeDisplay"]	= 10,								-- seconds of message in status bar
	["Collector"]	= "Generational",					-- wasted memory - Generational/Incremental
	["TraceMemory"]	= true,								-- enable tracing of memory usage

}

-- ----------------------------------------------------------------------------
--
return tSetupInf

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
