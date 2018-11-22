-- ----------------------------------------------------------------------------
--
--  Encode - guess file encoding
--
-- ----------------------------------------------------------------------------

local trace		= require "trace"		-- shortcut for tracing
local window	= require "window"		-- GUI for the application
local tUtf8Code = require "Utf8Table"	-- utf_8 codes table
local samples	= require "samples"		-- create a list of Unicode chars
				  require "extrastr"	-- extra string processor

local _toChar	= string.char
local _format	= string.format
local _utf8sub	= string.utf8sub
local _gcount	= string.gcount
local _wordsub	= string.wordsub
local _insert	= table.insert
local _concat	= table.concat

-- ----------------------------------------------------------------------------
--
local function OnGetTextAtPos(inStopStart, inOffset)
	
	local iLimit = thisApp.iMemorySize
	if 0 >= iLimit then return 0, "Nothing in memory" end
		
	if 0 > inStopStart or iLimit < inStopStart	then return 0, "Error!" end
	if 0 > inOffset or iLimit < inOffset 		then return 0, "Error!" end
	if inOffset < inStopStart 					then return 0, "Error!" end
	
	local sCopyBuff
	local sSource = thisApp.sFileMemory
	local sOption = thisApp.tConfig.CopyOption
	
	if "Byte" == sOption then
			
		sCopyBuff = sSource:sub(inOffset, inOffset)
		return 1, sCopyBuff
	end
	
	-- extract the whole line
	--
	local iLineEnd = sSource:find("\n", inStopStart)
	
	iLineEnd = iLineEnd or iLimit
	sCopyBuff = sSource:sub(inStopStart, iLineEnd)
	
	-- check requested action
	--
	if "Line" == sOption then return #sCopyBuff, sCopyBuff end
		
	-- normalize offset
	--
	local iPosition = inOffset - inStopStart + 1
--	iLineEnd = iLineEnd - inStopStart
	
	-- check action
	--
	if "UTF_8" == sOption then

		sCopyBuff = _utf8sub(sCopyBuff, iPosition)
		
		return #sCopyBuff, sCopyBuff		
	end
	
	sCopyBuff = _wordsub(sCopyBuff, iPosition)
	if sCopyBuff then return #sCopyBuff, sCopyBuff end
	
	-- handle the Word selection
	--
--	local iStart = iPosition
--	while 1 <= iStart do
	
--		local ch = sCopyBuff:sub(iStart, iStart)
--		if " " == ch then break end
		
--		iStart = iStart - 1
--	end
	
--	local iEnd = iPosition	
--	while iEnd <= iLineEnd do
		
--		local ch = sCopyBuff:sub(iEnd, iEnd)
--		if " " == ch then break end		
		
--		iEnd = iEnd + 1
--	end
	
--	-- extract word from entire line
--	--
--	sCopyBuff = sCopyBuff:sub(iStart + 1, iEnd - 1)
	return 0, "Error !"
end

