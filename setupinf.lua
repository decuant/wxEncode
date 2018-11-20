-- ----------------------------------------------------------------------------
--
-- Setupinf - setup for the application
--
-- ----------------------------------------------------------------------------

local tSetupInf =
{
	-- importing the file
	--
	["InFile"]		= "testfiles\\__Test_2.txt",
	["ReadMode"]	= "r",

	-- saving the file
	--
	["OutFile"]		= "testfiles\\__Test_0.txt",
	["WriteMode"]	= "w",

	-- samples file
	--
	["TestEncode"]	= "UTF_8",							-- ASCII/UTF_8

	-- display
	--
	["ByteFont"]	= {13, "Liberation Mono"},			-- left display (codes)
	["TextFont"]	= {17, "Source Code Pro"}, -- "Carlito"},					-- right display (text)
	["Columns"]		= 16,								-- format number of columns
	["Format"]		= "Hexadecimal",					-- Oct/Dec/Hex
}

-- ----------------------------------------------------------------------------
--
return tSetupInf

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
