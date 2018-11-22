-- ----------------------------------------------------------------------------
--
--  Utility - helpers
--
-- ----------------------------------------------------------------------------

local Utility = _G.Utility or {}

local _insert	= table.insert
--local _concat	= table.concat
local _format	= string.format
--local _toChar	= string.char

-- ----------------------------------------------------------------------------
-- check if the byte at inStart is a valid utf_8 code
-- returns the full utf_8 code
--
function Utility.utf_8(inBytes, inStart, inEnd)
	
	local sNullCode = "\x00\x00\x00"
	
	if not inBytes or 0 == #inBytes then return sNullCode end
	
	inStart = inStart or 1
	inEnd	= inEnd or #inBytes
	
	if 0 > inStart	 then inStart = -1 * inStart end
	if 0 > inEnd	 then inEnd = -1 * inEnd end
	if 1 > inStart	 then inStart = 1 end
	if #inBytes > inEnd then inEnd = #inBytes end
	if inStart > inEnd then inEnd, inStart = inStart, inEnd end
	
	local ch1 = inBytes:sub(inStart, inStart):byte()
--	local ch2 = inBytes:sub(inStart - 1, inStart - 1):byte()
	
	if 0xc0 < ch1 then
		
		local ch2 = inBytes:sub(inStart + 1, inStart + 1):byte()
		
		if 0x7f < ch2 and ch2 < 0xc0 then
			if 0xdf < ch1 then
				local ch3 = inBytes:sub(inStart + 2, inStart + 2):byte()
				
				return _format("%c%c%c", ch1, ch2, ch3)
				
			else
				return _format("%c%c", ch1, ch2)
			end
			
		else
			
		end
		
	elseif 1 < inStart then
		
		local ch2 = inBytes:sub(inStart - 1, inStart - 1):byte()
		
		if 0x7f < ch2 and ch2 < 0xc0 then
		
			ch1, ch2 = ch2, ch1
		
			if 0xc0 < ch1 then
				return _format("%c%c", ch1, ch2)
			else
			end
		end
	end

	return sNullCode
end

-- ----------------------------------------------------------------------------
-- reverse search and return the extension only
--
function Utility.fileExt(inFullPath)
	
	local ret = ""
	local ch
	
	for i=#inFullPath, 1, -1 do
		
		ch = inFullPath:sub(i, i)
		if '.' == ch then ret = inFullPath:sub(i + 1) break end
	end
	
	return ret
end

-- ----------------------------------------------------------------------------
-- get the filename only out of a complete file path
--
function Utility.fileName(inFullPath, inNameOnly)
	
	local iStart, iEnd
	
	-- remove all occourences of '\'
	--
	while true do
		
		iStart, iEnd = inFullPath:find('\\')		
		if nil == iStart then break end
		
		inFullPath = inFullPath:sub(iEnd + 1) 
	end
		
	-- remove everything from '.' to its right
	--
	if inNameOnly then
		
		local ext = Utility.fileExt(inFullPath)
		if 0 < #ext then inFullPath = inFullPath:sub(1, - #ext - 2) end
	end
	
	return inFullPath
end

-- ----------------------------------------------------------------------------
-- return the top dir in inFilename from inBaseDir to the left
-- c:\usr\test\temp\file.txt     temp    ->  c:\usr\test
--
function Utility.getTopDir(inFilename, inBaseDir)
	
	local sSearch = Utility.fmtfind(inBaseDir)
	local iStart  = inFilename:find(sSearch)
	
	if iStart then return inFilename:sub(1, iStart - 1) end
	
	return nil
	
end

-- ----------------------------------------------------------------------------
-- reads number from a line of text, capable of handling float numbers
--
function Utility.makeArray(inText)
  
	local tNumbers  = { }
	local fValue  
	local sKeyword  = "[+-]?%d+%.?%d*"

	local ind1, ind2 = inText:find(sKeyword)

	while ind1 and ind2 do

		fValue = tonumber(inText:sub(ind1, ind2))

		if fValue then _insert(tNumbers, fValue) end

		ind1, ind2 = inText:find(sKeyword, ind2 + 1)
	end

	return tNumbers
end

-- ----------------------------------------------------------------------------
--
function Utility.isFileReady(inFilename)
  
	if not inFilename then return false end

	local hFile = io.open(inFilename, "r")  
	if not hFile then return false end  

	hFile:close()

	return true
end

-- ----------------------------------------------------------------------------
-- read
---
function Utility.file2Table(inSrcName)
	
	local tWords_0 = {}
	
	local fhSrc = io.open(inSrcName, "r")
	if not fhSrc then return tWords_0 end
	
	for aLine in fhSrc:lines() do
		if 1 < #aLine then
			_insert(tWords_0, aLine)
		end
	end			
	fhSrc:close()
	
	return tWords_0
end

-- ----------------------------------------------------------------------------
-- save
--
function Utility.table2File(inSrcName, inTable)
		
	local fhSrc = io.open(inSrcName, "w")
	if not fhSrc then return false end

	for i=1, #inTable do 
		fhSrc:write(inTable[i]) 
		fhSrc:write("\n") 
	end		
	fhSrc:close()

	return true
end

-- ----------------------------------------------------------------------------
-- protect access to a table
--
function protect(tbl)
  return setmetatable({}, {
    __index = tbl,
    __newindex = function(_, key, value)
        error("attempting to change constant " ..
               tostring(key) .. " to " .. tostring(value), 2)
    end
  })
end

-- ----------------------------------------------------------------------------
--

return Utility

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
