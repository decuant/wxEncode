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

-- ----------------------------------------------------------------------------
-- list of blocks to output when creating samples
-- set to false an entry to disable the block
-- note: titles marked with a (*) are a continuation
-- and will display data only (no title's repetition)
-- see samples.lua for the physical division
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
	{true,		"Hebrew"},
	{true,		"Hebrew (*)"},
	{true,		"Arabic"},
	{true,		"Arabic (*)"},
	{true,		"Syriac"},
	{true,		"Syriac (*)"},
	{true,		"Arabic Supplement"},
	{true,		"Thaana"},
	{true,		"NKo"},

	-- e0-ef block (3 bytes)
	------------------------
	
	{true,		"Samaritan"},
	{true,		"Mandaic"},
	{true,		"Syriac Supplement"},
	{true,		"No_Block"},
	{true,		"No_Block (*)"},
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
	{true,		"High Surrogates"},
	{true,		"High Private Use Surrogates"},
	{true,		"Low Surrogates"},
	{true, 		"Private Use Area"},
	{true, 		"Private Use Area (*)"},
	{true,		"CJK Compatibility Ideographs"},
	{true,		"Alphabetic Presentation Forms"},
	{true,		"Alphabetic Presentation Forms (*)"},
	{true,		"Arabic Presentation Forms-A"},
	{true,		"Arabic Presentation Forms-A (*)"},
	{true,		"Variation Selectors"},
	{true,		"Vertical Forms"},
	{true,		"Combining Half Marks"},
	{true,		"CJK Compatibility Forms"},
	{true,		"CJK Compatibility Forms (*)"},
	{true,		"Small Form Variants"},
	{true,		"Arabic Presentation Forms-B"},
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
	{true,		"No_Block"},
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
	{true,		"No_Block"},	
	{true,		"Deseret"},
	{true,		"Deseret (*)"},
	{true,		"Shavian"},
	{true,		"Osmanya"},	
	{true,		"Osage"},
	{true,		"Osage (*)"},
	{true,		"Elbasan"},
	{true,		"Caucasian Albanian"},
	{true,		"Caucasian Albanian (*)"},
	{true,		"No_Block"},
	{true,		"No_Block (*)"},
	{true,		"Linear A"},
	{true,		"No_Block"},
	{true,		"Cypriot Syllabary"},
	{true,		"Imperial Aramaic"},
	{true,		"Palmyrene"},
	{true,		"Nabataean"},
	{true,		"No_Block"},
	{true,		"No_Block (*)"},
	{true,		"Hatran"},
	{true,		"Phoenician"},
	{true,		"Lydian"},	
	{true,		"No_Block"},
	{true,		"Meroitic Hieroglyphs"},
	{true,		"Meroitic Cursive"},
	{true,		"Meroitic Cursive (*)"},
	{true,		"Kharoshthi"},
	{true,		"Kharoshthi (*)"},
	{true,		"Old South Arabian"},
	{true,		"Old North Arabian"},
	{true,		"No_Block"},
	{true,		"Manichaean"},
	{true,		"Avestan"},
	{true,		"Inscriptional Parthian"},
	{true,		"Inscriptional Pahlavi"},
	{true,		"Psalter Pahlavi"},
	{true,		"No_Block"},
	{true,		"No_Block (*)"},
	{true,		"Old Turkic"},
	{true,		"Old Turkic (*)"},
	{true,		"No_Block"},
	{true,		"Old Hungarian"},
	{true,		"Hanifi Rohingya"},
	{true,		"No_Block"},
	{true,		"No_Block (*)"},
	{true,		"Rumi Numeral Symbols"},
	{true,		"No_Block"},
	{true,		"Old Sogdian"},
	{true,		"Sogdian"},
	{true,		"Sogdian (*)"},
	{true,		"No_Block"},
	{true,		"No_Block (*)"},
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
	{true,		"No_Block"},
	{true,		"Newa"},
	{true,		"Tirhuta"},
	{true,		"Tirhuta (*)"},
	{true,		"No_Block"},
	{true,		"No_Block (*)"},
	{true,		"Siddham"},
	{true,		"Modi"},
	{true,		"Modi (*)"},
	{true,		"Mongolian Supplement"},
	{true,		"Takri"},
	{true,		"Takri (*)"},
	{true,		"No_Block"},
	{true,		"Ahom"},
	{true,		"No_Block"},
	{true,		"Dogra"},
	{true,		"Dogra (*)"},
	{true,		"No_Block"},
	{true,		"No_Block (*)"},
	{true,		"Warang Citi"},
	{true,		"Warang Citi (*)"},
	{true,		"No_Block"},	
	{true,		"Zanabazar Square"},
	{true,		"Zanabazar Square (*)"},				-- <<<<<
	{true,		"f0 91 a9 ??"},
	{true,		"f0 91 aa-bf ??"},
	{true,		"Cuneiform"},
	{true,		"Cuneiform Numbers and Punctuation"},
	{true,		"Early Dynastic Cuneiform"},
	{true,		"Early Dynastic Cuneiform (*)"},
	{true,		"f0 92 95 ??"},
	{true,		"f0 92 96 bf ??"},
	{true,		"Egyptian Hieroglyphs"},
	{true,		"f0 93 91 ??"},
	{true,		"f0 94-95 ??"},
	{true,		"f0 96 80 ??"},
	{true,		"f0 96-bf ??"},
	{true,		"Ideographic Symbols and Punctuation"},
	{true,		"f0 97-9a ??"},
	{true,		"f0 9b 80 ??"},	
	{true,		"Duployan"},
	{true,		"Duployan (*)"},
	{true,		"f0 9b b2 ??"},
	{true,		"f0 9b  b3-bf ??"},
	{true,		"f0 9c ??"},
	{true,		"f0 9d ??"},
	{true,		"Musical Symbols"},
	{true,		"f0 9d 88 ??"},
	{true,		"f0 9d 8d ??"},
	{true,		"Counting Rod Numerals"},
	{true,		"f0 9d 8e ??"},
	{true,		"Mathematical Alphanumeric Symbols"},
	{true,		"Sutton SignWriting"},
	{true,		"Sutton SignWriting (*)"},
	{true,		"f0 9d aa ??"},
	{true,		"f0 9d ab-bf ??"},
	{true,		"f0 9e 80 ??"},
	{true,		"Arabic Mathematical Alphabetic Symbols"},
	{true,		"f0 9e bc ??"},
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
	{true,		"No_Block"},
	{true,		"No_Block (*)"},
	{true,		"CJK Unified Ideographs Extension B"},
	{true,		"CJK Unified Ideographs Extension B (*)"},
	{true,		"CJK Unified Ideographs Extension B (*)"},
	{true,		"No_Block"},
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
	{true,		"No_Block"},
	{true,		"No_Block (*)"},
	{true,		"No_Block (*)"},
	{true,		"CJK Compatibility Ideographs Supplement"},
	{true,		"CJK Compatibility Ideographs Supplement (*)"},
	{true,		"No_Block"},
	{true,		"No_Block (*)"},
	{true,		"No_Block (*)"},
	
	{true,		"-> Private Area B <-"},
	{true,		"-> Private Area C <-"},
	{true,		"-> Private Area D <-"},
	{true,		"-> Unknown Extras <-"},
	{true,		"-> Private Area E <-"},
	{true,		"-> Private Area F <-"},
	
}

