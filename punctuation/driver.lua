-- ----------------------------------------------------------------------------
--
--  driver - extract all Unicode's codepoints that belong to punctuation
--
-- ----------------------------------------------------------------------------

package.path = package.path .. ";?.lua;"

local trace	= require "trace"		-- tracing
			  require "extrastr"	-- extra utf8 helpers
			  
local _format	= string.format
local _char		= string.char
local _strrep	= string.rep
local _concat	= table.concat
local _floor	= math.floor

-- ----------------------------------------------------------------------------
-- make a string array represent a valid hexadecimal code
--
local function _norm(inText)

	if 0 == inText:len() then return "00" end

	inText = inText:gsub(" ", "")
	inText = inText:upper()
	inText = inText:sub(1, math.min(#inText, 8))
	if 1 == (inText:len() % 2) then inText = "0" .. inText end

	return inText
end

-- ----------------------------------------------------------------------------
-- convert an ASCII string of hex values into a table of bytes
--
local function _text2hex(inText)

	local tBytes = { }
	local iHexVal

	for i=1, #inText do

		iHexVal = (inText:byte(i) - 0x30)
		if 0x09 < iHexVal then iHexVal = iHexVal - 0x07 end

		tBytes[#tBytes + 1] = iHexVal
	end

	return tBytes
end

-- ----------------------------------------------------------------------------
-- get a Unicode reference number and convert it to its UTF_8 representation
-- (assume a properly formatted hex number was passed as argument)
--
local function _uni2bytes(inText)

	local iSumUp = tonumber(inText, 16)
	local tBytes = _text2hex(inText)
	local sValue = ""
	local iByte1 = 0
	local iByte2 = 0
	local iByte3 = 0
	local iByte4 = 0

	-- sanity check
	--
	if not iSumUp then return sValue end
	
	if 0x0080 > iSumUp then
		
		sValue = _format("%c", iSumUp)

	elseif 0x07d0 > iSumUp then

		-- c2-df block (2 bytes)
		
		------------------------

		iByte4 = 0x80	+ (tBytes[4] % 0x10)		+ 0x10 * (tBytes[3] % 0x04)
		iByte3 = 0xc0	+ _floor(tBytes[3] / 0x04)	+ 0x04 * (tBytes[2] % 0x08)

		sValue = _format("%c%c", iByte3, iByte4)	

	elseif 0x010000 > iSumUp then

		-- e0-ef block (3 bytes)
		------------------------
		iByte2 = 0xe0	+ tBytes[1]

		iByte4 = 0x80	+ (tBytes[4] % 0x10) 		+ 0x10 * (tBytes[3] % 0x04)
		iByte3 = 0x80	+ _floor(tBytes[3] / 0x04) 	+ 0x04 * (tBytes[2] % 0x10)
		iByte2 = 0xe0	+ tBytes[1]
		
		if 0x00 == tBytes[1] then iByte3 = iByte3 + 1 end		-- correct the start

		sValue = _format("%c%c%c", iByte2, iByte3, iByte4)

	else

		-- f0-f4 block (4 bytes)
		------------------------

		iByte4 = 0x80	+ (tBytes[6] % 0x10) 		+ 0x10 * (tBytes[5] % 0x04)
		iByte3 = 0x80	+ _floor(tBytes[5] / 0x04) 	+ 0x04 * (tBytes[4] % 0x10)
		iByte2 = 0x80	+ (tBytes[3] % 0x10)		+ 0x10 * (tBytes[2] % 0x04)
		iByte1 = 0xf0	+ _floor(tBytes[2] / 0x04)	+ 0x04 * (tBytes[1] % 0x10)

		sValue = _format("%c%c%c%c", iByte1, iByte2, iByte3, iByte4)
	end

	return sValue
end

-- ----------------------------------------------------------------------------
-- check the line for prefined strings
--

local tSections = 
{
	"unctuation",
	"rackets",
	"\tSpace",
	"Format characters",
	"Dashes",
	"Quotation marks",
	"Invisible operators",
	"New Testament editorial symbols",
	"Ancient Greek textual symbols",
	"Palaeotype transliteration symbol",
	"Kana repeat marks",
	"Editorial marks",
}

local function IsStartOfSect(inLine)
	
	if 0 == inLine:len() then return false end
	
	local iStart = inLine:find("@\t\t", 1, true)
	if iStart then
		
		for _, sText in ipairs(tSections) do
			iStart = inLine:find(sText, 3, true)
			if iStart then return true end
		end
	end

	return false
end

-- ----------------------------------------------------------------------------
--
local function Processor(inSourceName, inTargetName, inShowHeader, inColumns, inSpacer)
	
	if not inSourceName or not inTargetName then return -1 end
	
	local fhSrc = io.open(inSourceName, "r")
	if not fhSrc then return -1 end
	
	local fhTgt = io.open(inTargetName, "w")
	if not fhTgt then return -1 end	
	
	-- sanity check
	--
	inShowHeader = inShowHeader or false		-- ?
	iColumns	 = iColumns or 0
	inSpacer 	 = inSpacer or " "
	
	local iStart, iEnd
	local sUnicode
	local iTotal  = 0
	local iColumn = 1
	local sLine   = fhSrc:read("*l")
	
	while sLine do

		-- find the header of block of pertinent lines
		--
		if IsStartOfSect(sLine) then
	
			if inShowHeader then
				fhTgt:write("\n")
				fhTgt:write(sLine)
				fhTgt:write("\n")
				iColumn = 1
			end
	
			-- this line might be a valid code-point
			--
			sLine = fhSrc:read("*l")
	
			while sLine do

				-- check if stop of block of code-points
				--
				iStart = sLine:find("@\t", 1, true)
				iEnd   = sLine:find("@+", 1, true)
				if iStart and not iEnd then break end

				-- extract the code-point and save to file
				--
				iStart, iEnd = sLine:find("(%x+)", 1, false)
				if iStart and 1 == iStart then

					-- get the Unicode code-point from the line
					--
					sUnicode = _norm(sLine:sub(iStart, iEnd))

					-- write the UTF_8 character
					--
					fhTgt:write(_uni2bytes(sUnicode))
					
					if 0 < inColumns then
						
						if inColumns == iColumn then 
							iColumn = 1
							fhTgt:write("\n")
						else
							iColumn = iColumn + 1
							fhTgt:write(inSpacer)
						end
					end
					
					iTotal = iTotal + 1
				end
	
				sLine = fhSrc:read("*l")
			end
	
		else
	
			sLine = fhSrc:read("*l")
		end
	end
	
	fhTgt:close()
	fhSrc:close()
	
	return iTotal
end

-- ----------------------------------------------------------------------------
-- convert a file byte by byte in lua hex format
--
local function LuaFmtBytes(inSourceName, inTargetName)
	
	local fhSrc = io.open(inSourceName, "r")
	if not fhSrc then return -1 end
		
	local iLength
	local tOutput = { }
	local sLine   = fhSrc:read("*l")
	
	-- here we play a little trick to add control characters
	-- that are often found as punctuation
	--
	tOutput[#tOutput + 1] = "\\x09\\x0a\\x0d"
	
	while sLine do
		
		iLength = sLine:len()
		
		-- does not care of the input
		-- but it should contain only utf8 characters
		-- for each byte in file
		--
		for i=1, iLength do
			tOutput[#tOutput + 1] = _format("\\x%02x", sLine:byte(i, i))
		end
		
		-- process next line
		--
		sLine = fhSrc:read("*l")
	end
	
	fhSrc:close()
	
	-- write down the buffer
	--
	local fhTgt = io.open(inTargetName, "w")
	if not fhTgt then return -1 end	
	
	fhTgt:write(_format("return \"%s\"\n", _concat(tOutput)))
	
	fhTgt:close()
	
	return 1
end

-- ----------------------------------------------------------------------------
-- set to false both the booleans and an empty string for the spacing character
-- to get an array of values ready for input with no other processing
--
--
local function Driver(inDoLuaConv)
	
	local sInput   = "..\\docs\\NamesList.txt"
	local sOutput  = "..\\docs\\Punctuation.txt"
	local sLuaFile = ".\\unipunct.lua"
	local bHeader  = false
	local iColumns = 16
	local sSpacer  = " "

	local iRet = Processor(sInput, sOutput, bHeader, iColumns, sSpacer)

	if 0 < iRet then
		
		print(_format("\nTotal Number of Punctuation Characters = %d\n", iRet))

		if not inDoLuaConv then return end

		local iRet2 = LuaFmtBytes(sOutput, sLuaFile)
		
		if 0 < iRet2 then
			print(_format("\nFormatted File [%s] to Lua Hex String\n", sOutput))
		else
			print("\nConversion to Lua Syntax Failed\n")
		end
	else
		print("\nFailed to Create Unicode Punctuation File\n")
	end
end

-- ----------------------------------------------------------------------------
-- run it
--
Driver(true)

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
