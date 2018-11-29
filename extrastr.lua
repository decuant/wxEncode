-- ----------------------------------------------------------------------------
--
--  ExtraStr - helpers for the string library
--
-- ----------------------------------------------------------------------------

local _floor	= math.floor
local _insert	= table.insert
local _concat	= table.concat
local _toChar	= string.char
local _format	= string.format

-- ----------------------------------------------------------------------------
-- count the number of occurrences of the specified text
--
local function str_gcount(inBytes, inValue)
	
	local iCount = 0

	if inBytes and inValue then
	
		local iEnd	 = inBytes:find(inValue, 1, true)
		
		while iEnd do
			
			iCount	= iCount + 1
			iEnd 	= inBytes:find(inValue, iEnd + 1, true)
		end
	end

	return iCount
end

-- ----------------------------------------------------------------------------
-- remove leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(programming)
--
local function str_ltrim(inString)  
	if not inString then return "" end
	
	return inString:gsub("^%s*", "")
end

-- ----------------------------------------------------------------------------
-- remove trailing whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(programming)
--
local function str_rtrim(inString)	
	if not inString then return "" end
	
	local n = #inString
	
	while n > 0 and inString:find("^%s", n) do n = n - 1 end
	
	return inString:sub(1, n)
end

-- ----------------------------------------------------------------------------
--
local function str_trim(inString)
	if not inString then return "" end
	
	return str_ltrim(str_rtrim(inString))	
end

-- ----------------------------------------------------------------------------
--
local function str_cap1st(inString)	
	if not inString then return "" end
		
	return (inString:sub(1):upper() .. inString:lower():sub(1))
end

-- ----------------------------------------------------------------------------
-- put a % before each char that must be escaped for the string.find function
--
local function str_fmtfind(inString)
	if not inString then return "" end

	local tOutString = { }
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
	
		_insert(tOutString, chCurrent)	
	end

	return _concat(tOutString, nil)	
end

-- ----------------------------------------------------------------------------
-- given a natural number returns a string where
-- 1024 	-> 1 kb
-- 1024^2	-> 1 Mb
-- 1024^3	-> 1 Gb
--
local function str_fmtkilo(inNum)
	
	if 0 < inNum then
	
		local iKilo = _floor(inNum / 1024)
		local iMega = _floor(iKilo / 1024)
		local iGiga	= _floor(iMega / 1024)
		local iTera	= _floor(iGiga / 1024)
		
		if 0 < iTera then return _format("%d Tb", iTera) end
		if 0 < iGiga then return _format("%d Gb", iGiga) end
		if 0 < iMega then return _format("%d Mb", iMega) end
		if 0 < iKilo then return _format("%d Kb", iKilo) end
	end

	return _format("%d b", inNum)
end

-- ----------------------------------------------------------------------------
-- ABNF from RFC 3629
--
-- UTF8-octets = *( UTF8-char )
-- UTF8-char   = UTF8-1 / UTF8-2 / UTF8-3 / UTF8-4
-- UTF8-1      = %x00-7F
-- UTF8-2      = %xC2-DF UTF8-tail
-- UTF8-3      = %xE0 %xA0-BF UTF8-tail / %xE1-EC 2( UTF8-tail ) /
--               %xED %x80-9F UTF8-tail / %xEE-EF 2( UTF8-tail )
-- UTF8-4      = %xF0 %x90-BF 2( UTF8-tail ) / %xF1-F3 3( UTF8-tail ) /
--               %xF4 %x80-8F 2( UTF8-tail )
-- UTF8-tail   = %x80-BF
--
local tUTF8Lookup =
{
	{0x00, 0x7f},
	{0xc2, 0xdf, 0x80, 0xbf},	
	{0xe0, 0xe0, 0xa0, 0xbf, 0x80, 0xbf},
	{0xe1, 0xec, 0x80, 0xbf, 0x80, 0xbf},
	{0xed, 0xed, 0x80, 0x9f, 0x80, 0xbf},	
	{0xee, 0xef, 0x80, 0xbf, 0x80, 0xbf},
	{0xf0, 0xf0, 0x90, 0xbf, 0x80, 0xbf, 0x80, 0xbf},
	{0xf1, 0xf3, 0x80, 0xbf, 0x80, 0xbf, 0x80, 0xbf},
	{0xf4, 0xf4, 0x80, 0x8f, 0x80, 0xbf, 0x80, 0xbf},
}

