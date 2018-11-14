-- ----------------------------------------------------------------------------
--
--  Encode - guess file encoding
--
-- ----------------------------------------------------------------------------

local trace		= require "trace"			-- shortcut for tracing
local window	= require "window"		-- GUI for the application
local rnd		= require "random"		-- random number generator

local _toChar	= string.char
local _format	= string.format
local _rand		= rnd.getInRange

-- ----------------------------------------------------------------------------
--
local function CountLines()
	if 0 >= thisApp.iMemorySize then return 0 end
	
	local iLimit	= thisApp.iMemorySize
	local sSource	= thisApp.sFileMemory
	local iRows		= 0 
	local iEnd	 	= sSource:find("\n", 1)
	
	-- total rows
	--
	while iEnd do
		
		iRows = iRows + 1
		iEnd	= sSource:find("\n", iEnd + 1)		
	end
	
	-- update
	--
	thisApp.iNumOfRows = iRows
	
	return iRows
end

-- ----------------------------------------------------------------------------
--
local function OnLoadFile()
	if not thisApp.tConfig then return 0 end
	
	-- reset content
	--
	thisApp.sFileMemory	= ""
	thisApp.iMemorySize	= 0
	thisApp.iNumOfRows	= 0
	
	thisApp.tConfig = dofile(thisApp.sConfigIni)
	if not thisApp.tConfig then return 0 end
	
	-- get names from configuration file
	--
	local sSourceFile = thisApp.tConfig.InFile
	local sOpenMode = thisApp.tConfig.ReadMode
		
	-- get the file's content
	--
	local  fhSrc = io.open(sSourceFile, sOpenMode)
	if not fhSrc then 
		
		trace.line("Unable to open [" .. sSourceFile .. "]")
		return 0 
	end
	
	thisApp.sFileMemory = fhSrc:read("*a")	
	thisApp.iMemorySize = thisApp.sFileMemory:len()
	fhSrc:close()
	
	local sText = _format("Read [file: %s] [mode: %s] [bytes: %d]", sSourceFile, sOpenMode, thisApp.iMemorySize)
	trace.line(sText)
	
	-- do a scan of text
	--
	CountLines()

	return thisApp.iMemorySize
end

-- ----------------------------------------------------------------------------
--
local tUtf8Code =
{
	{ 0x00, 0x7f,  nil }, -- no change
	{ 0x80, 0xbf, 0xc2 }, -- 80, bf },
	{ 0xc0, 0xff, 0xc3 }, -- 80, bf }
}

-- ----------------------------------------------------------------------------
--
local function OnEncode_UTF_8()
	
	local iLimit = thisApp.iMemorySize
	if 0 >= iLimit then return 0, "Nothing in memory" end
	
	local sTargetFile = thisApp.tConfig.OutFile
	local sOpenMode	= thisApp.tConfig.WriteMode
	
	-- open outut file
	--
	local fhTgt = io.open(sTargetFile, sOpenMode)
	if not fhTgt then	return 0, "Unable to open output file" end
	
	trace.lnTimeStart("Encoding memory as UTF_8 text to file [" .. sTargetFile .. "]")	
	
	local sSource = thisApp.sFileMemory
	local ch
	local tChars = { }
	local iNumSet = 0
	
	-- process char by char
	--
	local iIndex = 1
	
	while iIndex <= iLimit do
	
		ch = sSource:sub(iIndex, iIndex):byte()
		
		if tUtf8Code[1][1] <= ch and tUtf8Code[1][2] >= ch then
			
			-- first 127 bytes are std ascii
			--
			
		elseif tUtf8Code[2][3] == ch or tUtf8Code[3][3] == ch then
			
			-- UTF_8 point
			--
			fhTgt:write(_toChar(ch))

			-- read next byte of pair
			--
			iIndex = iIndex + 1
			ch = sSource:sub(iIndex, iIndex):byte()			
			
		elseif tUtf8Code[2][1] <= ch and tUtf8Code[2][2] >= ch then	
			
			-- ASCII extended #1
			--
			fhTgt:write(_toChar(tUtf8Code[2][3]))
			
			ch = 0x80 + (ch - tUtf8Code[2][1])

			iNumSet = iNumSet + 1			
			
		elseif tUtf8Code[3][1] <= ch and tUtf8Code[3][2] >= ch then	
			
			-- ASCII extended #2
			--			
			fhTgt:write(_toChar(tUtf8Code[3][3]))
			
			ch = 0x80 + (ch - tUtf8Code[3][1])

			iNumSet = iNumSet + 1			

		end
		
		-- write the char
		--
		fhTgt:write(_toChar(ch))
		if 0 == (iIndex % 1024) then io.flush() end	
		
		iIndex = iIndex + 1
	end

	fhTgt:close()
		
	local sText = _format("File encoded UTF_8 with %d conversions", iNumSet)
	trace.line(sText)	
	
	trace.lnTimeEnd("Encoding conversion")
	
	collectgarbage()
	
	return iNumSet, sText
