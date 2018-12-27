-- ----------------------------------------------------------------------------
--
--  main - driver for the translator
--
-- ----------------------------------------------------------------------------

package.path = package.path .. ";?.lua;"

local translate	= require "translate"	-- conversion processor
				  require "extrastr"	-- extra string processor
				  
local _format   = string.format
local _endwipe	= string.endwipe

-- ----------------------------------------------------------------------------
--
local function FileExists(inFilename)
	
	local fhSrc = io.open(inFilename, "r")
	if not fhSrc then return false end
	
	fhSrc:close()
	return true
end

-- ----------------------------------------------------------------------------
-- expect arguments:
-- 1> input filename
-- 2> output filename
-- 3> Codepage label (ISO, OEM, Windows)
-- 4> Codepage identification
--
local function driver(...)
	
	local inFilename, outFilename, sCodepage, iPageId = ...
	
	if not FileExists(inFilename) then io.write("Input file not found\n") return end
	
	-- note that the Codepage function wants a table as parameter
	--
	local codepage = translate.Codepage({sCodepage, iPageId})
	if not codepage then io.write("Codepage requested not found\n") return end
	
	-- read all lines (with newline)
	--
	local tLines = { }
	
	for sLine in io.lines(inFilename, "*L") do
		
		-- convert each line
		--
		tLines[#tLines + 1] = translate.Processor(sLine, codepage)		
	end
	
	-- write all lines to output file
	--
	local fhTgt = io.open(outFilename, "w")
	for _, sLine in ipairs(tLines) do
		fhTgt:write(sLine)
	end
	fhTgt:close()
	
	io.write("Translation completed\n")
end

-- ----------------------------------------------------------------------------
-- expect arguments:
-- 1> input filename
-- 2> output filename
--
local function cleaner(inDirectory)
	
	local tFileList	= { }
	
	-- ----------------------------------
	-- enumerate files in given directory
	--
	local function EnumFiles(inDirectory)

		local sPOpenCmd = 'chcp 1252 | dir /B /O:N /S /A:-D '
		local sCommand  = sPOpenCmd .. '"' .. inDirectory .. '"'

		local fhSrc = io.popen(sCommand, "r")
				
		for sFilename in fhSrc:lines() do
			tFileList[#tFileList + 1] = sFilename
		end
		
		-- return count of files
		--
		return #tFileList
	end
	
	-- ------------------------------
	-- do a cleanup of selected file
	-- return the total bytes removed
	--
	local function ProcessFile(inFilename)
	
		if not FileExists(inFilename) then io.write("Input file not found\n") return 0 end

		-- read all lines (with newline)
		--
		local tLines = { }
		local iTotal = 0			-- total removed
		local iSkipped				-- partial removed
		
		for sLine in io.lines(inFilename, "*L") do
			
			-- convert each line
			--
			iSkipped, tLines[#tLines + 1] = _endwipe(sLine)
			iTotal = iTotal + iSkipped
		end
		
		-- (over)write all lines to output file
		--
		local fhTgt = io.open(inFilename, "w")
		for _, sLine in ipairs(tLines) do
			fhTgt:write(sLine)
		end
		fhTgt:close()
		
		return iTotal
	end
	
	-- -----------------
	-- start of function
	--
	local iCount = EnumFiles(inDirectory)
	
	if 0 == iCount then
		io.write("No file found\n")
		return
	end
	
	local iRemoved
	
	for _, sFilename in ipairs(tFileList) do
		io.write(_format("Cleaning [%s]\n", sFilename))
		iRemoved = ProcessFile(sFilename)
		io.write(_format("Cleaned  [%s]\tremoved [%d]\n", sFilename, iRemoved))
	end

	io.write("Cleanup completed\n")
end

-- ----------------------------------------------------------------------------
-- run it
--
driver("Test\\Pres.txt", "Test\\Pres_out.txt", "OEM", 437)
driver("Test\\LiesMich.txt", "Test\\LiesMich_out.txt", "Windows", 1252)
cleaner("Test")

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