-- ----------------------------------------------------------------------------
-- return the row that contains the parameter
-- of the lookup table only the first 2 entries are used
--
local function str_lkp_utf_8(inCode)
	
	for iIndex=1, #tUTF8Lookup do
		if tUTF8Lookup[iIndex][1] <= inCode and inCode <= tUTF8Lookup[iIndex][2] then 
			return tUTF8Lookup[iIndex] 
		end
	end
	
	return nil
end

-- ----------------------------------------------------------------------------
-- check if the byte at inStart is a valid utf_8 code
-- returns the full utf_8 code or the best available
-- the second returned value is
-- -1 		error
--  [1..4] 	length of full Unicode char
--
local function str_sub_utf_8(inBytes, inStart)
	
	-- check if start of a Unicode point
	-- get the Unicode row description, if any
	--
	local chMark	= inBytes:sub(inStart, inStart)
	local utf8Codes = str_lkp_utf_8(chMark:byte())	
	
	if not utf8Codes then return chMark, -1 end
	
	-- quick shot to return when no check needed
	--
	local iChkLen = (#utf8Codes / 2) - 1
	if 0 == iChkLen then return chMark, 1 end
	
	-- check if enough bytes to complete the request
	--
	if #inBytes < (inStart + iChkLen) then return chMark, -1 end
	
	-- check each byte if in list of intervals
	--
	local chCode
	local iOffset = 2
	
	for j=1, iChkLen do
		
		chCode = inBytes:sub(inStart + j, inStart + j):byte()
		
		if not (utf8Codes[iOffset + j] <= chCode and chCode <= utf8Codes[iOffset + j + 1]) then
			
			-- this is an error, byte out of bounds
			--
			return inBytes:sub(inStart, inStart + j - 1), (- 1 * j)
		end
		
		iOffset = iOffset + 1
	end
	
	-- this a complete Unicode string of length > 1
	--
	return inBytes:sub(inStart, inStart + iChkLen), (iChkLen + 1)
end

-- ----------------------------------------------------------------------------
-- boolean test if a given byte value is an ASCII punctuation character
--
local function str_ispunct(inByte)
	
	local chReject = " \t\n:.;,\'\"`<>()[]{}~!?@#£$§%^&*-_+=|\\/"
	
	for iIndex = 1, #chReject do
		if inByte == chReject:sub(iIndex, iIndex) then return true end
	end
	
	return false
end

-- ----------------------------------------------------------------------------
-- extract an entire alfa-word (with punctuation) from a buffer
-- stops start and end at puctuation characters
--
local function str_wordsub(inBytes, inPosition)
	
	-- sanity check
	--
	if not inBytes then return nil end
	if inPosition > #inBytes then return nil end
	
	-- get the first space character before beginning of word
	--
	local ch
	
	local iStart = inPosition
	while 1 <= iStart do
	
		ch = inBytes:sub(iStart, iStart)
		if str_ispunct(ch) then break end
		
		iStart = iStart - 1
	end
	
	-- get first space character after end of word
	--
	local iEnd = inPosition	
	while iEnd <= #inBytes do
		
		ch = inBytes:sub(iEnd, iEnd)
		if str_ispunct(ch) then break end
		
		iEnd = iEnd + 1
	end
	
	-- extract word from entire line
	--
	return inBytes:sub(iStart + 1, iEnd - 1)
end

-- ----------------------------------------------------------------------------
-- install in the string library
--
if not string.gcount  then string.gcount  = str_gcount end
if not string.ltrim   then string.ltrim   = str_ltrim end
if not string.rtrim   then string.rtrim   = str_rtrim end
if not string.trim    then string.trim    = str_trim end
if not string.cap1st  then string.cap1st  = str_cap1st end
if not string.fmtfind then string.fmtfind = str_fmtfind end
if not string.utf8sub then string.utf8sub = str_sub_utf_8 end
if not string.ispunct then string.ispunct = str_ispunct end
if not string.wordsub then string.wordsub = str_wordsub end
if not string.fmtkilo then string.fmtkilo = str_fmtkilo end

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