end

-- ----------------------------------------------------------------------------
--
local function OnCheckEncoding()
	
	local iLimit = thisApp.iMemorySize
	if 0 >= iLimit then return 0, "Nothing in memory" end
	
	trace.lnTimeStart("Check file encoding ...")
	
	local sSource	= thisApp.sFileMemory
	local ch
	local sCurLine
	local iLimit
	local iStart 	= 1
	local iEnd	 	= sSource:find("\n", iStart)
	local iLineNo	= 0
	local iCheckLow = 1
	local iNumUTF_8 = 0
	local iNumASCII = 0
	
	-- check for unprintable characters
	-- 1 or 2 are allowed (cr or cr/lf)
	--
	if thisApp.tConfig.ReadMode == "rb" then iCheckLow = 2 end
		
	local tCounters = {0, 0, 0, 0}		-- chars found on each segment
	local tCtrsTot  = {0, 0, 0, 0}		-- sum up line by line
	local tFileFmt  = {0, 0}				-- sum up of ASCII or UTF_8 line by line

	-- process line by line
	--
	local bSkipNext
	
	while iEnd do

		sCurLine = sSource:sub(iStart, iEnd)
		iLimit	= sCurLine:len()
		
		bSkipNext = false
		
		for i=1, iLimit do
		
			if bSkipNext then
				bSkipNext = false
			else

				ch = sCurLine:sub(i, i):byte()

				if 0xc0 <= ch then
					tCounters[1] = tCounters[1] + 1
				elseif 0x80 <= ch then
					tCounters[2] = tCounters[2] + 1
				elseif 0x20 <= ch then
					tCounters[3] = tCounters[3] + 1
				else
					tCounters[4] = tCounters[4] + 1
				end
								
				if 0xc0 <= ch then
					if 0xc2 == ch or 0xc3 == ch then
						
						local ch2 = sCurLine:sub(i + 1, i + 1):byte()
						
						if 0x80 <= ch2 and 0xbf >= ch2 then
							
							tCounters[2] = tCounters[2] + 1
							
							iNumUTF_8 = iNumUTF_8 + 1
							bSkipNext = true
						end					
						
					else
						iNumASCII = iNumASCII + 1				
					end
				end

			end
		end

		if 0 < iNumASCII or 0 < iNumUTF_8 then
			
			local sText = _format("Line %4d: ASCII: %4d  UTF_8: %4d", iLineNo, iNumASCII, iNumUTF_8)

--			trace.line(sSource:sub(iStart, iEnd - 1))
			trace.line(sText)
			
		end

		if iCheckLow < tCounters[4] then
			local sText = _format("Line %4d: %4d %4d %4d %4d <--", 
										 iLineNo, tCounters[1], tCounters[2], tCounters[3], tCounters[4])

			trace.line(sCurLine) 
			trace.line(sText)
		end
		
		-- save totals
		--
		for j=1, #tCtrsTot do tCtrsTot[j] = tCtrsTot[j] + tCounters[j] end
		
		tFileFmt[1] = tFileFmt[1] + iNumASCII
		tFileFmt[2] = tFileFmt[2] + iNumUTF_8

		-- next line
		--
		tCounters 	= {0, 0, 0, 0}
		iNumASCII 	= 0
		iNumUTF_8 	= 0		
		iLineNo		= iLineNo + 1
		
		iStart = iEnd + 1
		iEnd	 = sSource:find("\n", iStart)
	end
	
	local sHits = _format("Check results ASCII: %4d UTF_8: %4d", tFileFmt[1], tFileFmt[2])
	trace.line(sHits)
		
	local sAssert = "--> Cannot guess encoding <--"
	
	if tFileFmt[1] > tFileFmt[2] then sAssert = "--> File encoded ASCII <--" end
	if tFileFmt[1] < tFileFmt[2] then sAssert = "--> File encoded UTF_8 <--" end
	
	trace.line(sAssert)	
	
	-- number of characters below 0x20 (space) should be equal to the newline counter
	--
	local sText = _format("Totals: [0xc0: %d] [0x80: %d] [0x20: %d] [0x00: %d/%d]", 
								 tCtrsTot[1], tCtrsTot[2], tCtrsTot[3], tCtrsTot[4], (iCheckLow * iLineNo))
	trace.line(sText)	
	
	trace.lnTimeEnd("Encoding check")
	
	collectgarbage()
	
	return iLineNo, sText
