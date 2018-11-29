-- ----------------------------------------------------------------------------
--
--  Samples - create a number of Unicode chars by blocks
--
-- (see List of Unicode characters - Wikipedia)
--
-- ----------------------------------------------------------------------------

local _format	= string.format
local _insert	= table.insert
local _concat	= table.concat

-- ----------------------------------------------------------------------------
--
local function BlockHeader(inText, inUTFMark)
	
	inUTFMark = inUTFMark or 0x00
	
	local sHeader = _format("‖%2d‖ %s", inUTFMark, inText)
	local sUnderL = string.rep("▬", #sHeader)
	
	return _format("%s\n%s\n", sHeader, sUnderL )
end

-- ----------------------------------------------------------------------------
--
local tFmtShowCodes =
{
	"%04x: [ %c ]",
	"%04x: [ %c%c ]",
	"%04x: [ %c%c%c ]",
	"%04x: [ %c%c%c%c ]",
}

local tFmtHideCodes =
{
	"%c",
	"%c%c",
	"%c%c%c",
	"%c%c%c%c",
}

-- ----------------------------------------------------------------------------
--
local function Create(inFilename, inMode, inFormat, inCompactOpt, inCompactCols)
	
	local fhTgt = io.open(inFilename, inMode)
	if not fhTgt then return false end
	
	local tOutFormat = tFmtHideCodes
	if not inCompactOpt then tOutFormat = tFmtShowCodes end
	local sCatChar = " "
	if not inCompactOpt then sCatChar = "\n" end
	
	inCompactCols = inCompactCols or 10
	if 10 > inCompactCols then inCompactCols = 10 end
	local iCmpctCol = 0
	
	local sOutFormat1 = tOutFormat[1]
	local sOutFormat2 = tOutFormat[2]
	local sOutFormat3 = tOutFormat[3]
	local sOutFormat4 = tOutFormat[4]
	
	local tLineOut			-- table for one-time write to file
	local dwStart			-- start value
	local dwEnd				-- end value
	local dwUTF				-- Unicode code (c0, c1, d0, d1, etc)
	local dwCode			-- UTF_8 mark byte
	local dwSwitch1			-- second (if any) byte
	local dwSwitch2			-- third (if any) byte
	local dwValue			-- selector
	local sLine				-- temporary line
	
	
	function _reformat(inFormat, inParam1, inParam2, inParam3, inParam4, inParam5)
		
		if not inCompactOpt then
			return _format(inFormat, inParam1, inParam2, inParam3, inParam4, inParam5)
		end

		return _format(inFormat, inParam2, inParam3, inParam4, inParam5)	
	end
	
	
	function InsertLineBreak()
			
		iCmpctCol = iCmpctCol + 1
		if inCompactOpt and (0 == (iCmpctCol % inCompactCols)) then
			_insert(tLineOut, "\n")
		end
	end

	---------------------------------------------
	-- Basic Latin
	--
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x20
	dwEnd	 = 0x7e
	dwUTF	 = 0xc0

	_insert(tLineOut, BlockHeader("Basic Latin", dwUTF))
	
	for dwCurrent = dwStart, dwEnd do

		sLine = _reformat(sOutFormat1, dwCurrent, dwCurrent)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end

	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Latin-1 Supplement
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0xa0
	dwEnd	 = 0xff
	dwUTF	 = 0xc2
	
	_insert(tLineOut, BlockHeader("Latin-1 Supplement", dwUTF))
	
	for dwCurrent = dwStart, dwEnd do

		if 2 == inFormat then
			-- format UTF_8
			--			
			if 0xc0 > dwCurrent then

				dwCode	= dwUTF
				dwValue	= dwCurrent
			else

				dwCode	= dwUTF + 1
				dwValue	= dwCurrent - 0x40
			end
			
			sLine = _reformat(sOutFormat2, dwCurrent, dwCode, dwValue)
			_insert(tLineOut, sLine)			
		else
			-- format ASCII
			--
			sLine = _reformat(sOutFormat1, dwCurrent, dwCurrent)
			_insert(tLineOut, sLine)
		end
		
		InsertLineBreak()
	end

	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	-- can't proceed further, we have 1 byte only
	--
	if (1 == inFormat) then 
		fhTgt:write("\n   eof\n---------\n\n")
		fhTgt:close()
	
		return true	
	end

	---------------------------------------------
	-- Latin Extended-A
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x0100
	dwEnd	 = 0x017f
	dwUTF	 = 0xc4
	
	_insert(tLineOut, BlockHeader("Latin Extended-A", dwUTF))
	
	for dwCurrent = dwStart, dwEnd do
		
		if 0x0140 > dwCurrent then

			dwCode	= dwUTF
			dwValue	= dwCurrent - 0x80			
		else

			dwCode	= dwUTF + 1
			dwValue	= dwCurrent - 0xc0
		end
		
		sLine = _reformat(sOutFormat2, dwCurrent, dwCode, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()		
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Latin Extended-B
	--
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x0180
	dwEnd	 = 0x024f
	dwUTF	 = 0xc6
	
	_insert(tLineOut, BlockHeader("Latin Extended-B", dwUTF))

	for dwCurrent = dwStart, dwEnd do

		if 0x01c0 > dwCurrent then
			
			dwCode	= dwUTF
			dwValue	= dwCurrent - 0x0100			
			
		elseif 0x0200 > dwCurrent then
			
			dwCode	= dwUTF + 1
			dwValue	= dwCurrent - 0x140
			
		elseif 0x0240 > dwCurrent then
			
			dwCode	= dwUTF + 2
			dwValue	= dwCurrent - 0x0180

		else
		
			dwCode	= dwUTF + 3
			dwValue	= dwCurrent - 0x01c0			
		end
		
		sLine = _reformat(sOutFormat2, dwCurrent, dwCode, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Spacing modifier letters
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x02b0
	dwEnd	 = 0x02ff
	dwUTF	 = 0xca
	
	_insert(tLineOut, BlockHeader("Spacing modifier letters", dwUTF))
	
	for dwCurrent = dwStart, dwEnd do
		
		if 0x02c0 > dwCurrent then

			dwCode	= dwUTF
			dwValue	= dwCurrent - 0x0200		
			
		else

			dwCode	= dwUTF + 1
			dwValue	= dwCurrent - 0x0240
		end
		
		sLine = _reformat(sOutFormat2, dwCurrent, dwCode, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Greek and Coptic
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x0370
	dwEnd	 = 0x03ff
	dwUTF	 = 0xcd
	
	_insert(tLineOut, BlockHeader("Greek and Coptic", dwUTF))

	for dwCurrent = dwStart, dwEnd do
		
		if 0x0380 > dwCurrent then

			dwCode	= dwUTF
			dwValue	= dwCurrent - 0x02c0
			
		elseif 0x03c0 > dwCurrent then

			dwCode	= dwUTF + 1
			dwValue	= dwCurrent - 0x0300
			
		else

			dwCode	= dwUTF + 2
			dwValue	= dwCurrent - 0x0340			
		end
		
		sLine = _reformat(sOutFormat2, dwCurrent, dwCode, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Cyrillic
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x0400
	dwEnd	 = 0x04ff
	dwUTF	 = 0xd0
	
	_insert(tLineOut, BlockHeader("Cyrillic", dwUTF))
	
	for dwCurrent = dwStart, dwEnd do
		
		if 0x0440 > dwCurrent then

			dwCode	= dwUTF
			dwValue	= dwCurrent - 0x0280
			
		elseif 0x0480 > dwCurrent then

			dwCode	= dwUTF + 1
			dwValue	= dwCurrent - 0x03c0
			
		elseif 0x04c0 > dwCurrent then

			dwCode	= dwUTF + 2
			dwValue	= dwCurrent - 0x0400	
			
		else

			dwCode	= dwUTF + 3
			dwValue	= dwCurrent - 0x0440	
		end
		
		sLine = _reformat(sOutFormat2, dwCurrent, dwCode, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
		
	---------------------------------------------
	-- Latin Extended Additional
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x1e00
	dwEnd	 = 0x1eff
	dwUTF	 = 0xe1
	dwSwitch1 = 0xb8
	
	_insert(tLineOut, BlockHeader("Latin Extended Additional", dwUTF))	

	for dwCurrent = dwStart, dwEnd do
		
		if 0x1e40 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0xb8
			dwValue	= dwCurrent - 0x1d80

		elseif 0x1e80 > dwCurrent then
			dwCode	= dwUTF
			dwSwitch1 = 0xb9
			dwValue	= dwCurrent - 0x1dc0

		elseif 0x1ec0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0xba
			dwValue	= dwCurrent - 0x1e00
			
		else

			dwCode	= dwUTF
			dwSwitch1 = 0xbb
			dwValue	= dwCurrent - 0x1e40		
			
		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))

	---------------------------------------------
	-- Unicode symbols
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x2013
	dwEnd	 = 0x204a
	dwUTF	 = 0xe2
	dwSwitch1 = 0x80

	_insert(tLineOut, BlockHeader("Unicode symbols", dwUTF))

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2040 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x80
			dwValue	= dwCurrent - 0x1f80
			
		else

			dwCode	= dwUTF
			dwSwitch1 = 0x81
			dwValue	= dwCurrent - 0x1fc0
		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Superscripts and Subscripts
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x2070
	dwEnd	 = 0x209c
	dwUTF	 = 0xe2
	dwSwitch1 = 0x81
	
	_insert(tLineOut, BlockHeader("Superscripts and Subscripts", dwUTF))

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2080 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x81
			dwValue	= dwCurrent - 0x1fc0
			
		else

			dwCode	= dwUTF
			dwSwitch1 = 0x82
			dwValue	= dwCurrent - 0x2000
		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Currency Symbols
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x20a0
	dwEnd	 = 0x20bf
	dwUTF	 = 0xe2
	dwSwitch1 = 0x82

	_insert(tLineOut, BlockHeader("Currency Symbols", dwUTF))

	for dwCurrent = dwStart, dwEnd do

		dwCode	= dwUTF
		dwSwitch1 = 0x82
		dwValue	= dwCurrent - 0x2000

		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Letterlike Symbols
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x2100
	dwEnd	 = 0x214f
	dwUTF	 = 0xe2
	dwSwitch1 = 0x84
	
	_insert(tLineOut, BlockHeader("Letterlike Symbols", dwUTF))
	
	for dwCurrent = dwStart, dwEnd do
		
		if 0x2140 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x84
			dwValue	= dwCurrent - 0x2080
			
		else

			dwCode	= dwUTF
			dwSwitch1 = 0x85
			dwValue	= dwCurrent - 0x20c0
		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Number Forms
	--
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x2150
	dwEnd	 = 0x218b
	dwUTF	 = 0xe2
	dwSwitch1 = 0x85
	
	_insert(tLineOut, BlockHeader("Number Forms", dwUTF))
	
	for dwCurrent = dwStart, dwEnd do
		
		if 0x2180 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x85
			dwValue	= dwCurrent - 0x20c0
			
		else

			dwCode	= dwUTF
			dwSwitch1 = 0x86
			dwValue	= dwCurrent - 0x2100
		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Arrows
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x2190
	dwEnd	 = 0x21ff
	dwUTF	 = 0xe2
	dwSwitch1 = 0x86
	
	_insert(tLineOut, BlockHeader("Arrows", dwUTF))

	for dwCurrent = dwStart, dwEnd do
		
		if 0x21c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x86
			dwValue	= dwCurrent - 0x2100
			
		else

			dwCode	= dwUTF
			dwSwitch1 = 0x87
			dwValue	= dwCurrent - 0x2140
		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
		
	---------------------------------------------
	-- Mathematical operators
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x2200
	dwEnd	 = 0x22ff
	dwUTF	 = 0xe2
	dwSwitch1 = 0x88
	
	_insert(tLineOut, BlockHeader("Mathematical operators", dwUTF))

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2240 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x88
			dwValue	= dwCurrent - 0x2180

		elseif 0x2280 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x89
			dwValue	= dwCurrent - 0x21c0

		elseif 0x22c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x8a
			dwValue	= dwCurrent - 0x2200
			
		else

			dwCode	= dwUTF
			dwSwitch1 = 0x8b
			dwValue	= dwCurrent - 0x2240			
		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Miscellaneous Technical
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x2300
	dwEnd	 = 0x23ff
	dwUTF	 = 0xe2
	dwSwitch1 = 0x8c
	
	_insert(tLineOut, BlockHeader("Miscellaneous Technical", dwUTF))

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2340 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x8c
			dwValue	= dwCurrent - 0x2280

		elseif 0x2380 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x8d
			dwValue	= dwCurrent - 0x22c0

		elseif 0x23c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x8e
			dwValue	= dwCurrent - 0x2300
			
		else

			dwCode	= dwUTF
			dwSwitch1 = 0x8f
			dwValue	= dwCurrent - 0x2340			
		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))

	---------------------------------------------
	-- Enclosed Alphanumerics
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x2460
	dwEnd	 = 0x24ff
	dwUTF	 = 0xe2
	dwSwitch1 = 0x91
	
	_insert(tLineOut, BlockHeader("Enclosed Alphanumerics", dwUTF))	

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2480 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x91
			dwValue	= dwCurrent - 0x23c0

		elseif 0x24c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x92
			dwValue	= dwCurrent - 0x2400

		else

			dwCode	= dwUTF
			dwSwitch1 = 0x93
			dwValue	= dwCurrent - 0x2440

		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Box Drawing
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x2500
	dwEnd	 = 0x257f
	dwUTF	 = 0xe2
	dwSwitch1 = 0x94
	
	_insert(tLineOut, BlockHeader("Box Drawing", dwUTF))	

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2540 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x94
			dwValue	= dwCurrent - 0x2480

		elseif 0x2580 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x95
			dwValue	= dwCurrent - 0x24c0
			
		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Block Elements
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x2580
	dwEnd	 = 0x259f
	dwUTF	 = 0xe2
	dwSwitch1 = 0x96
	
	_insert(tLineOut, BlockHeader("Block Elements", dwUTF))	

	for dwCurrent = dwStart, dwEnd do
		
		if 0x25a0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x96
			dwValue	= dwCurrent - 0x2500
			
		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Geometric Shapes
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x25a0
	dwEnd	 = 0x25ff
	dwUTF	 = 0xe2
	dwSwitch1 = 0x96
	
	_insert(tLineOut, BlockHeader("Geometric Shapes", dwUTF))	

	for dwCurrent = dwStart, dwEnd do
		
		if 0x25c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x96
			dwValue	= dwCurrent - 0x2500

		elseif 0x2600 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x97
			dwValue	= dwCurrent - 0x2540
			
		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Miscellaneous Symbols
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x2600
	dwEnd	 = 0x26ff
	dwUTF	 = 0xe2
	dwSwitch1 = 0x98
	
	_insert(tLineOut, BlockHeader("Miscellaneous Symbols", dwUTF))	

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2640 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x98
			dwValue	= dwCurrent - 0x2580

		elseif 0x2680 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x99
			dwValue	= dwCurrent - 0x25c0

		elseif 0x26c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0x9a
			dwValue	= dwCurrent - 0x2600
			
		else

			dwCode	= dwUTF
			dwSwitch1 = 0x9b
			dwValue	= dwCurrent - 0x2640		
			
		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))
	
	---------------------------------------------
	-- Supplemental Mathematical Operators
	--	
	iCmpctCol= 0
	tLineOut = { }
	dwStart	 = 0x2a00
	dwEnd	 = 0x2aff
	dwUTF	 = 0xe2
	dwSwitch1 = 0xa8
	
	_insert(tLineOut, BlockHeader("Supplemental Mathematical Operators", dwUTF))	

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2a40 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0xa8
			dwValue	= dwCurrent - 0x2980

		elseif 0x2a80 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0xa9
			dwValue	= dwCurrent - 0x29c0

		elseif 0x2ac0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch1 = 0xaa
			dwValue	= dwCurrent - 0x2a00
			
		else

			dwCode	= dwUTF
			dwSwitch1 = 0xab
			dwValue	= dwCurrent - 0x2a40		
			
		end
		
		sLine = _reformat(sOutFormat3, dwCurrent, dwCode, dwSwitch1, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))

	---------------------------------------------
	-- Musical Symbols
	--	
	iCmpctCol= 0
	tLineOut  = { }
	dwStart	  = 0x01d100
	dwEnd	  = 0x01d1ff
	dwUTF	  = 0xf0
	dwSwitch1 = 0x9d
	dwSwitch2 = 0x84
	
	_insert(tLineOut, BlockHeader("Musical Symbols", dwUTF))	

	for dwCurrent = dwStart, dwEnd do
		
		if 0x01d140 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x84
			dwValue	= dwCurrent - 0x01d080

		elseif 0x01d180 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x85
			dwValue	= dwCurrent - 0x01d0c0
			
		elseif 0x01d1c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x86
			dwValue	= dwCurrent - 0x01d100
			
		else

			dwCode	= dwUTF
			dwSwitch2 = 0x87
			dwValue	= dwCurrent - 0x01d140
			
		end
		
		sLine = _reformat(sOutFormat4, dwCurrent, dwCode, dwSwitch1, dwSwitch2, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))

	---------------------------------------------
	-- Mathematical Alphanumeric Symbols
	--	
	iCmpctCol= 0
	tLineOut  = { }
	dwStart	  = 0x01d400
	dwEnd	  = 0x01d7ff
	dwUTF	  = 0xf0
	dwSwitch1 = 0x9d
	dwSwitch2 = 0x90
	
	_insert(tLineOut, BlockHeader("Mathematical Alphanumeric Symbols", dwUTF))	

	for dwCurrent = dwStart, dwEnd do
		
		if 0x01d440 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x90
			dwValue	= dwCurrent - 0x01d380

		elseif 0x01d480 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x91
			dwValue	= dwCurrent - 0x01d3c0
			
		elseif 0x01d4c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x92
			dwValue	= dwCurrent - 0x01d400
			
		elseif 0x01d500 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x93
			dwValue	= dwCurrent - 0x01d440
			
		elseif 0x01d540 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x94
			dwValue	= dwCurrent - 0x01d480
			
		elseif 0x01d580 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x95
			dwValue	= dwCurrent - 0x01d4c0
			
		elseif 0x01d5c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x96
			dwValue	= dwCurrent - 0x01d500
			
		elseif 0x01d600 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x97
			dwValue	= dwCurrent - 0x01d540
		
		elseif 0x01d640 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x98
			dwValue	= dwCurrent - 0x01d580
			
		elseif 0x01d680 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x99
			dwValue	= dwCurrent - 0x01d5c0
			
		elseif 0x01d6c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x9a
			dwValue	= dwCurrent - 0x01d600
			
		elseif 0x01d700 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x9b
			dwValue	= dwCurrent - 0x01d640
			
		elseif 0x01d740 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x9c
			dwValue	= dwCurrent - 0x01d680
			
		elseif 0x01d780 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x9d
			dwValue	= dwCurrent - 0x01d6c0
			
		elseif 0x01d7c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x9e
			dwValue	= dwCurrent - 0x01d700
			
		else

			dwCode	= dwUTF
			dwSwitch2 = 0x9f
			dwValue	= dwCurrent - 0x01d740
			
		end
		
		sLine = _reformat(sOutFormat4, dwCurrent, dwCode, dwSwitch1, dwSwitch2, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))

