-- ----------------------------------------------------------------------------
--
--  ExtraStr - helpers for the string library
--
-- ----------------------------------------------------------------------------

local _insert	= table.insert
local _concat	= table.concat
local _toChar	= string.char

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
-- check if the byte at inStart is a valid utf_8 code
-- returns the full utf_8 code or the best available
-- the second returned value is
-- -1 		error
--  [1..4] 	length of full Unicode char
--
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
	{0x00, 0x7f, 0},
	{0xc2, 0xdf, 1, 0x80, 0xbf},	
	{0xe0, 0xe0, 2, 0xa0, 0xbf, 0x80, 0xbf},
	{0xe1, 0xec, 2, 0x80, 0xbf, 0x80, 0xbf},
	{0xed, 0xed, 2, 0x80, 0x9f, 0x80, 0xbf},	
	{0xee, 0xef, 2, 0x80, 0xbf, 0x80, 0xbf},
	{0xf0, 0xf0, 3, 0x90, 0xbf, 0x80, 0xbf, 0x80, 0xbf},
	{0xf1, 0xf3, 3, 0x80, 0xbf, 0x80, 0xbf, 0x80, 0xbf},
	{0xf4, 0xf4, 3, 0x80, 0x8f, 0x80, 0xbf, 0x80, 0xbf},
}

local function str_lkp_utf_8(inCode)
	
	for _, row in ipairs(tUTF8Lookup) do
		if row[1] <= inCode and inCode <= row[2] then return row end
	end
	
	return nil
end


local function str_sub_utf_8(inBytes, inStart)

	-- sanity check
	--
	if not inBytes then return "\x00", -1 end
	
	inStart = inStart or 1
	if (1 > inStart) or (inStart > #inBytes) then return "\x00", -1 end
	
	-- check if start of a Unicode point
	-- get the Unicode row description, if any
	--
	local ch1		= inBytes:sub(inStart, inStart):byte()
	local utf8Codes = str_lkp_utf_8(ch1)	
	
	if not utf8Codes then return _toChar(ch1), -1 end
	
	-- quick shot to return when no check needed
	--
	local iChkLen = utf8Codes[3]
	if 0 == iChkLen then return _toChar(ch1), 1 end
	
	-- check if enough bytes to complete the request
	-- when at the end must return too
	-- but here the Unicode point is correct, thus
	-- has to return with an error
	--
	if #inBytes == inStart 	then return _toChar(ch1), -1 end
	if #inBytes < (inStart + iChkLen) then return _toChar(ch1), -1 end
	
	-- check each byte if in list of intervals
	--
	local iOffset = 3
	
	for j=1, iChkLen do
		local chTest = inBytes:sub(inStart + j, inStart + j):byte()
		
		if not (utf8Codes[iOffset + j] <= chTest and chTest <= utf8Codes[iOffset + j + 1]) then
			
			-- this is an error, byte out of bounds
			--
			return inBytes:sub(inStart, inStart + j - 1), (- 1 * j)
		end
		
		iOffset = iOffset + 1
	end
	
	-- this a complete Unicode string of lenght > 1
	--
	return inBytes:sub(inStart, inStart + iChkLen), (iChkLen + 1)
end

-- ----------------------------------------------------------------------------
-- extract an entire alfa-word (with punctuation) from a buffer
-- stops start and end at reject character
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

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