-- ----------------------------------------------------------------------------
--
local function OnCheckEncoding()
	
	trace.lnTimeStart("Testing UTF_8 validity ...")
	
	local tCounters = {0, 0, 0, 0, 0}		-- UTF1, UTF2, UTF3, UTF4, ERRORS
	
	local sSource = thisApp.sFileMemory
	local iLimit  = thisApp.iMemorySize

	local iStart = 1
	local iEnd	 = sSource:find("\n", iStart, true)
	
	local iCurLine = 1
	local iIndex 
	local chCurr
	local sLine
	local iRetCode
	local tLineOut = { }
	
	while iEnd do
		
		sLine = sSource:sub(iStart, iEnd)
		
		-- tokenize
		--
		iIndex = 1
		while #sLine >= iIndex do
		
			-- get next char, which might span from 1 byte to 4 bytes
			--
			chCurr, iRetCode = _utf8sub(sLine, iIndex)			
			_insert(tLineOut, chCurr)			
			
			if 0 > iRetCode then
				trace.line(_format("Line [%4d:%2d] -> [%s]", iCurLine, iIndex, chCurr))
				
				tCounters[5] = tCounters[5] + 1
			else
				tCounters[iRetCode] = tCounters[iRetCode] + 1
			end
			
			iIndex = iIndex + #chCurr
		end
		
		-- perform the test, old string compared to sum of tokens
		--
		local sTest = _concat(tLineOut, nil)
		if sLine ~= sTest then
			trace.line(_format("Line [%4d] fails test", iCurLine))
		end

		-- prepare for next line of text
		--
		tLineOut = { }
		iCurLine = iCurLine + 1

		iStart	= iEnd + 1
		iEnd	= sSource:find("\n", iStart, true)
		
		if not iEnd and iStart < iLimit then iEnd = iLimit end
	end
	
	-- number of characters below 0x20 (space) should be equal to the newline counter
	--
	local sText = _format("[UTF8 1: %d] [UTF8 2: %d] [UTF8 3: %d] [UTF8 4: %d] [ERRORS: %d]", 
							tCounters[1], tCounters[2], tCounters[3], tCounters[4], tCounters[5])
	trace.line(sText)	
	
	collectgarbage()
	
	trace.lnTimeEnd("UTF_8 test end")
	
	return true, sText
end

-- ----------------------------------------------------------------------------
--
local function OnLoadFile()
	
	-- reset content
	--
	thisApp.sFileMemory	= ""
	thisApp.iMemorySize	= 0
	thisApp.iNumOfRows	= 0
	
	-- refresh setup
	--
	thisApp.tConfig = dofile(thisApp.sConfigIni)
	if not thisApp.tConfig then return 0, "Configuration file load failed." end
	
	-- get names from configuration file
	--
	local sSourceFile = thisApp.tConfig.InFile
	local sOpenMode = thisApp.tConfig.ReadMode
	
	local sText = _format("Loading [%s] (%s)", sSourceFile, sOpenMode)
	trace.line(sText)
		
	-- get the file's content
	--
	local  fhSrc = io.open(sSourceFile, sOpenMode)
	if not fhSrc then 
		
		sText = "Unable to open [" .. sSourceFile .. "] (" .. sOpenMode .. ")"
		trace.line(sText)
		return 0, sText
	end
	
	-- set content in app.
	--
	thisApp.sFileMemory = fhSrc:read("*a")	
	thisApp.iMemorySize = thisApp.sFileMemory:len()
	thisApp.iNumOfRows  = _gcount(thisApp.sFileMemory, "\n")
	fhSrc:close()
	
	-- test for utf_8 validity
	--
	if thisApp.tConfig.AutoCheck then OnCheckEncoding() end
	
	-- give feedback
	--
	sText = _format("Read [file: %s] (%s) [lines: %d] [bytes: %d]", 
					sSourceFile, sOpenMode, thisApp.iNumOfRows, thisApp.iMemorySize)
	trace.line(sText)

	return thisApp.iMemorySize, sText
end

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
	local iNumSet = 0
	
	-- process char by char
	--
	local iIndex = 1
	
	while iIndex <= iLimit do
	
		ch = sSource:sub(iIndex, iIndex):byte()
		
		if tUtf8Code[1][1] <= ch and tUtf8Code[1][2] >= ch then
			
			-- first 127 bytes are std ascii
			--
			
--		elseif tUtf8Code[2][3] == ch or tUtf8Code[3][3] == ch then
			
--			-- UTF_8 point
--			--
--			fhTgt:write(_toChar(ch))

--			-- read next byte of pair
--			--
--			iIndex = iIndex + 1
--			ch = sSource:sub(iIndex, iIndex):byte()		
			
		elseif tUtf8Code[3][1] <= ch and tUtf8Code[3][2] >= ch then	
			
			-- ASCII extended #2
			--			
			fhTgt:write(_toChar(tUtf8Code[3][3]))
			
			ch = 0x80 + (ch - tUtf8Code[3][1])

			iNumSet = iNumSet + 1				
			
		elseif tUtf8Code[2][1] <= ch and tUtf8Code[2][2] >= ch then	
			
			-- ASCII extended #1
			--
			fhTgt:write(_toChar(tUtf8Code[2][3]))
			
			ch = 0x80 + (ch - tUtf8Code[2][1])

			iNumSet = iNumSet + 1			

		end
		
		-- write the char
		--
		fhTgt:write(_toChar(ch))
		if 0 == (iIndex % 1024) then io.flush() end	
		
		iIndex = iIndex + 1
	end

	fhTgt:close()
	
	trace.lnTimeEnd("Encoding conversion")
	
	collectgarbage()	

	local sText = _format("File encoded UTF_8 with %d conversions", iNumSet)
	trace.line(sText)	
	
	return iNumSet, sText