end

-- ----------------------------------------------------------------------------
--
local function OnCreateTest()
--	trace.line("OnCreateTest")

	local sTargetFile = thisApp.tConfig.OutFile
	local sOpenMode = thisApp.tConfig.WriteMode
	
	local fhTgt = io.open(sTargetFile, sOpenMode)
	if not fhTgt then	
		
		trace.line("Failed to create [" .. sTargetFile .. "]")
		return 0	
	end
	
	local iLines	= 255
	local iFormat	= 1

	-- check which encoding to use
	--
	if thisApp.tConfig.TestEncode == "ASCII" then
		iFormat = 1
	elseif thisApp.tConfig.TestEncode == "UTF_8" then
		iFormat = 2
	end
	
	-- write the sequence
	--
	for i=1, iLines do
		
		if 1 == iFormat then
			fhTgt:write(_toChar(i))
			
		elseif 2 == iFormat then
			
			if tUtf8Code[1][1] <= i and i <= tUtf8Code[1][2] then
				fhTgt:write(_toChar(i))	
				
			elseif tUtf8Code[2][1] <= i and i <= tUtf8Code[2][2] then
				fhTgt:write(_toChar(tUtf8Code[2][3]))
				fhTgt:write(_toChar(0x80 + i - tUtf8Code[2][1]))
				
			elseif tUtf8Code[3][1] <= i and i <= tUtf8Code[3][2] then
				fhTgt:write(_toChar(tUtf8Code[3][3]))
				fhTgt:write(_toChar(0x80 + i - tUtf8Code[3][1]))				
			else
			end
		else
		end
		
		fhTgt:write(_toChar(0x0a))
	end
	fhTgt:close()
	
	trace.line("Test file in [" .. sTargetFile .. "]")

	return iLines
end

-- ----------------------------------------------------------------------------
-- preamble
--
local function SetUpApplication()

	trace.line(thisApp.sAppName .. " (Ver. " .. thisApp.sAppVersion .. ")")
	trace.line("Released " .. thisApp.sAppRelDate)

	rnd.initialize()
	
	assert(os.setlocale('ita', 'all'))
	trace.line("Current locale is [" .. os.setlocale() .. "]")
		
	thisApp.tConfig = dofile(thisApp.sConfigIni)
	if not thisApp.tConfig then return false end
		
	trace.line("Configuration script read")
	return true
end

-- ----------------------------------------------------------------------------
-- leave clean
--
local function QuitApplication()
	
	-- call the close 
	--
	CloseMainWindow()
	
	trace.line(thisApp.sAppName .. " terminated")
end

-- ----------------------------------------------------------------------------
--
local function main()
  
	-- redirect logging
	--
	io.output("encodelog.txt")

	if SetUpApplication() then 
		ShowMainWindow()
	end

	-- we'll get here only when the main window loop closes
	--
	QuitApplication()

	io.output():close()
end

-- ----------------------------------------------------------------------------
--
thisApp =
{
	sAppVersion			= "0.0.3",					-- application's version
	sAppRelDate			= "10-nov-18",				-- date of release update
	sAppName				= "Encode",					-- name for the application
	
	sConfigIni			= "SetupInf.lua",			-- filename for the config
	tConfig				= { },						-- configuration for the app.
	
	sFileMemory			= "",							-- store file here
	iMemorySize			= 0,							-- lenght of memory for the file
	iNumOfRows			= 0,							-- number of new lines chars
	
	LoadFile				= OnLoadFile,				-- load the config file in memory
	CheckEncoding		= OnCheckEncoding,		-- check chars in current file
	Encode_UTF_8		= OnEncode_UTF_8,			-- save the current file UTF_8
	CreateTest			= OnCreateTest,			-- create a 256 lines binary file
}

-- ----------------------------------------------------------------------------
-- run it
--
main()

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
