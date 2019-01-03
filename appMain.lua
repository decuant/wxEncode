-- ----------------------------------------------------------------------------
--
--  wxEncode - guess file encoding
--
-- note that almost everywhere in this file is used the operator
-- string.len instead of #array because strings can contain
-- embedded zeros
-- ----------------------------------------------------------------------------

package.path = package.path .. ";transcode/?.lua;"

local trace		= require "trace"		-- shortcut for tracing
local wxWinMain	= require "wxMain"		-- GUI for the application
local samples	= require "uniBlocks"	-- create a list of Unicode blocks
				  require "extrastr"	-- extra string processor

local _format	= string.format
local _strrep	= string.rep
local _byte		= string.byte
local _utf8sub	= string.utf8sub		-- extract utf8 bytes (1-4)
local _wordsub	= string.wordsub		-- extract words
local _fmtkilo	= string.fmtkilo		-- pretty format byte size
local _concat	= table.concat
local _floor	= math.floor

-- ----------------------------------------------------------------------------
--
local thisApp = nil

-- ----------------------------------------------------------------------------
-- binary search for the index in this special table for the file in memory
-- table's rows are:
-- { total sum of previous text length, line of text }
--
local function OnLookupInterval(inTable, inByteIndex)

	local iStart = 1
	local iEnd	 = #inTable
	local iIndex
	local tCurr
	local iSum

	-- check for the very first row that happens to start with a zero
	--
	if (0 == inByteIndex) and (0 < #inTable) then return 1, inTable[1] end

	-- do the scan
	--
	while iStart <= iEnd do

		iIndex = _floor(iStart + (iEnd - iStart) / 2)

		tCurr = inTable[iIndex]
		iSum  = tCurr[1] + tCurr[2]:len()

		if tCurr[1] < inByteIndex and inByteIndex <= iSum then
			return iIndex, tCurr
		end

		if iSum <= inByteIndex then iStart = iIndex + 1 else iEnd = iIndex - 1 end
	end

	return -1, nil
end

-- ----------------------------------------------------------------------------
--
local function OnFindLine(inAbsOffset)

	if 0 == thisApp.iFileBytes then return -1, nil end

	return OnLookupInterval(thisApp.tFileLines, inAbsOffset)
end

-- ----------------------------------------------------------------------------
-- find text from optional start pos
-- follow the Lua standard of indexing from 1 (0 is not a valid option)
-- if the 'no case' option is enabled this will succeed only for ASCII text
--
local function OnFindText(inText, inStartPos, inNoCase)
--	trace.line("OnFindText")

	if not inText or 0 == #inText then return -1 end

	-- upon getting an automatic value then
	-- shif it up a position so to retrieve
	-- the next match
	--
	local tLines  = thisApp.tFileLines
	local iCursor = wxWinMain.GetCursorPos() + 1

	-- sanity check
	--
	inStartPos = inStartPos or iCursor
	if 0 > inStartPos then inStartPos = iCursor end
	if 0 > inStartPos then return -1 end

	-- get the current line from the optional position
	--
	local iLineIndex = OnFindLine(inStartPos)			-- get line of text
	if 0 > iLineIndex then return -1 end

	inStartPos = inStartPos - tLines[iLineIndex][1]		-- normalize

	if inNoCase then inText = inText:upper() end		-- check for case

	-- the first find might be on the current line
	--
	local sLine = tLines[iLineIndex][2]

	if inNoCase then
		iCursor = sLine:upper():find(inText, inStartPos, true)
	else
		iCursor = sLine:find(inText, inStartPos, true)
	end

	-- search each line for the text
	--
	if not iCursor then

		for i=iLineIndex + 1, #tLines do

			sLine = tLines[i][2]

			if inNoCase then
				iCursor = sLine:upper():find(inText, 1, true)
			else
				iCursor = sLine:find(inText, 1, true)
			end

			if iCursor then iLineIndex = i break end
		end
	end

	if iCursor then

		-- align the cursor to the global pos
		-- within the file
		--
		iCursor = iCursor + tLines[iLineIndex][1]
		wxWinMain.SetCursorPos(iCursor)

		return iCursor
	end

	return -1
end

-- ----------------------------------------------------------------------------
-- copy text from absolute values
--
local function OnCopySelected(inFrom, inTo)
--	trace.line("OnGetTextAtPos")

	if 0 == thisApp.iFileBytes then return 0, "Nothing in memory" end

	-- correct indices
	--
	if inFrom > inTo then
		inFrom, inTo = inTo, inFrom
	end
	
	if inFrom == inTo then
		return 0, "Empty selection"
	end

	if 0 >= inFrom or inTo > thisApp.iFileBytes then
		return 0, "Invalid indices"
	end

	local tLines	= thisApp.tFileLines
	local iStartLn	= OnFindLine(inFrom)
	local iStopLn	= OnFindLine(inTo)
	local iStart	= inFrom - tLines[iStartLn][1]

	-- simple case, selection within a single line
	--
	if iStartLn == iStopLn then

		local iEnd  = inTo - tLines[iStartLn][1]
		local sText = tLines[iStartLn][2]:sub(iStart, iEnd)

		return sText:len(), sText
	end

	-- selected text spans more than 1 line
	--
	local tSelected = { }

	-- first piece
	--
	tSelected[#tSelected + 1] = tLines[iStartLn][2]:sub(iStart)

	while iStartLn < iStopLn do

		iStartLn = iStartLn + 1

		if iStartLn < iStopLn then

			-- continuation
			--
			tSelected[#tSelected + 1] = tLines[iStartLn][2]
		else

			-- end of selection
			--
			local iEnd = inTo - tLines[iStartLn][1]

			tSelected[#tSelected + 1] = tLines[iStartLn][2]:sub(1, iEnd)
		end
	end

	-- put all together
	--
	local sText = _concat(tSelected)

	return sText:len(), sText
end

-- ----------------------------------------------------------------------------
-- get text from source buffer with the line at inLine
-- start copying from offset to selected option's end
-- depending on the configuration will extract:
-- 1 byte
-- an UTF_8 code made of 1 to 4 bytes
-- a word starting from punctuation to punctuation
-- all the text at inLine
--
local function OnGetTextAtPos(inLine, inOffset)
--	trace.line("OnGetTextAtPos")

	-- sanity check
	--
	if 0 == thisApp.iFileBytes then return 0, "Nothing in memory" end
	if #thisApp.tFileLines < inLine or 1 > inLine then
		return 0, "Line index not valid"
	end

	local iOption	= thisApp.tConfig.CopyOption			-- check for option
	local sTextLine	= thisApp.tFileLines[inLine][2]			-- set current line

	if "Line" == inOption then return sTextLine:len(), sTextLine end

	if 0 < inOffset and inOffset < sTextLine:len() then

		if "Byte" == inOption then
			return 1, sTextLine:sub(inOffset, inOffset)
		end

		if "UTF_8" == inOption then

			local sUTF8 = _utf8sub(sTextLine, inOffset)
			return sUTF8:len(), sUTF8
		end

		-- handle the Word selection
		--
		local sWord = _wordsub(sTextLine, inOffset)
		if sWord then return sWord:len(), sWord end
	end

	return 0, "Error performing copy!"
end

-- ----------------------------------------------------------------------------
-- get an error from the checked UTF_8 validity test
-- an error is a table itself:
-- {line number, offset within the line}
--
local function OnGetUTF8Error(inIndex)
--	trace.line("OnGetUTF8Error")

	inIndex = inIndex or 1

	local tErrors = thisApp.tCheckErrors
	if #tErrors < inIndex then inIndex = 1 end			-- rotate errors right
	if 0 >= inIndex then inIndex = #tErrors end			-- rotate errors left

	return inIndex, tErrors[inIndex]
end

-- ----------------------------------------------------------------------------
--
local function OnEnumCodepages()
--	trace.line("OnEnumCodepages")

	-- load the translator
	--
	local translate = dofile(thisApp.sTranslateApp)
	if not translate then return 0, "Translator not found" end

	translate.AvailCodepages()

	return 1, "Available codepages are in the trace file"
end

-- ----------------------------------------------------------------------------
-- validate the file, loads the errors table (if any)
-- see the Unicode's recommendation for error handling
-- that is: a sequence of, say, 4 bytes with an error on the first byte
-- will produce an error for the first byte only, subsquent bytes might
-- produce more errors
--
local function OnCheckEncoding()
--	trace.line("OnCheckEncoding")

	trace.lnTimeStart("Testing UTF_8 validity ...")

	local tCounters = {0, 0, 0, 0, 0}		-- UTF1, UTF2, UTF3, UTF4, ERRORS
	thisApp.tCheckErrors = { }				-- reset errors table

	local iIndex
	local chCurr
	local sLine
	local iEnd
	local iRetCode
	local tLineOut = { }
	local tErrors  = thisApp.tCheckErrors

	-- format for each line is
	-- {offset from start of file, line of text}
	--
	for iCurLine, tLine in ipairs(thisApp.tFileLines) do

		sLine = tLine[2]

		-- UTF_8 aware splitting
		--
		iIndex	= 1
		iEnd	= sLine:len() + 1

		while iEnd > iIndex do

			-- get next char, which might span from 1 byte to 4 bytes
			--
			chCurr, iRetCode = _utf8sub(sLine, iIndex)
			tLineOut[#tLineOut + 1] = chCurr

			-- a negative index is an error
			--
			if 0 > iRetCode then

				-- add an error to the errors' table
				--
				tErrors[#tErrors + 1] = {iCurLine, iIndex}

				if thisApp.tConfig.Pedantic then
					trace.line(_format("Line [%4d:%2d] -> [0x%02x]", iCurLine, iIndex, _byte(chCurr)))
				end

				tCounters[5] = tCounters[5] + 1
				iIndex = iIndex + 1						-- advance by 1 only

			else

				tCounters[iRetCode] = tCounters[iRetCode] + 1
				iIndex = iIndex + iRetCode				-- skip all UTF_8 size
			end
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
	end

	-- number of characters below 0x20 (space) should be equal to the newline counter
	--
	local sText = _format("[UTF8 1: %d] [UTF8 2: %d] [UTF8 3: %d] [UTF8 4: %d] [ERRORS: %d]",
							tCounters[1], tCounters[2], tCounters[3], tCounters[4], tCounters[5])
	trace.line(sText)

	trace.lnTimeEnd("UTF_8 test end")

	return #thisApp.tCheckErrors, sText
end

-- ----------------------------------------------------------------------------
--
local function OnCountSequences(inLineIdx)
--	trace.line("OnCountSequences")
	
	local tCurLine = thisApp.tFileLines[inLineIdx]
	if not tCurLine then return -1 end
	
	local tSequence = { }
	local tCurrent	= { }
	local sBuffer   = tCurLine[2]
	local iLength   = sBuffer:len()
	local iNumHigh  = 0
	local iCounter	= 0
	local chMark    = 0x00
	local chTest
	
	for i=1, iLength do
		
		chTest = sBuffer:byte(i)
		if 0x80 < chTest then
			iNumHigh = iNumHigh + 1
			
			iCounter = iCounter + 1
			
			if chTest ~= chMark then		-- add new
				tCurrent = {chTest, 0}
				chMark   = chTest
				iCounter = 1
				tSequence[#tSequence + 1] = tCurrent
			end
			
			tCurrent[2] = iCounter			-- increment current
		else
			
			chMark  = 0x00					-- restart current
		end
	end
	
	local tCompact = { }
	for i, tCurr in ipairs(tSequence) do
		
		if 1 < tCurr[2] then
			tCompact[#tCompact + 1] = tCurr
		end		
	end
	tSequence = tCompact
	
	for i, tCurr in ipairs(tSequence) do
		trace.line(_format(">> [0x%2x]  [%d]", tCurr[1], tCurr[2]))
	end	

	trace.line(_format("Format Test Line [%d] Length [%d] High [%d]", inLineIdx, iLength, iNumHigh))
	
	return iLength, iNumHigh, #tSequence
end


-- ----------------------------------------------------------------------------
-- read the configuration file written in Lua's syntax
--
local function OnReadSetupInf()
--	trace.line("OnReadSetupInf")

	thisApp.tConfig = dofile(thisApp.sConfigIni)
	if not thisApp.tConfig then return false end

	-- do it here so we can change the collector
	-- when the application is already running
	--
	if "Generational" == thisApp.tConfig.Collector then
		collectgarbage("generational")
	else
		collectgarbage("incremental")
	end

	trace.line("Configuration script read")
	return true
end

-- ----------------------------------------------------------------------------
-- load file into memory
-- if a filename is provided then override the flename declared in config file
--
local function OnLoadFile(inOptFilename)
--	trace.line("OnLoadFile")

	trace.line("Importing a new file")

	-- reset content
	--
	thisApp.tFileLines	 = { }
	thisApp.iFileBytes 	 = 0
	thisApp.tCheckErrors = { }

	-- refresh setup
	--
	if not OnReadSetupInf() then return 0, "Configuration file load failed." end

	-- perform a full garbage collection cycle
	-- trying to profit of just released memory
	--
	collectgarbage("collect")

	-- get names from configuration file
	--
	local sSourceFile = thisApp.tConfig.InFile
	local sOpenMode	  = thisApp.tConfig.ReadMode

	-- override using last filenames used
	--
	if 0 < thisApp.sLastOpenFile:len() then sSourceFile = thisApp.sLastOpenFile end
--	if 0 < thisApp.sLastSaveFile:len() then sSourceFile = thisApp.sLastSaveFile end

	-- override if a filename was provided
	--
	if inOptFilename and 0 < inOptFilename:len() then sSourceFile = inOptFilename end

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

	-- read the whole line with the end of line too
	--
	local iCount = 0
	local tFile  = { }
	local tLine  = {0, ""}

	-- add line by line, set the global bytes counter in each line
	--
	local sLine = fhSrc:read("*L")

	while sLine do

		tLine[1] = iCount					-- progressive count of bytes read so far
		tLine[2] = sLine					-- the actual line of text
		tFile[#tFile + 1] = tLine

		iCount = iCount + tLine[2]:len()
		tLine  = {0, ""}

		sLine = fhSrc:read("*L")
	end

	fhSrc:close()

	-- assign to the app
	--
	thisApp.tFileLines = tFile
	thisApp.iFileBytes = iCount

	-- test for utf_8 validity
	--
	if thisApp.tConfig.AutoCheck then OnCheckEncoding() end

	-- give feedback
	--
	sText = _format("Read [file: %s] (%s) [lines: %d] [size: %s]",
					sSourceFile, sOpenMode, #thisApp.tFileLines, _fmtkilo(thisApp.iFileBytes))
	trace.line(sText)

	thisApp.sLastOpenFile = sSourceFile			-- remember filename used

	return thisApp.iFileBytes, sText
end

-- ----------------------------------------------------------------------------
--
local function OnEncode_UTF_8()
--	trace.line("OnEncode_UTF_8")

	local iLimit = thisApp.iFileBytes
	if 0 >= iLimit then return 0, "Nothing in memory" end

	-- load the translator
	--
	local translate = dofile(thisApp.sTranslateApp)
	if not translate then return 0, "Translator not found" end

	local cpInput  = thisApp.tConfig.Codepage
	local codepage = translate.Codepage(cpInput)
	if not codepage then return 0, "Codepage not found" end

	-- do the translation
	--
	local sText = _format("Encoding memory [%s: %d]", cpInput[1], cpInput[2])
	trace.lnTimeStart(sText)

	local tLinesSeq = { }			-- collection of translated lines
	local iCountPrev= 0				-- addition of line by line length
	local sLine

	-- process line by line
	-- (it's unlikely to get an error here)
	--
	for _, tRow in ipairs(thisApp.tFileLines) do

		sLine = translate.Processor(tRow[2], codepage)		-- translate
		tLinesSeq[#tLinesSeq + 1] = {iCountPrev, sLine}		-- make new row
		iCountPrev = iCountPrev + sLine:len()				-- sum up bytes
	end

	-- swap buffers
	--
	thisApp.tFileLines = tLinesSeq
	thisApp.iFileBytes = iCountPrev

	sText =  _format("Encoded memory [%s: %d] successfully", cpInput[1], cpInput[2])
	trace.lnTimeEnd(sText)

	return iCountPrev, sText
end

-- ----------------------------------------------------------------------------
-- save file to target
-- inSelector options:
-- 1  - export to file declared in config (defualt option)
-- 2  - overwrite input file
-- 3  - save to optional filename
--
local function OnSaveFile(inSelector, inOptFilename)
--	trace.line("OnSaveFile")

	if 0 == thisApp.iFileBytes then return 0, "Nothing in memory" end

	local sTargetFile = nil
	local sOpenMode   = "w"

	-- override using last filenames used
	--
	if 0 < thisApp.sLastOpenFile:len() then sTargetFile = thisApp.sLastOpenFile end
	if 0 < thisApp.sLastSaveFile:len() then sTargetFile = thisApp.sLastSaveFile end

	inSelector = inSelector or 1

	if 1 == inSelector then

		sTargetFile = thisApp.tConfig.OutFile
		sOpenMode	= thisApp.tConfig.WriteMode

	elseif 2 == inSelector then

		sTargetFile = sTargetFile or thisApp.tConfig.InFile
	else

		sTargetFile = inOptFilename
		if not sTargetFile then return 0, "Filename undeclared" end
	end

	-- open outut file and write line by line
	--
	local fhTgt = io.open(sTargetFile, sOpenMode)
	if not fhTgt then return 0, "Unable to open output file" end

	for _, tLine in ipairs(thisApp.tFileLines) do
		fhTgt:write(tLine[2])
	end

	fhTgt:close()

	local sText = "File saved in [" .. sTargetFile .. "] (" .. sOpenMode .. ")"
	trace.line(sText)

	thisApp.sLastSaveFile = sTargetFile		-- remember selection

	return thisApp.iFileBytes, sText
end

-- ----------------------------------------------------------------------------
--
local function OnCreateByBlock()
--	trace.line("OnCreateByBlock")

	local sTargetFile = thisApp.tConfig.SamplesFile
	local sOpenMode	  = "a+"
	local tBlocks	  = thisApp.tConfig.ByBlocksRow

	if not tBlocks then return false end

	-- remove the file and allow the application to
	-- open the file in append mode so to handle
	-- properly n calls to createbyblock
	--
	if not os.remove(thisApp.tConfig.SamplesFile) then
		trace.line("Failed to remove old file ...")
	end

	trace.lnTimeStart("Creating samples file ...")

	-- scan the table, each row is a table itself
	-- where the first element is the enabling flag
	-- and the second element is a generic label
	--
	local iAlignAt = thisApp.tConfig.AlignByCols
	local bCompact = thisApp.tConfig.OnlyGroups

	for iRow, iBlock in ipairs(thisApp.tConfig.ByBlocksRow) do

		if iBlock[1] then

			if not samples.ByBlock(iRow, iBlock[2], sTargetFile, sOpenMode, iAlignAt, bCompact) then

				trace.lnTimeEnd("Create samples interrupted, quitting...")
				break
			end
		end
	end

	trace.lnTimeEnd("Create samples end")

	return true
end

-- ----------------------------------------------------------------------------
-- check for memory usage and call a collector walk
-- a megabyte measure is used instead of kilos to reduce
-- the trace messaging using a gross unit of measure
--
local function OnGarbageTest()
--	trace.line("OnGarbageTest")

	local iKilo = collectgarbage("count")
	local iMega = _floor(iKilo / 1024)

	if thisApp.iGarbageCount ~= iMega then

		if iMega > thisApp.iGarbageCount  then

			if "Generational" == thisApp.tConfig.Collector then
				collectgarbage("step", 50)
			else
				collectgarbage("collect")
			end
		end

		-- store for later
		--
		thisApp.iGarbageCount = iMega

		if thisApp.tConfig.TraceMemory then

			local sLine = _format("Memory: [%3d Mb] %s", iMega, _strrep("•", iMega))
			trace.line(sLine)
		end
	end
end

-- ----------------------------------------------------------------------------
-- preamble
--
local function SetUpApplication()
--	trace.line("SetUpApplication")

	local sApplication = thisApp.sAppName .. " (Ver. " .. thisApp.sAppVersion .. ")"
	trace.line(sApplication)
	trace.line("Released: " .. thisApp.sAppRelDate)
	trace.line("_VERSION: " .. _VERSION)

	wx.wxGetApp():SetAppName(sApplication)

	-- wxWidgets can be run only with Lua version 5.2
	--
	assert(thisApp.sChkVer == _VERSION, "Error: " .. thisApp.sChkVer .. " required")

	-- setting the locale is not strictly necessary for this application
	--
	assert(os.setlocale('ita', 'all'))
	trace.line("Current locale is [" .. os.setlocale() .. "]")

	-- will protect the Unicode table from accidental writing to
	--
	samples.Init()

	-- read the configuration file appConfig.lua
	--
	trace.line("Configuring the application")
	if not OnReadSetupInf() then return false end

	return true
end

-- ----------------------------------------------------------------------------
-- leave clean
--
local function QuitApplication()
--	trace.line("QuitApplication")

	-- call the close (shall be not necessary)
	--
	wxWinMain.CloseWindow()

	trace.line(thisApp.sAppName .. " terminated")
end

-- ----------------------------------------------------------------------------
--
local function main(inApplication)

	-- associate the application's reference
	--
	thisApp = inApplication

	-- redirect logging
	--
	io.output(thisApp.sLogFilename)

	if SetUpApplication() then

		if thisApp.tConfig.AutoLoad then OnLoadFile() end

		wx.wxGetApp():SetUseBestVisual(true)
		wx.wxGetApp():SetExitOnFrameDelete(true)

		local hWindow = wxWinMain.ShowWindow(thisApp)
		if hWindow then

			wx.wxGetApp():SetTopWindow(hWindow)

			-- run the main loop
			--
			wx.wxGetApp():MainLoop()
		end
	end

	-- we'll get here only when the main window loop closes
	--
	QuitApplication()

	io.output():close()
end

-- ----------------------------------------------------------------------------
-- application's table
--
local tApplication =
{
	sAppVersion		= "0.0.7",				-- application's version
	sAppRelDate		= "27-dec-18",			-- date of release update
	sAppName		= "wxEncode",			-- name for the application
	sChkVer			= "Lua 5.2",			-- Lua's version required
	sIconFile		= "wxEncode.ico",		-- icon for the application
	sLogFilename	= "wxEncode.log",		-- logging filename
	sTranslateApp 	= "transcode\\transcode.lua",	-- transcoder

	sConfigIni		= "appConfig.lua",		-- filename for the config
	tConfig			= { },					-- configuration for the app.
	iGarbageCount	= 0,					-- last memory check value

	sLastOpenFile	= "",					-- last input filename used
	sLastSaveFile	= "",					-- last output filename used

	tFileLines		= { },					-- line by line memory file
	iFileBytes		= 0,					-- sum of all bytes in tFileLines
	tCheckErrors	= { },					-- table of check UTF_8 errors

	ReadSetupInf	= OnReadSetupInf,		-- read the setupinf.lua file
	LoadFile		= OnLoadFile,			-- load the file in memory
	SaveFile		= OnSaveFile,			-- save memory to file
	CheckEncoding	= OnCheckEncoding,		-- check chars in current file
	GetUTF8Error	= OnGetUTF8Error,		-- get an error from errors' list
	EnumCodepages	= OnEnumCodepages,		-- enumerate available codepages
	Encode_UTF_8	= OnEncode_UTF_8,		-- save the current file UTF_8
	CreateByBlock	= OnCreateByBlock,		-- crate samples of characters
	FindLine		= OnFindLine,			-- test find the row of index
	GetTextAtPos	= OnGetTextAtPos,		-- get text at pos (see appConfig.lua)
	CopySelected	= OnCopySelected,		-- get selected text
	FindText		= OnFindText,			-- find text within the file
	GarbageTest		= OnGarbageTest,		-- test memory and call collect
	CountSequences	= OnCountSequences,		-- test buffer for sequences
}

-- ----------------------------------------------------------------------------
-- run it
--
main(tApplication)

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