end

-- ----------------------------------------------------------------------------
--[[
local function OnCheckEncodingNew()

	
--	local iLimit = thisApp.iMemorySize
	if 0 >= thisApp.iMemorySize then return 0, "Nothing in memory" end
	
	trace.lnTimeStart("Check file encoding ...")
	
	local sSource	= thisApp.sFileMemory
--	local dwCurHigh
--	local dwCurLow
	local sCurLine
	local iLimit
	local iStart 	= 1
	local iEnd	 	= sSource:find("\n", iStart, true)
	local iLineNo	= 0
	local iCheckLow = 1
	local iNumUTF_8 = 0
	local iNumASCII = 0
	local iNumError = 0
	
	-- check for unprintable characters
	-- 1 or 2 are allowed (cr or cr/lf)
	--
	if thisApp.tConfig.ReadMode == "rb" then iCheckLow = 2 end
		
	local tCounters = {0, 0, 0, 0}		-- chars found on each segment
	local tCtrsTot  = {0, 0, 0, 0}		-- sum up line by line
	local tFileFmt  = {0, 0, 0}			-- sum up of ASCII, UTF_8, Err line by line

	-- process line by line
	--
	while iEnd do
		
		sCurLine = sSource:sub(iStart, iEnd)
		iLimit	= rawlen(sCurLine)
		
		
		local i = 1
		while i <= iLimit do
		
			local tConvert = nil
			
			if i <= (iLimit - 1) then
				
				tConvert = get2BytesRow(sCurLine:sub(i, i + 1))
				
				if tConvert then
					
					iNumUTF_8 = iNumUTF_8 + 1
					
					-- skip next
					--
					i = i + 1						
				end
			end
			
			if not tConvert then
				
				-- get the char code
				--
				tConvert = get1ByteRow(sCurLine:sub(i, i))
				
				if not tConvert then
					iNumError = iNumError + 1
				else
					iNumASCII = iNumASCII + 1
					
					-- here we can append a char for writing the output file
					--
					-- check is ok
					
				end
			end

			-- process next
			--
			i = i + 1
		
		end
		
		-- save totals
		--
		for j=1, #tCtrsTot do tCtrsTot[j] = tCtrsTot[j] + tCounters[j] end
		
		tFileFmt[1] = tFileFmt[1] + iNumASCII
		tFileFmt[2] = tFileFmt[2] + iNumUTF_8
		tFileFmt[3] = tFileFmt[3] + iNumError

		-- next line
		--
		tCounters 	= {0, 0, 0, 0}
		iNumASCII 	= 0
		iNumUTF_8 	= 0
		iNumError	= 0
		iLineNo		= iLineNo + 1
		
		iStart = iEnd + 1
		iEnd	 = sSource:find("\n", iStart, true)		

	end

	trace.lnTimeEnd("Encoding check")
	
	-- number of characters below 0x20 (space) should be equal to the newline counter
	--
	local sText = _format("Totals: [0xc0: %d] [0x80: %d] [0x20: %d] [0x00: %d/%d]", 
								 tCtrsTot[1], tCtrsTot[2], tCtrsTot[3], tCtrsTot[4], (iCheckLow * iLineNo))
	trace.line(sText)	
	
	sText = _format("Summary: [iNumASCII: %d] [iNumUTF_8: %d] [iNumError: %d]", 
						 tFileFmt[1], tFileFmt[2], tFileFmt[3])
	
	trace.line(sText)
	
	collectgarbage()
	
	return iLineNo, sText	
end
]]
-- ----------------------------------------------------------------------------
--[[
local function OnCheckEncoding()
	
--	local iLimit = thisApp.iMemorySize
	if 0 >= thisApp.iMemorySize then return 0, "Nothing in memory" end
	
	trace.lnTimeStart("Check file encoding ...")
	
	local sSource	= thisApp.sFileMemory
	local ch
	local sCurLine
	local iLimit
	local iStart 	= 1
	local iEnd	 	= sSource:find("\n", iStart, true)
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
		iLimit	= rawlen(sCurLine)
		
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
		iEnd	 = sSource:find("\n", iStart, true)
	end
	
	local sHits = _format("Check results ASCII: %4d UTF_8: %4d", tFileFmt[1], tFileFmt[2])
	trace.line(sHits)
		
	local sAssert = "--> Cannot guess encoding <--"
	
	if tFileFmt[1] > tFileFmt[2] then sAssert = "--> File encoded ASCII <--" end
	if tFileFmt[1] < tFileFmt[2] then sAssert = "--> File encoded UTF_8 <--" end
	
	trace.line(sAssert)	
	
	-- number of characters below 0x20 (space) should be equal to the newline counter
	-- otherwise there mught be tabulations or the file was read binary
	--
	local sText = _format("Totals: [0xc0: %d] [0x80: %d] [0x20: %d] [0x00: %d/%d]", 
								 tCtrsTot[1], tCtrsTot[2], tCtrsTot[3], tCtrsTot[4], (iCheckLow * iLineNo))
	trace.line(sText)	
	
	trace.lnTimeEnd("Encoding check")
	
	collectgarbage()
	
	return iLineNo, sText
end
]]

