-- ----------------------------------------------------------------------------
--
--  Utility
--
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--
module(..., package.seeall)

local Utility = Utility or {}

-- ----------------------------------------------------------------------------
-- remove leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(programming)
--
function Utility.ltrim(inString)  
	if not inString then return "" end
	
	return inString:gsub("^%s*", "")
end

-- ----------------------------------------------------------------------------
-- remove trailing whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(programming)
--
function Utility.rtrim(inString)	
	if not inString then return "" end
	
	local n = #inString
	
	while n > 0 and inString:find("^%s", n) do n = n - 1 end
	
	return inString:sub(1, n)
end

-- ----------------------------------------------------------------------------
--
function Utility.trim(inString)
	
	return Utility.ltrim(Utility.rtrim(inString))	
end

-- ----------------------------------------------------------------------------
--
function Utility.capitalize(inString)
	
	local index, sPre, sPost
	
	index = inString:find("^%s")
	
	local chStart = inString:sub(1)
	chStart = chStart:upper()
	inString = inString:lower():sub(1)
	
	chStart = chStart .. inString
	
	return chStart
end

-- ----------------------------------------------------------------------------
-- remove all occourrences of a character, with the option of replacing it
--
function Utility.strip(inString, inChOld, inChNew)
	
	local sOutString = ""
	local chCurrent
	
	for i=1, #inString do
		
		chCurrent = inString:sub(i, i)
		
		if inChOld == chCurrent then 
			if inChNew then chCurrent = inChNew else chCurrent = "" end
		end
			
		sOutString = sOutString .. chCurrent	
	end

	return sOutString
end


-- ----------------------------------------------------------------------------
-- put a % before each char that must be escaped for the string.find function
--
function Utility.fmtfind(inString)
	
	local sOutString = ""
	local chCurrent
	
	for i=1, #inString do
		
		chCurrent = inString:sub(i, i)
		
		if     '.' == chCurrent then chCurrent = "%."
		elseif '_' == chCurrent then chCurrent = "%_"
		elseif '-' == chCurrent then chCurrent = "%-"
		elseif '[' == chCurrent then chCurrent = "%["
		elseif ']' == chCurrent then chCurrent = "%]"
		elseif '(' == chCurrent then chCurrent = "%("
		elseif ')' == chCurrent then chCurrent = "%)"
		
		end
	
		sOutString = sOutString .. chCurrent
	
	end

	return sOutString	
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
  
  local floats  = {}
  local pattern = "[+-]?%d+%.?%d*"
  
  local ind1, ind2 = string.find(inText, pattern)
  
  while ind1 and ind2 do
    
    local number = tonumber(string.sub(inText, ind1, ind2))
    
    if number then table.insert(floats, number) end
    
    ind1, ind2 = string.find(inText, pattern, ind2 + 1)
  end
  
  return floats
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
			table.insert(tWords_0, aLine)
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
    __newindex = function(t, key, value)
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
