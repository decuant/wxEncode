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
local function BlockHeader(inText)
	
	return _format("%s\n%s\n", inText, string.rep("=", #inText))
end

-- ----------------------------------------------------------------------------
--
local function Create(inFilename, inMode, inFormat)
	
	local fhTgt = io.open(inFilename, inMode)
	if not fhTgt then return false end
	
	local tLineOut			-- table for one-time write to file
	local dwStart			-- start code
	local dwEnd				-- end code
	local dwUTF				-- Unicode code (c0, c1, d0, d1, etc)
	local dwCode			-- first byte of code
	local dwSwitch			-- second (if any) byte of code
	local dwValue			-- third byte of code
	local sLine				-- temporary line

	---------------------------------------------
	-- Basic Latin
	--
	tLineOut = { }
	dwStart	 = 0x20
	dwEnd	 = 0x7e
	dwUTF	 = 0xc0
	
	_insert(tLineOut, BlockHeader("Basic Latin"))
	
	for dwCurrent = dwStart, dwEnd do

		sLine = _format("%04x: [ %c ]", dwCurrent, dwCurrent)
		_insert(tLineOut, sLine)
	end

	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))
	
	---------------------------------------------
	-- Latin-1 Supplement
	--	
	tLineOut = { }
	dwStart	 = 0xa0
	dwEnd	 = 0xff
	dwUTF	 = 0xc2
	
	_insert(tLineOut, BlockHeader("Latin-1 Supplement"))
	
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
			
			sLine = _format("%04x: [ %c%c ]", dwCurrent, dwCode, dwValue)
			_insert(tLineOut, sLine)			
		else
			-- format ASCII
			--
			sLine = _format("%04x: [ %c ]", dwCurrent, dwCurrent)
			_insert(tLineOut, sLine)
		end
	end

	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))
	
	-- can't proceed further, we have 1 byte only
	--
	if 1 == inFormat then goto closeFile end
	
	---------------------------------------------
	-- Latin Extended-A
	--	
	tLineOut = { }
	dwStart	 = 0x0100
	dwEnd	 = 0x017f
	dwUTF	 = 0xc4
	
	_insert(tLineOut, BlockHeader("Latin Extended-A"))
	
	for dwCurrent = dwStart, dwEnd do
		
		if 0x0140 > dwCurrent then

			dwCode	= dwUTF
			dwValue	= dwCurrent - 0x80			
		else

			dwCode	= dwUTF + 1
			dwValue	= dwCurrent - 0xc0
		end
		
		sLine = _format("%04x: [ %c%c ]", dwCurrent, dwCode, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))
	
	---------------------------------------------
	-- Latin Extended-B
	--
	tLineOut = { }
	dwStart	 = 0x0180
	dwEnd	 = 0x024f
	dwUTF	 = 0xc6
	
	_insert(tLineOut, BlockHeader("Latin Extended-B"))

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
		
		sLine = _format("%04x: [ %c%c ]", dwCurrent, dwCode, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))
	
	---------------------------------------------
	-- Spacing modifier letters
	--	
	tLineOut = { }
	dwStart	 = 0x02b0
	dwEnd	 = 0x02ff
	dwUTF	 = 0xca
	
	_insert(tLineOut, BlockHeader("Spacing modifier letters"))
	
	for dwCurrent = dwStart, dwEnd do
		
		if 0x02c0 > dwCurrent then

			dwCode	= dwUTF
			dwValue	= dwCurrent - 0x0200		
			
		else

			dwCode	= dwUTF + 1
			dwValue	= dwCurrent - 0x0240
		end
		
		sLine = _format("%04x: [ %c%c ]", dwCurrent, dwCode, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))
	
	---------------------------------------------
	-- Greek and Coptic
	--	
	tLineOut = { }
	dwStart	 = 0x0370
	dwEnd	 = 0x03ff
	dwUTF	 = 0xcd
	
	_insert(tLineOut, BlockHeader("Greek and Coptic"))

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
		
		sLine = _format("%04x: [ %c%c ]", dwCurrent, dwCode, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))
	
	---------------------------------------------
	-- Cyrillic
	--	
	tLineOut = { }
	dwStart	 = 0x0400
	dwEnd	 = 0x04ff
	dwUTF	 = 0xd0
	
	_insert(tLineOut, BlockHeader("Cyrillic"))
	
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
		
		sLine = _format("%04x: [ %c%c ]", dwCurrent, dwCode, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))

	---------------------------------------------
	-- Unicode symbols
	--	
	tLineOut = { }
	dwStart	 = 0x2013
	dwEnd	 = 0x204a
	dwUTF	 = 0xe2
	dwSwitch = 0x80

	_insert(tLineOut, BlockHeader("Unicode symbols"))

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2040 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x80
			dwValue	= dwCurrent - 0x1f80
			
		else

			dwCode	= dwUTF
			dwSwitch = 0x81
			dwValue	= dwCurrent - 0x1fc0
		end
		
		sLine = _format("%04x: [ %c%c%c ]", dwCurrent, dwCode, dwSwitch, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))
	
	---------------------------------------------
	-- Superscripts and Subscripts
	--	
	tLineOut = { }
	dwStart	 = 0x2070
	dwEnd	 = 0x209c
	dwUTF	 = 0xe2
	dwSwitch = 0x81
	
	_insert(tLineOut, BlockHeader("Superscripts and Subscripts"))

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2080 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x81
			dwValue	= dwCurrent - 0x1fc0
			
		else

			dwCode	= dwUTF
			dwSwitch = 0x82
			dwValue	= dwCurrent - 0x2000
		end
		
		sLine = _format("%04x: [ %c%c%c ]", dwCurrent, dwCode, dwSwitch, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))		
	
	---------------------------------------------
	-- Currency Symbols
	--	
	tLineOut = { }
	dwStart	 = 0x20a0
	dwEnd	 = 0x20bf
	dwUTF	 = 0xe2
	dwSwitch = 0x82

	_insert(tLineOut, BlockHeader("Currency Symbols"))

	for dwCurrent = dwStart, dwEnd do

		dwCode	= dwUTF
		dwSwitch = 0x82
		dwValue	= dwCurrent - 0x2000

		sLine = _format("%04x: [ %c%c%c ]", dwCurrent, dwCode, dwSwitch, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))	
	
	---------------------------------------------
	-- Letterlike Symbols
	--	
	tLineOut = { }
	dwStart	 = 0x2100
	dwEnd	 = 0x214f
	dwUTF	 = 0xe2
	dwSwitch = 0x84
	
	_insert(tLineOut, BlockHeader("Letterlike Symbols"))
	
	for dwCurrent = dwStart, dwEnd do
		
		if 0x2140 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x84
			dwValue	= dwCurrent - 0x2080
			
		else

			dwCode	= dwUTF
			dwSwitch = 0x85
			dwValue	= dwCurrent - 0x20c0
		end
		
		sLine = _format("%04x: [ %c%c%c ]", dwCurrent, dwCode, dwSwitch, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))	
	
	---------------------------------------------
	-- Number Forms
	--
	tLineOut = { }
	dwStart	 = 0x2150
	dwEnd	 = 0x218b
	dwUTF	 = 0xe2
	dwSwitch = 0x85
	
	_insert(tLineOut, BlockHeader("Number Forms"))
	
	for dwCurrent = dwStart, dwEnd do
		
		if 0x2180 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x85
			dwValue	= dwCurrent - 0x20c0
			
		else

			dwCode	= dwUTF
			dwSwitch = 0x86
			dwValue	= dwCurrent - 0x2100
		end
		
		sLine = _format("%04x: [ %c%c%c ]", dwCurrent, dwCode, dwSwitch, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))		
	
	---------------------------------------------
	-- Arrows
	--	
	tLineOut = { }
	dwStart	 = 0x2190
	dwEnd	 = 0x21ff
	dwUTF	 = 0xe2
	dwSwitch = 0x86
	
	_insert(tLineOut, BlockHeader("Arrows"))

	for dwCurrent = dwStart, dwEnd do
		
		if 0x21c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x86
			dwValue	= dwCurrent - 0x2100
			
		else

			dwCode	= dwUTF
			dwSwitch = 0x87
			dwValue	= dwCurrent - 0x2140
		end
		
		sLine = _format("%04x: [ %c%c%c ]", dwCurrent, dwCode, dwSwitch, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))
		
	---------------------------------------------
	-- Mathematical operators
	--	
	tLineOut = { }
	dwStart	 = 0x2200
	dwEnd	 = 0x22ff
	dwUTF	 = 0xe2
	dwSwitch = 0x88
	
	_insert(tLineOut, BlockHeader("Mathematical operators"))

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2240 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x88
			dwValue	= dwCurrent - 0x2180

		elseif 0x2280 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x89
			dwValue	= dwCurrent - 0x21c0

		elseif 0x22c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x8a
			dwValue	= dwCurrent - 0x2200
			
		else

			dwCode	= dwUTF
			dwSwitch = 0x8b
			dwValue	= dwCurrent - 0x2240			
		end
		
		sLine = _format("%04x: [ %c%c%c ]", dwCurrent, dwCode, dwSwitch, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))
	
	---------------------------------------------
	-- Miscellaneous Technical
	--	
	tLineOut = { }
	dwStart	 = 0x2300
	dwEnd	 = 0x23ff
	dwUTF	 = 0xe2
	dwSwitch = 0x8c
	
	_insert(tLineOut, BlockHeader("Miscellaneous Technical"))

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2340 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x8c
			dwValue	= dwCurrent - 0x2280

		elseif 0x2380 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x8d
			dwValue	= dwCurrent - 0x22c0

		elseif 0x23c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x8e
			dwValue	= dwCurrent - 0x2300
			
		else

			dwCode	= dwUTF
			dwSwitch = 0x8f
			dwValue	= dwCurrent - 0x2340			
		end
		
		sLine = _format("%04x: [ %c%c%c ]", dwCurrent, dwCode, dwSwitch, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))

	---------------------------------------------
	-- Enclosed Alphanumerics
	--	
	tLineOut = { }
	dwStart	 = 0x2460
	dwEnd	 = 0x24ff
	dwUTF	 = 0xe2
	dwSwitch = 0x91
	
	_insert(tLineOut, BlockHeader("Enclosed Alphanumerics"))	

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2480 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x91
			dwValue	= dwCurrent - 0x23c0

		elseif 0x24c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x92
			dwValue	= dwCurrent - 0x2400

		else

			dwCode	= dwUTF
			dwSwitch = 0x93
			dwValue	= dwCurrent - 0x2440

		end
		
		sLine = _format("%04x: [ %c%c%c ]", dwCurrent, dwCode, dwSwitch, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))
	
	---------------------------------------------
	-- Miscellaneous Symbols
	--	
	tLineOut = { }
	dwStart	 = 0x2600
	dwEnd	 = 0x26ff
	dwUTF	 = 0xe2
	dwSwitch = 0x98
	
	_insert(tLineOut, BlockHeader("Miscellaneous Symbols"))	

	for dwCurrent = dwStart, dwEnd do
		
		if 0x2640 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x98
			dwValue	= dwCurrent - 0x2580

		elseif 0x2680 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x99
			dwValue	= dwCurrent - 0x25c0

		elseif 0x26c0 > dwCurrent then

			dwCode	= dwUTF
			dwSwitch = 0x9a
			dwValue	= dwCurrent - 0x2600
			
		else

			dwCode	= dwUTF
			dwSwitch = 0x9b
			dwValue	= dwCurrent - 0x2640			
		end
		
		sLine = _format("%04x: [ %c%c%c ]", dwCurrent, dwCode, dwSwitch, dwValue)
		_insert(tLineOut, sLine)
	end
	
	_insert(tLineOut, "\n")
	fhTgt:write(_concat(tLineOut, "\n"))

::closeFile::

	fhTgt:write("\n   eof\n---------\n\n")
	fhTgt:close()
	
	return true
end

-- ----------------------------------------------------------------------------
--
return 
{
	Create = Create
}

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