-- ----------------------------------------------------------------------------
--
local function OnCreateSamples()
--	trace.line("OnCreateSamples")

	local sTargetFile = thisApp.tConfig.OutFile
	local sOpenMode = thisApp.tConfig.WriteMode
	
	-- check which encoding to use
	--
	local iFormat	= 1

	if thisApp.tConfig.TestEncode == "UTF_8" then iFormat = 2 end
	
	trace.lnTimeStart("Creating samples file ...")
	
	-- call the function to create the samples
	--
	local bRet = samples.Create(sTargetFile, sOpenMode, iFormat)
	
	trace.lnTimeEnd("Create samples end")
	
	collectgarbage()
	
	return bRet
end

-- ----------------------------------------------------------------------------
-- preamble
--
local function SetUpApplication()

	trace.line(thisApp.sAppName .. " (Ver. " .. thisApp.sAppVersion .. ")")
	trace.line("Released " .. thisApp.sAppRelDate)
	
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
	window.Close()
	
	trace.line(thisApp.sAppName .. " terminated")
end

-- ----------------------------------------------------------------------------
--
local function main()
  
	-- redirect logging
	--
	io.output(thisApp.sLogFilename)

	if SetUpApplication() then 
		
		if thisApp.tConfig.Autoload then OnLoadFile() end
		
		window.Show()
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
	sAppVersion		= "0.0.4",				-- application's version
	sAppRelDate		= "20-nov-18",			-- date of release update
	sAppName		= "Encode",				-- name for the application
	
	sLogFilename	= "Encode.log",			-- logging filename
	sConfigIni		= "SetupInf.lua",		-- filename for the config
	tConfig			= { },					-- configuration for the app.
	
	sFileMemory		= "",					-- store file here
	iMemorySize		= 0,					-- lenght of memory for the file
	iNumOfRows		= 0,					-- number of new lines chars
	
	LoadFile		= OnLoadFile,			-- load the config file in memory
	CheckEncoding	= OnCheckEncoding,		-- check chars in current file
	Encode_UTF_8	= OnEncode_UTF_8,		-- save the current file UTF_8
	CreateTest		= OnCreateSamples,		-- create a file with samples
	GetTextAtPos	= OnGetTextAtPos,		-- get text at pos (see setupinf.lua)
}

-- ----------------------------------------------------------------------------
-- run it
--
main()

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