-- domino and cards
-- 0xf0 0x9f 0x81

	---------------------------------------------
	-- Playing Cards
	--	
	iCmpctCol= 0
	tLineOut  = { }
	dwStart	  = 0x01f0a0
	dwEnd	  = 0x01f0ff
	dwUTF	  = 0xf0
	dwSwitch1 = 0x9f
	dwSwitch2 = 0x82
	
	_insert(tLineOut, BlockHeader("Playing Cards", dwUTF))	

	for dwCurrent = dwStart, dwEnd do
		
		if 0x01f0c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch2 = 0x82
			dwValue	= dwCurrent - 0x01f000
			
		else

			dwCode	= dwUTF
			dwSwitch2 = 0x83
			dwValue	= dwCurrent - 0x01f040
			
		end
		
		sLine = _reformat(sOutFormat4, dwCurrent, dwCode, dwSwitch1, dwSwitch2, dwValue)
		_insert(tLineOut, sLine)
		
		InsertLineBreak()
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, sCatChar))

	-- add more symbols here ...
	--

--
-- e2 9c looks emoji
-- e2 9d 

-- e2 a0 is braille
-- e2 a3

-- e3 8e is unit of measure
-- e3 8f 9f

-- extra alphabet
-- 0xf0 0x9d 0x90

