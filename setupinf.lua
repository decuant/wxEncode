-------------------------------------------------------------------------------

local tSetupInf =
{
	-- importing the file
	--
	["InFile"]		= "testfiles\\__Test_4.txt",
	["ReadMode"]	= "r",

	-- saving the file
	--
	["OutFile"]		= "testfiles\\__Test_0.txt",
	["WriteMode"]	= "w",
	
	-- test file
	--
	["TestEncode"]	= "UTF_8",								-- ASCII/UTF_8

	-- display
	--
	["ByteFont"]	= {12, "Source Code Pro"},			-- left display (codes)
	["TextFont"]	= {11, "Lucida Sans Unicode"},	-- right display (text)
	["Columns"]		= 16,										-- format number of columns
	["Format"]		= "Hexadecimal",						-- Oct/Dec/Hex
}

return tSetupInf

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
