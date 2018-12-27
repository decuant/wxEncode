-- ----------------------------------------------------------------------------
--
--  wxEncode - guess file encoding
--
-- note that almost everywhere in this file is used the operator
-- string.len instead of #array because strings can contain
-- embedded zeros
-- ----------------------------------------------------------------------------

package.path = package.path .. ";translate/?.lua;"

local trace		= require "trace"		-- shortcut for tracing
local wxWinMain	= require "wxMain"		-- GUI for the application
local samples	= require "uniBlocks"	-- create a list of Unicode blocks
				  require "extrastr"	-- extra string processor

local _format	= string.format
local _strrep	= string.rep
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

	while iStart <= iEnd do

		iIndex = _floor(iStart + (iEnd - iStart) / 2)

		tCurr = inTable[iIndex]
		iSum  = tCurr[1] + tCurr[2]:len()

		if tCurr[1] <= inByteIndex and inByteIndex < iSum then
			return iIndex
		end

		if iSum <= inByteIndex then iStart = iIndex + 1 else iEnd = iIndex - 1 end
	end

	return -1
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
	local iLineIndex = OnLookupInterval(tLines, inStartPos)	-- get line of text
	if 0 > iLineIndex then return -1 end

	inStartPos = inStartPos - tLines[iLineIndex][1]			-- normalize

	if inNoCase then inText = inText:upper() end			-- check for case

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
-- get text from source buffer with the line starting at
-- at inStopStart and the offset at inOffset
-- depending on the configuration will extract
-- 1 byte
-- an UTF_8 code made of 1 to 4 bytes
-- a word starting from punctuation to punctuation
-- a sequence of words stopping at the new line
--
local function OnGetTextAtPos(inStopStart, inOffset, inOption)
--	trace.line("OnGetTextAtPos")

	local iLineIndex = OnLookupInterval(thisApp.tFileLines, inStopStart)	-- get line of text
	if 0 == iLineIndex then return 0, "Nothing in memory" end

	inOption = inOption or thisApp.tConfig.CopyOption						-- check for option

	local sSource= thisApp.tFileLines[iLineIndex][2]

	if "Line" == inOption then return sSource:len(), sSource end

	local iPosition = inOffset - inStopStart + 1							-- normalize offset

	if 0 < iPosition and iPosition < sSource:len() then

		if "Byte" == inOption then return 1, sSource:sub(iPosition, iPosition) end

		if "UTF_8" == inOption then

			local sCopyBuff = _utf8sub(sSource, iPosition)

			return sCopyBuff:len(), sCopyBuff
		end

		-- handle the Word selection
		--
		local sCopyBuff = _wordsub(sSource, iPosition)
		if sCopyBuff then return sCopyBuff:len(), sCopyBuff end

	end

	return 0, "Error !"
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
--
local function OnCheckEncoding()
--	trace.line("OnCheckEncoding")

	trace.lnTimeStart("Testing UTF_8 validity ...")

	local tCounters = {0, 0, 0, 0, 0}		-- UTF1, UTF2, UTF3, UTF4, ERRORS

	local iIndex
	local chCurr
	local sLine
	local iEnd
	local iRetCode
	local tLineOut = { }

	-- format for each line is
	-- {offset from start of file, line of text}
	--
	for iCurLine, tLine in ipairs(thisApp.tFileLines) do

		sLine = tLine[2]

		-- UTF_8 aware splitting
		--
		iIndex	= 1
		iEnd	= sLine:len()

		while iEnd >= iIndex do

			-- get next char, which might span from 1 byte to 4 bytes
			--
			chCurr, iRetCode = _utf8sub(sLine, iIndex)
			tLineOut[#tLineOut + 1] = chCurr

			-- a negative index is an error
			--
			if 0 > iRetCode then

				if thisApp.tConfig.Pedantic then
					trace.line(_format("Line [%4d:%2d] -> [%s]", iCurLine, iIndex, chCurr))
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

	return true, sText
end

-- ----------------------------------------------------------------------------
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
	thisApp.tFileLines = { }
	thisApp.iFileBytes = 0

	-- refresh setup
	--
	if not OnReadSetupInf() then return 0, "Configuration file load failed." end

	-- get names from configuration file
	--
	local sSourceFile = thisApp.tConfig.InFile
	local sOpenMode	  = thisApp.tConfig.ReadMode

	-- override if importing and a different name was provided
	--
	if thisApp.sLastOpenFile then sSourceFile = thisApp.sLastOpenFile end
	if thisApp.sLastSaveFile then sSourceFile = thisApp.sLastSaveFile end

	-- override if a filename was provided
	--
	if inOptFilename then sSourceFile = inOptFilename end

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

	local sTargetFile = thisApp.sLastSaveFile or thisApp.sLastOpenFile
	local sOpenMode   = "w"

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

	trace.line(thisApp.sAppName .. " (Ver. " .. thisApp.sAppVersion .. ")")
	trace.line("Released: " .. thisApp.sAppRelDate)
	trace.line("_VERSION: " .. _VERSION)

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

		wxWinMain.ShowWindow(thisApp)
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
	sTranslateApp 	= "translate\\translate.lua",	-- translator

	sConfigIni		= "appConfig.lua",		-- filename for the config
	tConfig			= { },					-- configuration for the app.
	iGarbageCount	= 0,					-- last memory check value

	sLastOpenFile	= nil,					-- last input filename used
	sLastSaveFile	= nil,					-- last output filename used

	tFileLines		= { },					-- line by line memory file
	iFileBytes		= 0,					-- sum of all bytes in tFileLines

	ReadSetupInf	= OnReadSetupInf,		-- read the setupinf.lua file
	LoadFile		= OnLoadFile,			-- load the file in memory
	SaveFile		= OnSaveFile,			-- save memory to file
	CheckEncoding	= OnCheckEncoding,		-- check chars in current file
	EnumCodepages	= OnEnumCodepages,		-- enumerate available codepages
	Encode_UTF_8	= OnEncode_UTF_8,		-- save the current file UTF_8
	CreateByBlock	= OnCreateByBlock,		-- crate samples of characters
	LookupInterval	= OnLookupInterval,		-- test find the row of index
	GetTextAtPos	= OnGetTextAtPos,		-- get text at pos (see setupinf.lua)
	FindText		= OnFindText,			-- find text within the file
	GarbageTest		= OnGarbageTest,		-- test memory and call collect
}

-- ----------------------------------------------------------------------------
-- run it
--
main(tApplication)

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