-- emoji
-- 0xf0 0x9f 0x8c

-- mahjongg
-- 0xf0 0x9f 0x80

-- domino and cards
-- 0xf0 0x9f 0x81

	fhTgt:write("\n   eof\n---------\n\n")
	fhTgt:close()
	
	return true
end

local tUTF8Blocks =
{
	{0x20, 0x7e},										-- replaced original with printable	
	{0xc2, 0xc3, 0x80, 0xbf},							-- Latin-1 Supplement
	{0xc4, 0xc5, 0x80, 0xbf},							-- Latin Extended-A
	{0xc6, 0xc9, 0x80, 0xbf},							-- Latin Extended-B
	{0xca, 0xcb, 0x80, 0xbf},							-- Spacing modifier letters
	{0xcc, 0xcc, 0x80, 0xbf},							-- ??
	{0xcd, 0xcf, 0x80, 0xbf},							-- Greek and Coptic
	{0xd0, 0xd3, 0x80, 0xbf},							-- Cyrillic
	{0xd4, 0xd8, 0x80, 0xbf},							-- ??
	{0xd9, 0xdc, 0x80, 0xbf},							-- ??
	{0xdd, 0xdf, 0x80, 0xbf},							-- ??
	{0xe0, 0xe0, 0xa0, 0xbf, 0x80, 0xbf},				-- ??
	{0xe1, 0xe1, 0x80, 0xb7, 0x80, 0xbf},				-- ??
	{0xe1, 0xe1, 0xb8, 0xbb, 0x80, 0xbf},				-- Latin Extended Additional
	{0xe1, 0xe1, 0xbc, 0xbf, 0x80, 0xbf},				-- ??
	{0xe2, 0xe2, 0x80, 0x81, 0x80, 0xbf},				-- Unicode symbols
	{0xe2, 0xe2, 0x82, 0x82, 0x80, 0x9f},				-- Unicode symbols (contd)
	{0xe2, 0xe2, 0x82, 0x82, 0xa0, 0xbf},				-- Currency Symbols

	{0xe2, 0xe2, 0x83, 0x87, 0x80, 0xbf},				-- ??
	
	{0xe2, 0xe2, 0x88, 0x8b, 0x80, 0xbf},				-- Mathematical operators
	{0xe2, 0xe2, 0x8c, 0x93, 0x80, 0xbf},				-- Miscellaneous Technical
	{0xe2, 0xe2, 0x94, 0x97, 0x80, 0xbf},				-- Box Drawing
	{0xe2, 0xe2, 0x98, 0xbf, 0x80, 0xbf},				-- Miscellaneous Symbols	
	{0xe3, 0xe4, 0x80, 0xbf, 0x80, 0xbf},				-- ??
	{0xe5, 0x08, 0x80, 0xbf, 0x80, 0xbf},				-- ??
	{0xe9, 0xec, 0x80, 0xbf, 0x80, 0xbf},				-- ??
	{0xed, 0xed, 0x80, 0x9f, 0x80, 0xbf},				-- ??
	{0xee, 0xef, 0x80, 0xbf, 0x80, 0xbf},				-- ??
	{0xf0, 0xf0, 0x90, 0x9c, 0x80, 0xbf, 0x80, 0xbf},	-- ??	
	{0xf0, 0xf0, 0x9d, 0x9d, 0x80, 0x83, 0x80, 0xbf},	-- ??
	{0xf0, 0xf0, 0x9d, 0x9d, 0x84, 0x87, 0x80, 0xbf},	-- Musical symbols
	{0xf0, 0xf0, 0x9d, 0x9d, 0x88, 0x89, 0x80, 0xbf},	-- ??
	{0xf0, 0xf0, 0x9d, 0x9d, 0x90, 0x9f, 0x80, 0xbf},	-- Mathematical Alphanumeric Symbols
	{0xf0, 0xf0, 0x9d, 0x9d, 0xa0, 0xbf, 0x80, 0xbf},	-- ??
	{0xf0, 0xf0, 0x9e, 0x9f, 0x80, 0xbf, 0x80, 0xbf},	-- ??
	{0xf0, 0xf0, 0x9f, 0x9f, 0x82, 0x83, 0x80, 0xbf},	-- Playing Cards
	{0xf0, 0xf0, 0x9f, 0x9f, 0x84, 0xbf, 0x80, 0xbf},	-- ??
	{0xf0, 0xf0, 0xa0, 0xbf, 0x80, 0xbf, 0x80, 0xbf},	-- ??
	{0xf1, 0xf3, 0x80, 0xbf, 0x80, 0xbf, 0x80, 0xbf},	-- ??
	{0xf4, 0xf4, 0x80, 0x8f, 0x80, 0xbf, 0x80, 0xbf},	-- ??
}

