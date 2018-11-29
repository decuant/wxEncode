-- ----------------------------------------------------------------------------
--
-- Setupinf - setup for the application
--
-- ----------------------------------------------------------------------------
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
-- commenting a line wll disable the block
--
local tSamplesBlocks =
{
	-- 7 bits only
	--------------
	
--	{1,		"ASCII std"},			-- replaced original with printable	
	
	-- c2-df (2 bytes)
	------------------
	
--	{2,		"Latin-1 Supplement"},
--	{3,		"Latin Extended-A"},
--	{4,		"Latin Extended-B"},
--	{5,		"Spacing modifier letters"},
--	{6,		"??"},
--	{7,		"Greek and Coptic"},
--	{8,		"Cyrillic"},
--	{9,		"??"},
--	{10,	"??"},
--	{11,	"??"},
	
	-- e0-ef block (3 bytes)
	------------------------
	
--	{12,	"??"},
--	{13,	"??"},
--	{14,	"Latin Extended Additional"},
--	{15,	"??"},
	{16,	"Unicode symbols"},
	{17,	"Unicode symbols (contd)"},
	{18,	"Currency Symbols"},
	{19,	"??"},	
	{20,	"Mathematical operators"},
	{21,	"Miscellaneous Technical"},
	{22,	"Box Drawing"},
	{23,	"Miscellaneous Symbols	"},
--	{24,	"??"},
--	{25,	"??"},
--	{26,	"??"},
--	{27,	"??"},
--	{28,	"??"},
	
	-- f0-f4 block (4 bytes)
	------------------------
	
--	{29,	"??"},	
--	{30,	"??"},
--	{31,	"Musical symbols"},
--	{32,	"??"},
--	{33,	"Mathematical Alphanumeric Symbols"},
--	{34,	"??"},
--	{35,	"??"},
--	{36,	"Playing Cards"},
--	{37,	"??"},
--	{38,	"??"},
--	{39,	"??"},
--	{40,	"??"},
	
}

-- ----------------------------------------------------------------------------
--
local tSetupInf =
{
	-- importing the file
	--
	["InFile"]		= "testfiles\\__Test_xx.txt",		-- import file name
	["ReadMode"]	= "r",								-- r/rb
	["AutoLoad"]	= true,								-- load at startup time
	
	-- checking validity
	--
	["Pedantic"]	= false,							-- trace a line for each error
	["AutoCheck"]	= false,							-- check validity at load time

	-- saving the file
	--
	["OutFile"]		= "testfiles\\__Test_aa.txt",		-- output file name
	["WriteMode"]	= "w",								-- w/wb/a  with + option

	-- samples file creation
	--
	["SamplesEnc"]	= "UTF_8",							-- ASCII/UTF_8
	["Compact"]		= true,								-- compact output
	["CompactCols"]	= 16,								-- number of columns when in compact mode
	["ByBlocksRow"] = tSamplesBlocks,					-- table listing the UTF blocks to generate
	["SamplesFile"]	= "testfiles\\__Test_xx.txt",		-- output file name
	
	-- display
	--
	["ByteFont"]	= {12, tPreferFont[1]},				-- left display (codes)
	["TextFont"]	= {17, tPreferFont[1]},				-- right display (text)
	["Columns"]		= 30,								-- format number of columns
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
	["CopyOption"]	= "Line",							-- Byte/UTF_8/Word/Line (textual word)
--	["PasteOption"] = "Discard",						-- handling of errors - Discard/Convert/Plain
--	["SelectOption"]= "Line",							-- selection mode - Line/All
	
	-- extra
	--
	["TimeDisplay"]	= 5,								-- seconds of message in status bar
	["TraceMemory"]	= true,								-- enable tracing of memory usage
}

-- ----------------------------------------------------------------------------
--
return tSetupInf

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
