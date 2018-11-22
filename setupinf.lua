-- ----------------------------------------------------------------------------
--
-- Setupinf - setup for the application
--
-- ----------------------------------------------------------------------------

local tSetupInf =
{
	-- importing the file
	--
	["InFile"]		= "testfiles\\__Test_99.txt",
	["ReadMode"]	= "r",
	["Autoload"]	= true,
	["AutoCheck"]	= true,

	-- saving the file
	--
	["OutFile"]		= "testfiles\\__Test_0.txt",
	["WriteMode"]	= "w",

	-- samples file
	--
	["TestEncode"]	= "UTF_8",							-- ASCII/UTF_8

	-- display
	--
	["ByteFont"]	= {14, "Liberation Mono"},			-- left display (codes)
	["TextFont"]	= {14, "Liberation Mono"}, -- "Carlito"},					-- right display (text)
	["Columns"]		= 16,								-- format number of columns
	["Format"]		= "Hexadecimal",					-- Oct/Dec/Hex
	["TabSize"]		= 4,								-- convert tab to 'n' chars
	["Underline"]	= true,								-- underline bytes below 0x20
	["ColorCodes"]	= true,								-- highlight Unicode bytes group
	["Inverted"]	= false,							-- invert display colors
	["CopyOption"]	= "Word",							-- Byte/UTF_8/Word/Line
}

-- ----------------------------------------------------------------------------
--
return tSetupInf

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