-- ----------------------------------------------------------------------------
-- helper: these are some fonts installed on my laptop
-- so if I want to test a new font I just change
-- the index in tSetupInf.ByteFont or tSetupInf.TextFont
--
local tPreferFont =
{
	"Source Code Pro",				-- 1
	"Gentium Book Basic",
	"David Libre",
	"EmojiOne Color",				-- 4
	"Microsoft Sans Serif",
	"Lucida Sans Unicode",
	"DejaVu Sans Mono",				-- 7
	"Noto Mono",
	"Trebuchet MS",
	"Liberation Sans",				-- 10
	"Courier New",	
	"Frank Ruehl CLM",
	"Alef",							-- 13
	"Amiri",
	"Ebrima",
	"Gadugi",						-- 16
	"MusicM",
	"MS Gothic",
	"Arial Unicode MS",				-- 19
	
}

-- ----------------------------------------------------------------------------
-- parameters for the application
-- if modified and the application is running then call refresh settings
--
local tSetupInf =
{
	-- importing the file
	--
	["InFile"]		= "testfiles\\__Test_xx.txt",		-- import file name
	["ReadMode"]	= "r",								-- r/rb
	["AutoLoad"]	= true,								-- load at startup time

	-- saving the file
	--
	["OutFile"]		= "testfiles\\__Test_xx.txt",		-- output file name
	["WriteMode"]	= "w",								-- w/wb/a  with + option
	
	-- checking validity
	--
	["Pedantic"]	= false,							-- trace each line error
	["AutoCheck"]	= false,							-- check validity at load time

	-- samples file creation
	--
	["OnlyGroups"]	= false,							-- compact output, show group's names only
	["AlignByCols"]	= 16,								-- number of columns when in compact mode
	["ByBlocksRow"] = tUnicodeBlocks,					-- table listing the UTF blocks to generate
	["SamplesFile"]	= "testfiles\\__Test_xx.txt",		-- output file name
	
	-- display
	--
	["ByteFont"]	= { 8.5, tPreferFont[7]},			-- left display (codes)
	["TextFont"]	= {17.5, tPreferFont[18]},			-- right display (text)
	["FontStep"]	= 1.5,								-- step for increasing text's font size
	["Columns"]		= 16,								-- format number of columns
	["Interleave"]	= true,								-- highlight even columns
	["WheelMult"]	= 10,								-- override o.s. mouse wheel's scroll
	["Format"]		= "Hex",							-- Oct/Dec/Hex
	["HideSpaces"]	= true,								-- hide the bytes of value 0x20
	["Underline"]	= true,								-- underline bytes below 0x20
	["ColourCodes"]	= true,								-- highlight Unicode bytes group
	["TabSize"]		= 4,								-- convert tab to 'n' chars (left pane)
	["Scheme"]		= "Black",							-- colour scheme - White/Light/Dark/Black
	
	-- edit
	--
	["CopyOption"]	= "UTF_8",							-- Byte/UTF_8/Word/Line (textual word)
--	["PasteOption"] = "Discard",						-- handling of errors - Discard/Convert/Plain
--	["SelectOption"]= "Line",							-- selection mode - Line/All
	
	-- extra
	--
	["TimeDisplay"]	= 10,								-- seconds of message in status bar
	["TraceMemory"]	= true,								-- enable tracing of memory usage
	
	-- magnify
	--
	["Loupe"]		= {150, tPreferFont[12]},			-- font for the magnify window	
}

-- ----------------------------------------------------------------------------
--
return tSetupInf

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
