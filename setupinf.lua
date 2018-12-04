-- ----------------------------------------------------------------------------
--
-- Setupinf - setup for the application
--
-- # Blocks-11.0.0.txt
-- # Date: 2017-10-16, 24:39:00 GMT [KW]
-- # © 2017 Unicode®, Inc.
-- # For terms of use, see http://www.unicode.org/terms_of_use.html
-- #
-- # Unicode Character Database
-- # For documentation, see http://www.unicode.org/reports/tr44/
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- helper: these are fonts installed on my laptop
-- so if I want to test a new font I just change
-- the index in tSetupInf.ByteFont or tSetupInf.TextFont
--
local tPreferFont =
{
	"Source Code Pro",
	"Gentium Book Basic",
	"David Libre",
	"EmojiOne Color",				-- 4	(0xf0)
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
	"Gadugi"						-- 16
}

-- ----------------------------------------------------------------------------
-- list of blocks to output when creating samples
-- set to false an entry to disable the block
-- note: titles marked with a (*) are a continuation
-- and will display data only (no title's repetition)
-- see samples.lua for the physical division
--
local tSamplesBlocks =
{
	-- 7 bits only
	--------------
	
	{false,		"Basic Latin"},
	
	-- c2-df (2 bytes)
	------------------	

	{false,		"Latin-1 Supplement"},
	{false,		"Latin Extended-A"},
	{false,		"Latin Extended-B"},
	{false,		"Latin Extended-B (*)"},
	{false,		"IPA Extensions"},
	{false,		"IPA Extensions (*)"},
	{false,		"Spacing Modifier Letters"},
	{false,		"Spacing Modifier Letters (*)"},
	{false,		"Combining Diacritical Marks"},
	{false,		"Combining Diacritical Marks (*)"},
	{false,		"Greek and Coptic"},
	{false,		"Greek and Coptic (*)"},
	{false,		"Cyrillic"},
	{false,		"Cyrillic Supplement"},
	{false,		"Armenian"},
	{false,		"Armenian (*)"},
	{false,		"Armenian (*)"},
	{false,		"Hebrew"},
	{false,		"Hebrew (*)"},
	{false,		"Arabic"},
	{false,		"Arabic (*)"},
	{false,		"Syriac"},
	{false,		"Syriac (*)"},
	{false,		"Arabic Supplement"},
	{false,		"Thaana"},
	{false,		"NKo"},

	-- e0-ef block (3 bytes)
	------------------------
	
	{false,		"Samaritan"},
	{false,		"Mandaic"},
	{false,		"Syriac Supplement"},
	{false,		"No_Block"},
	{false,		"No_Block"},
	{false,		"Arabic Extended-A"},
	{false,		"Devanagari"},
	{false,		"Bengali"},
	{false,		"Gurmukhi"},
	{false,		"Gujarati"},
	{false,		"Oriya"},
	{false,		"Tamil"},
	{false,		"Telugu"},
	{false,		"Kannada"},
	{false,		"Malayalam"},
	{false,		"Sinhala"},
	{false,		"Thai"},
	{false,		"Lao"},
	{false,		"Tibetan"},
	{false,		"Myanmar"},
	{false,		"Myanmar (*)"},
	{false,		"Georgian"},
	{false,		"Georgian (*)"},
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
	{true,		"ea ad ??"},							-- starts here
	{true,		"ea ae-bf ??"},
	{true,		"ee CJK ??"},
	{true,		"ee CJK ??"},
	{true,		"ee 80-bf ??"},
	{true,		"ef 80-ab ??	"},	
	{true,		"Alphabetic Presentation Forms"},
	{true,		"Alphabetic Presentation Forms (*)"},	
	{true,		"Arabic Presentation Forms-A"},
	{true,		"Arabic Presentation Forms-A (*)"},
	{true,		"Variation Selectors"},
	{true,		"Vertical Forms"},
	{true,		"Combining Half Marks"},
	{true,		"ee ??"},
	{true,		"ee ??"},
	{true,		"Small Form Variants"},
	{true,		"ee ??"},
	{true,		"ee ??"},
	{true,		"Halfwidth and Fullwidth Forms"},
	{true,		"Halfwidth and Fullwidth Forms (*)"},
	{true,		"Specials"},
	
	-- f0-f4 block (4 bytes)
	------------------------
	
	{false,		"Linear B Syllabary"},
	{false,		"Linear B Ideograms"},
	{false,		"Aegean Numbers"},	
	{false,		"Ancient Greek Numbers"},	
	{false,		"Ancient Greek Numbers (*)"},
	{false,		"Ancient Symbols"},
	{false,		"Ancient Symbols (*)"},
	{false,		"Phaistos Disc"},	
	{false,		"f0 88 ??"},
	{false,		"f0 89 ??"},
	{false,		"Lycian"},	
	{false,		"Carian"},	
	{false,		"Carian (*)"},	
	{false,		"f0 8b ??"},
	{false,		"Old Italic"},
	{false,		"Gothic"},
	{false,		"Gothic (*)"},	
	{false,		"Old Permic"},
	{false,		"Ugaritic"},	
	{false,		"Old Persian"},	
	{false,		"Old Persian (*)"},	
	{false,		"f0 90 8f ??"},	
	{false,		"Deseret"},
	{false,		"Deseret (*)"},
	{false,		"Shavian"},
	{false,		"f0 92 ??"},	
	{false,		"Osage"},
	{false,		"Osage (*)"},
	{false,		"Elbasan"},
	{false,		"Caucasian Albanian"},
	{false,		"Caucasian Albanian (*)"},
	{false,		"f0 95 ??"},
	{false,		"f0 96-97 ??"},
	{false,		"Linear A"},	
	{false,		"Cypriot Syllabary"},
	{false,		"f0 a1 ??"},
	{false,		"Palmyrene"},
	{false,		"f0 a2-a3 ??"},
	{false,		"Phoenician"},
	{false,		"Lydian"},
	{false,		"f0 a5-af ??"},
	{false,		"Old Turkic"},
	{false,		"Old Turkic (*)"},
	{false,		"f0 b1 ??"},
	{false,		"Old Hungarian"},
	{false,		"f0 90 b4-bf ??"},
	{false,		"f0 91 88-a7 ??"},
	{false,		"Zanabazar Square"},
	{false,		"Zanabazar Square (*)"},
	{false,		"f0 91 a9 ??"},
	{false,		"f0 91 aa-bf ??"},
	{false,		"Cuneiform"},
	{false,		"Cuneiform Numbers and Punctuation"},
	{false,		"Early Dynastic Cuneiform"},
	{false,		"Early Dynastic Cuneiform (*)"},
	{false,		"f0 92 95 ??"},
	{false,		"f0 92 96 bf ??"},
	{false,		"Egyptian Hieroglyphs"},
	{false,		"f0 93 91 ??"},
	{false,		"f0 94-95 ??"},
	{false,		"f0 96 80 ??"},
	{false,		"f0 96-bf ??"},
	{false,		"Ideographic Symbols and Punctuation"},
	{false,		"f0 97-9a ??"},
	{false,		"f0 9b 80 ??"},	
	{false,		"Duployan"},
	{false,		"Duployan (*)"},
	{false,		"f0 9b b2 ??"},
	{false,		"f0 9b  b3-bf ??"},
	{false,		"f0 9c ??"},
	{false,		"f0 9d ??"},
	{false,		"Musical Symbols"},
	{false,		"f0 9d 88 ??"},
	{false,		"f0 9d 8d ??"},
	{false,		"Counting Rod Numerals"},
	{false,		"f0 9d 8e ??"},
	{false,		"Mathematical Alphanumeric Symbols"},
	{false,		"Sutton SignWriting"},
	{false,		"Sutton SignWriting (*)"},
	{false,		"f0 9d aa ??"},
	{false,		"f0 9d ab-bf ??"},
	{false,		"f0 9e 80 ??"},
	{false,		"Arabic Mathematical Alphabetic Symbols"},
	{false,		"f0 9e bc ??"},
	{false,		"Mahjong Tiles"},
	{false,		"Domino Tiles"},
	{false,		"Domino Tiles (*)"},
	{false,		"Domino Tiles (*)"},
	{false,		"Playing Cards"},
	{false,		"Playing Cards (*)"},
	{false,		"Enclosed Alphanumeric Supplement"},
	{false,		"Enclosed Ideographic Supplement"},
	{false,		"Miscellaneous Symbols and Pictographs"},
	{false,		"Emoticons"},
	{false,		"Emoticons (*)"},	
	{false,		"Ornamental Dingbats"},
	{false,		"Transport and Map Symbols"},
	{false,		"Alchemical Symbols"},
	{false,		"Geometric Shapes Extended"},
	{false,		"Supplemental Arrows-C"},
	{false,		"Supplemental Symbols and Pictographs"},
	{false,		"Chess Symbols"},
	{false,		"Chess Symbols (*)"},
	{false,		"No_Block"},
	{false,		"No_Block"},
	{false,		"CJK Unified Ideographs Extension B"},
	{false,		"CJK Unified Ideographs Extension B (*)"},
	{false,		"CJK Unified Ideographs Extension B (*)"},
	{false,		"No_Block"},
	{false,		"CJK Unified Ideographs Extension C"},
	{false,		"CJK Unified Ideographs Extension C (*)"},
	{false,		"CJK Unified Ideographs Extension D"},
	{false,		"CJK Unified Ideographs Extension D (*)"},
	{false,		"CJK Unified Ideographs Extension E"},
	{false,		"CJK Unified Ideographs Extension E (*)"},
	{false,		"CJK Unified Ideographs Extension E (*)"},
	{false,		"CJK Unified Ideographs Extension E (*)"},
	{false,		"CJK Unified Ideographs Extension F"},
	{false,		"CJK Unified Ideographs Extension F (*)"},
	{false,		"CJK Unified Ideographs Extension F (*)"},
	{false,		"CJK Unified Ideographs Extension F (*)"},
	{false,		"CJK Unified Ideographs Extension F (*)"},
	{false,		"No_Block"},
	{false,		"No_Block"},
	{false,		"No_Block"},
	{false,		"No_Block"},
	{false,		"CJK Compatibility Ideographs Supplement"},
	{false,		"CJK Compatibility Ideographs Supplement (*)"},
	{false,		"No_Block"},
	{false,		"No_Block"},
	{false,		"No_Block"},
	
	{false,		"-> Private Area B <-"},
	{false,		"-> Private Area C <-"},
	{false,		"-> Private Area D <-"},
	{false,		"-> Unknown Extras <-"},
	{false,		"-> Private Area E <-"},
	{false,		"-> Private Area F <-"},
	
}

-- ----------------------------------------------------------------------------
--
local tSetupInf =
{
	-- importing the file
	--
	["InFile"]		= "testfiles\\__Test_5.txt",		-- import file name
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
	["ByBlocksRow"] = tSamplesBlocks,					-- table listing the UTF blocks to generate
	["SamplesFile"]	= "testfiles\\__Test_xx.txt",		-- output file name
	
	-- display
	--
	["ByteFont"]	= { 9.5, tPreferFont[1]},			-- left display (codes)
	["TextFont"]	= {13.5, tPreferFont[1]},			-- right display (text)
	["FontStep"]	= 1.5,								-- step for increasing text's font size
	["Columns"]		= 16,								-- format number of columns
	["Interleave"]	= false,							-- highlight even columns
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
}

-- ----------------------------------------------------------------------------
--
return tSetupInf

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