-- ----------------------------------------------------------------------------
--
local function CreateByBlock(inBlock, inLabel, inFilename, inMode, inCompactCols)
	
	-- safety check
	--
	if 0 > inBlock or inBlock > #tUTF8Blocks then return false end
	
	local fhTgt = io.open(inFilename, inMode)
	if not fhTgt then return false end
	
	local tOutFormat = tFmtHideCodes
	local sCatChar = " "
	
	inCompactCols = inCompactCols or 10
	if 8 > inCompactCols then inCompactCols = 8 end
	local iCmpctCol = 0
	
	local sOutFormat1 = tOutFormat[1]
	local sOutFormat2 = tOutFormat[2]
	local sOutFormat3 = tOutFormat[3]
	local sOutFormat4 = tOutFormat[4]	
	
	local tUTFRow	= tUTF8Blocks[inBlock]
	
	---------------------------------------------
	-- By Block Number
	--	
	local tLineOut = { }
	local sHeader
	local sLine
	
	function InsertLineBreak()
			
		iCmpctCol = iCmpctCol + 1
		if (0 == (iCmpctCol % inCompactCols)) then
			_insert(tLineOut, "\n")
		end
	end	

	_insert(tLineOut, BlockHeader(inLabel, inBlock))
	
	--------------------------------------
	-- the very first row is the std ascii
	--
	if not tUTFRow[3] then 
		_insert(tLineOut, "\nASCII\n") 
		
		-- loop all codes
		for iCurUTF=tUTFRow[1], tUTFRow[2] do
			
			sLine = _format(sOutFormat1, iCurUTF)
			_insert(tLineOut, sLine)
			InsertLineBreak()				
		end
		
		_insert(tLineOut, "\n\n")
		fhTgt:write(_concat(tLineOut, sCatChar))
		
		fhTgt:close()
	
		return true
	end
	
	-----------------
	-- loop all codes
	--
	for iCurUTF=tUTFRow[1], tUTFRow[2] do
	
		if not tUTFRow[5] then
			
			sHeader= _format("\nUTF 0x%x\n", iCurUTF)
			_insert(tLineOut, sHeader)
		end

		for iByte1=tUTFRow[3], tUTFRow[4] do
			
			if tUTFRow[5] then
				
				if not tUTFRow[7] then
					
					sHeader= _format("\nUTF 0x%x 0x%x\n", iCurUTF, iByte1)
					_insert(tLineOut, sHeader)
				end

				for iByte2=tUTFRow[5], tUTFRow[6] do	
					
					if tUTFRow[7] then
						
						sHeader= _format("\nUTF 0x%x 0x%x 0x%x\n", iCurUTF, iByte1, iByte2)
						_insert(tLineOut, sHeader)

						
						for iByte3=tUTFRow[7], tUTFRow[8] do

							sLine = _format(sOutFormat4, iCurUTF, iByte1, iByte2, iByte3)	
							_insert(tLineOut, sLine)
							InsertLineBreak()
						end
					else
						
						sLine = _format(sOutFormat3, iCurUTF, iByte1, iByte2)
						_insert(tLineOut, sLine)
						InsertLineBreak()						
					end
				end
				
				_insert(tLineOut, "\n")
				fhTgt:write(_concat(tLineOut, sCatChar))
				tLineOut = { }					
				
			else
				
				sLine = _format(sOutFormat2, iCurUTF, iByte1)
				_insert(tLineOut, sLine)
				InsertLineBreak()				
			end
		end
		
		_insert(tLineOut, "\n")
		fhTgt:write(_concat(tLineOut, sCatChar))
		tLineOut = { }			
	end

	fhTgt:close()
	
	return true
end

-- ----------------------------------------------------------------------------
--
return 
{
	Create	= Create,
	ByBlock	= CreateByBlock,
}

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
