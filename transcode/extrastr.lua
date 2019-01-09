-- ----------------------------------------------------------------------------
--
--  ExtraStr - helpers for the string library
--
-- ----------------------------------------------------------------------------

local _floor	= math.floor
local _concat	= table.concat
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

		tOutString[#tOutString + 1] = chCurrent
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
	{0x00, 0x7f},											-- 1 column
	{0xc2, 0xdf, 0x80, 0xbf},
	{0xe0, 0xe0, 0xa0, 0xbf, 0x80, 0xbf},
	{0xe1, 0xec, 0x80, 0xbf, 0x80, 0xbf},
	{0xed, 0xed, 0x80, 0x9f, 0x80, 0xbf},
	{0xee, 0xef, 0x80, 0xbf, 0x80, 0xbf},
	{0xf0, 0xf0, 0x90, 0xbf, 0x80, 0xbf, 0x80, 0xbf},
	{0xf1, 0xf3, 0x80, 0xbf, 0x80, 0xbf, 0x80, 0xbf},
	{0xf4, 0xf4, 0x80, 0x8f, 0x80, 0xbf, 0x80, 0xbf},		-- 4 columns
}

-- ----------------------------------------------------------------------------
-- return the row that contains the parameter in the very first column
--
local function str_lkp_utf_8(inCode)

	if inCode then
		for iIndex=1, #tUTF8Lookup do
			if tUTF8Lookup[iIndex][1] <= inCode and inCode <= tUTF8Lookup[iIndex][2] then
				return tUTF8Lookup[iIndex]
			end
		end
	end

	return nil
end

-- ----------------------------------------------------------------------------
-- return length of UTF_8 character (1 to 4)
-- on error return 0
--
local function str_len_utf_8(inBytes, inStart)

	if 1 > inStart or #inBytes < inStart then return 0 end
	local chByte = inBytes:byte(inStart, inStart)

	-- quick shot, we know first 0x7f values are 1 byte long
	--
	if 0x80 > chByte then return 1 end

	-- otherwise we check the lookup table
	--
	local utf8Codes = str_lkp_utf_8(chByte)
	if not utf8Codes then return 0 end

	return (#utf8Codes / 2)
end

-- ----------------------------------------------------------------------------
-- extract an UTF_8 bytes sequence out of a bytes array
-- check if each byte is valid
-- returns 2 values:
-- 1. the full utf_8 code or the first byte of the sequence
-- 2. validity check as:
--	    -1 		error
--    [1..4] 	length of full utf8 sequence
--
-- Note: Unicode recommends to return always the first byte in case of error.
--
local function str_sub_utf_8(inBytes, inStart)

	-- sanity checks
	--
	if 1 > inStart then return "", -1 end

	local iLength = inBytes:len()
	if iLength < inStart then return "", -1 end

	-- start byte, the mark
	--
	local chMark  = inBytes:sub(inStart, inStart)
	local chByte  = chMark:byte()

	-- quick shot, we know first 0x7f characters are 1 byte long
	--
	if 0x80 > chByte then return chMark,  1 end

	-- otherwise we get the exact row in the lookup table
	--
	local utf8Codes = str_lkp_utf_8(chByte)
	if not utf8Codes then return chMark, -1 end

	-- check if enough bytes to complete the request
	--
	local iChkLen = (#utf8Codes / 2) - 1
	if iLength < (inStart + iChkLen) then return chMark, -1 end

	-- check each byte if in list of intervals
	--
	local chCode
	local iOffset = 2

	for j=1, iChkLen do

		chCode = inBytes:byte(inStart + j, inStart + j)

		if utf8Codes[iOffset + j]     > chCode or
		   utf8Codes[iOffset + j + 1] < chCode then

			-- this is an error, byte's value out of bounds
			-- as per the Unicode's recommendation return 1 byte
			--
			return chMark, -1
		end

		iOffset = iOffset + 1
	end

	-- this a complete UTF_8 character of length > 1
	--
	return inBytes:sub(inStart, inStart + iChkLen), (iChkLen + 1)
end

-- ----------------------------------------------------------------------------
-- iterator for UTF_8 characters in a line of text
--
local function str_iter_utf_8_char(inText)
	
	local iCurr	 = 1
	local bError = false
	
	return function ()
		
		local sUtf8, iULen = inText:utf8sub(iCurr)
		
		-- adjust the current position
		--
		if - 1 == iULen then 
			iCurr  = iCurr + 1
			bError = true
		else 
			iCurr  = iCurr + iULen
			bError = false
		end
		
		if -1 == iULen and 0 == sUtf8:len() then sUtf8 = nil end
			
		return sUtf8, bError		
	end
end

-- ----------------------------------------------------------------------------
-- Unicode's punctuation characters
-- Note: the fisrt row contains only ASCII codes
--
-- Hint: comment the variable declaration and content to get run-time load of
--       punctuation characters from file.
--
local sUnicodePunct = 
"\x09\x0a\x0d\x20\x21\x22\x23\x24\x25\x26\x27\x28\x29\x2a\x2b\x2c\x2d\x2e\x2f\x3a\x3b\x3c\x3d\x3e\x3f\x40\x5b\x5c\x5d\x5e\x5f\x60\x7b\x7c\x7d\x7e\z
\xc2\xa0\xc2\xa1\xc2\xa2\xc2\xa3\xc2\xa4\xc2\xa5\xc2\xa6\xc2\xa7\xc2\xa8\xc2\xa9\xc2\xaa\xc2\xab\xc2\xac\xc2\xad\xc2\xae\xc2\xaf\z
\xc2\xb0\xc2\xb1\xc2\xb2\xc2\xb3\xc2\xb4\xc2\xb5\xc2\xb6\xc2\xb7\xc2\xb8\xc2\xb9\xc2\xba\xc2\xbb\xc2\xbf\xcd\xbe\xce\x87\xd6\x89\z
\xd6\x8a\xd6\xb0\xd6\xb1\xd6\xb2\xd6\xb3\xd6\xb4\xd6\xb5\xd6\xb6\xd6\xb7\xd6\xb8\xd6\xb9\xd6\xba\xd6\xbb\xd6\xbc\xd6\xbd\xd6\xbe\z
\xd6\xbf\xd7\x80\xd7\x81\xd7\x82\xd7\x83\xd7\x86\xd7\x87\xd7\xb3\xd7\xb4\xd8\x89\xd8\x8a\xd8\x8c\xd8\x8d\xd8\x9b\xd8\x9e\xd8\x9f\z
\xd9\xaa\xd9\xab\xd9\xac\xd9\xad\xdb\x94\xdc\x80\xdc\x81\xdc\x82\xdc\x83\xdc\x84\xdc\x85\xdc\x86\xdc\x87\xdc\x88\xdc\x89\xdc\x8a\z
\xdc\x8b\xdc\x8c\xdc\x8d\xe0\xa0\xb7\xe0\xa0\xb8\xe0\xa0\xb9\xe0\xa1\xb0\xe0\xa1\xb1\xe0\xa1\xb2\xe0\xa1\xb3\xe0\xa1\xb4\xe0\xa1\xb5\z
\xe0\xa1\xb6\xe0\xa1\xb7\xe0\xa1\xb8\xe0\xa1\xb9\xe0\xa1\xba\xe0\xa1\xbb\xe0\xa1\xbc\xe0\xa1\xbd\xe0\xa1\xbe\xe0\xa2\x9e\xe0\xa6\xa4\z
\xe0\xa6\xa5\xe0\xb8\xb4\xe0\xbd\xba\xe0\xbd\xbb\xe0\xbd\xbc\xe0\xbd\xbd\xe1\x81\x8a\xe1\x81\x8b\xe1\x83\xbb\xe1\x8d\xa0\xe1\x8d\xa1\z
\xe1\x8d\xa2\xe1\x8d\xa3\xe1\x8d\xa4\xe1\x8d\xa5\xe1\x8d\xa6\xe1\x8d\xa7\xe1\x8d\xa8\xe1\x90\x80\xe1\x99\xae\xe1\x9a\x80\xe1\x9a\x9b\z
\xe1\x9a\x9c\xe1\x9b\xab\xe1\x9b\xac\xe1\x9b\xad\xe1\x9c\xb5\xe1\x9c\xb6\xe1\xa0\x80\xe1\xa0\x81\xe1\xa0\x82\xe1\xa0\x83\xe1\xa0\x84\z
\xe1\xa0\x85\xe1\xa0\x86\xe1\xa0\x87\xe1\xa0\x88\xe1\xa0\x89\xe1\xa0\x8a\xe1\xaa\xa3\xe1\xaa\xa4\xe1\xaa\xa5\xe1\xaa\xa6\xe1\xaa\xa8\z
\xe1\xaa\xa9\xe1\xaa\xaa\xe1\xaa\xab\xe1\xaa\xac\xe1\xaa\xad\xe1\xad\x9a\xe1\xad\x9b\xe1\xad\x9c\xe1\xad\x9d\xe1\xad\x9e\xe1\xad\x9f\z
\xe1\xad\xa0\xe1\xaf\xbc\xe1\xaf\xbd\xe1\xaf\xbe\xe1\xaf\xbf\xe1\xb0\xbb\xe1\xb0\xbc\xe1\xb0\xbd\xe1\xb0\xbe\xe1\xb0\xbf\xe1\xb1\xbe\z
\xe1\xb1\xbf\xe1\xb3\x80\xe1\xb3\x81\xe1\xb3\x82\xe1\xb3\x83\xe1\xb3\x84\xe1\xb3\x85\xe1\xb3\x86\xe1\xb3\x87\xe2\x80\x80\xe2\x80\x81\z
\xe2\x80\x82\xe2\x80\x83\xe2\x80\x84\xe2\x80\x85\xe2\x80\x86\xe2\x80\x87\xe2\x80\x88\xe2\x80\x89\xe2\x80\x8a\xe2\x80\x8b\xe2\x80\x8c\z
\xe2\x80\x8d\xe2\x80\x8e\xe2\x80\x8f\xe2\x80\x90\xe2\x80\x91\xe2\x80\x92\xe2\x80\x93\xe2\x80\x94\xe2\x80\x95\xe2\x80\x96\xe2\x80\x97\z
\xe2\x80\x98\xe2\x80\x99\xe2\x80\x9a\xe2\x80\x9b\xe2\x80\x9c\xe2\x80\x9d\xe2\x80\x9e\xe2\x80\x9f\xe2\x80\xa0\xe2\x80\xa1\xe2\x80\xa2\z
\xe2\x80\xa3\xe2\x80\xa4\xe2\x80\xa5\xe2\x80\xa6\xe2\x80\xa7\xe2\x80\xa8\xe2\x80\xa9\xe2\x80\xaa\xe2\x80\xab\xe2\x80\xac\xe2\x80\xad\z
\xe2\x80\xae\xe2\x80\xaf\xe2\x80\xb0\xe2\x80\xb1\xe2\x80\xb2\xe2\x80\xb3\xe2\x80\xb4\xe2\x80\xb5\xe2\x80\xb6\xe2\x80\xb7\xe2\x80\xb8\z
\xe2\x80\xb9\xe2\x80\xba\xe2\x80\xbb\xe2\x80\xbc\xe2\x80\xbd\xe2\x80\xbe\xe2\x80\xbf\xe2\x81\x80\xe2\x81\x81\xe2\x81\x82\xe2\x81\x83\z
\xe2\x81\x84\xe2\x81\x85\xe2\x81\x86\xe2\x81\x87\xe2\x81\x88\xe2\x81\x89\xe2\x81\x8a\xe2\x81\x8b\xe2\x81\x8c\xe2\x81\x8d\xe2\x81\x8e\z
\xe2\x81\x8f\xe2\x81\x90\xe2\x81\x91\xe2\x81\x92\xe2\x81\x93\xe2\x81\x94\xe2\x81\x95\xe2\x81\x96\xe2\x81\x97\xe2\x81\x98\xe2\x81\x99\z
\xe2\x81\x9a\xe2\x81\x9b\xe2\x81\x9c\xe2\x81\x9d\xe2\x81\x9e\xe2\x81\x9f\xe2\x81\xa1\xe2\x81\xa2\xe2\x81\xa3\xe2\x81\xa4\xe2\x81\xa6\z
\xe2\x81\xa7\xe2\x81\xa8\xe2\x81\xa9\xe2\x8c\xa9\xe2\x8c\xaa\xe2\x8e\xb4\xe2\x8e\xb5\xe2\x8e\xb6\xe2\x8f\x9c\xe2\x8f\x9d\xe2\x8f\x9e\z
\xe2\x8f\x9f\xe2\x8f\xa0\xe2\x8f\xa1\xe2\x9d\x9b\xe2\x9d\x9c\xe2\x9d\x9d\xe2\x9d\x9e\xe2\x9d\x9f\xe2\x9d\xa0\xe2\x9d\xa1\xe2\x9d\xa2\z
\xe2\x9d\xa3\xe2\x9d\xa4\xe2\x9d\xa5\xe2\x9d\xa8\xe2\x9d\xa9\xe2\x9d\xaa\xe2\x9d\xab\xe2\x9d\xac\xe2\x9d\xad\xe2\x9d\xae\xe2\x9d\xaf\z
\xe2\x9d\xb0\xe2\x9d\xb1\xe2\x9d\xb2\xe2\x9d\xb3\xe2\x9d\xb4\xe2\x9d\xb5\xe2\x9f\x85\xe2\x9f\x86\xe2\x9f\xa6\xe2\x9f\xa7\xe2\x9f\xa8\z
\xe2\x9f\xa9\xe2\x9f\xaa\xe2\x9f\xab\xe2\x9f\xac\xe2\x9f\xad\xe2\x9f\xae\xe2\x9f\xaf\xe2\xa6\x83\xe2\xa6\x84\xe2\xa6\x85\xe2\xa6\x86\z
\xe2\xa6\x87\xe2\xa6\x88\xe2\xa6\x89\xe2\xa6\x8a\xe2\xa6\x8b\xe2\xa6\x8c\xe2\xa6\x8d\xe2\xa6\x8e\xe2\xa6\x8f\xe2\xa6\x90\xe2\xa6\x91\z
\xe2\xa6\x92\xe2\xa6\x93\xe2\xa6\x94\xe2\xa6\x95\xe2\xa6\x96\xe2\xa6\x97\xe2\xa6\x98\xe2\xa7\xbc\xe2\xa7\xbd\xe2\xb3\xb9\xe2\xb3\xba\z
\xe2\xb3\xbb\xe2\xb3\xbc\xe2\xb3\xbe\xe2\xb3\xbf\xe2\xb5\xb0\xe2\xb8\x80\xe2\xb8\x81\xe2\xb8\x82\xe2\xb8\x83\xe2\xb8\x84\xe2\xb8\x85\z
\xe2\xb8\x86\xe2\xb8\x87\xe2\xb8\x88\xe2\xb8\x89\xe2\xb8\x8a\xe2\xb8\x8b\xe2\xb8\x8c\xe2\xb8\x8d\xe2\xb8\x8e\xe2\xb8\x8f\xe2\xb8\x90\z
\xe2\xb8\x91\xe2\xb8\x92\xe2\xb8\x93\xe2\xb8\x94\xe2\xb8\x95\xe2\xb8\x96\xe2\xb8\x98\xe2\xb8\x99\xe2\xb8\x9a\xe2\xb8\x9b\xe2\xb8\x9c\z
\xe2\xb8\x9d\xe2\xb8\x9e\xe2\xb8\x9f\xe2\xb8\xa0\xe2\xb8\xa1\xe2\xb8\xa2\xe2\xb8\xa3\xe2\xb8\xa4\xe2\xb8\xa5\xe2\xb8\xa6\xe2\xb8\xa7\z
\xe2\xb8\xa8\xe2\xb8\xa9\xe2\xb8\xaa\xe2\xb8\xab\xe2\xb8\xac\xe2\xb8\xad\xe2\xb8\xae\xe2\xb8\xaf\xe2\xb8\xb0\xe2\xb8\xb1\xe2\xb8\xb2\z
\xe2\xb8\xb3\xe2\xb8\xb4\xe2\xb8\xb5\xe2\xb8\xb6\xe2\xb8\xb7\xe2\xb8\xb8\xe2\xb8\xb9\xe2\xb8\xba\xe2\xb8\xbb\xe2\xb8\xbc\xe2\xb8\xbd\z
\xe2\xb8\xbe\xe2\xb8\xbf\xe2\xb9\x81\xe2\xb9\x82\xe2\xb9\x83\xe2\xb9\x84\xe2\xb9\x85\xe2\xb9\x86\xe2\xb9\x87\xe2\xb9\x88\xe2\xb9\x89\z
\xe2\xb9\x8a\xe2\xb9\x8b\xe2\xb9\x8c\xe2\xb9\x8d\xe2\xb9\x8e\xe3\x80\x80\xe3\x80\x81\xe3\x80\x82\xe3\x80\x83\xe3\x80\x84\xe3\x80\x85\z
\xe3\x80\x86\xe3\x80\x87\xe3\x80\x88\xe3\x80\x89\xe3\x80\x8a\xe3\x80\x8b\xe3\x80\x8c\xe3\x80\x8d\xe3\x80\x8e\xe3\x80\x8f\xe3\x80\x90\z
\xe3\x80\x91\xe3\x80\x94\xe3\x80\x95\xe3\x80\x96\xe3\x80\x97\xe3\x80\x98\xe3\x80\x99\xe3\x80\x9a\xe3\x80\x9b\xe3\x80\x9c\xe3\x80\x9d\z
\xe3\x80\x9e\xe3\x80\x9f\xe3\x80\xb0\xe3\x80\xb1\xe3\x80\xb2\xe3\x80\xb3\xe3\x80\xb4\xe3\x80\xb5\xe3\x80\xbb\xe3\x80\xbc\xe3\x80\xbd\z
\xe3\x82\xa0\xea\x93\xbe\xea\x93\xbf\xea\x98\x8d\xea\x98\x8e\xea\x98\x8f\xea\x99\xb3\xea\x99\xbe\xea\x9b\xb2\xea\x9b\xb3\xea\x9b\xb4\z
\xea\x9b\xb5\xea\x9b\xb6\xea\x9b\xb7\xea\xa1\xb6\xea\xa1\xb7\xea\xa3\x8e\xea\xa3\x8f\xea\xa3\xb8\xea\xa3\xb9\xea\xa3\xba\xea\xa3\xbb\z
\xea\xa4\xae\xea\xa4\xaf\xea\xa5\x9f\xea\xa7\x81\xea\xa7\x82\xea\xa7\x83\xea\xa7\x84\xea\xa7\x85\xea\xa7\x86\xea\xa7\x87\xea\xa7\x88\z
\xea\xa7\x89\xea\xa7\x8a\xea\xa7\x8b\xea\xa7\x8c\xea\xa7\x8d\xea\xa9\x9c\xea\xa9\x9d\xea\xa9\x9e\xea\xa9\x9f\xea\xab\x9e\xea\xab\x9f\z
\xea\xab\xb0\xea\xab\xb1\xea\xaf\xab\xea\xaf\xac\xea\xaf\xad\xef\xb4\xbe\xef\xb4\xbf\xef\xbd\x9f\xef\xbd\xa0\xef\xbd\xa1\xef\xbd\xa2\z
\xef\xbd\xa3\xef\xbd\xa4\xf0\x90\x84\x80\xf0\x90\x84\x81\xf0\x90\x84\x82\xf0\x90\x8e\x9f\xf0\x90\x8f\x90\xf0\x90\x95\xaf\z
\xf0\x90\xa1\x97\xf0\x90\xa4\x9f\xf0\x90\xa4\xbf\xf0\x90\xa9\x90\xf0\x90\xa9\x91\xf0\x90\xa9\x92\xf0\x90\xa9\x93\xf0\x90\xa9\x94\z
\xf0\x90\xa9\x95\xf0\x90\xa9\x96\xf0\x90\xa9\x97\xf0\x90\xa9\x98\xf0\x90\xab\xb0\xf0\x90\xab\xb1\xf0\x90\xab\xb2\xf0\x90\xab\xb3\z
\xf0\x90\xab\xb4\xf0\x90\xab\xb5\xf0\x90\xab\xb6\xf0\x90\xac\xb9\xf0\x90\xac\xba\xf0\x90\xac\xbb\xf0\x90\xac\xbc\xf0\x90\xac\xbd\z
\xf0\x90\xac\xbe\xf0\x90\xac\xbf\xf0\x90\xae\x99\xf0\x90\xae\x9a\xf0\x90\xae\x9b\xf0\x90\xae\x9c\xf0\x90\xbd\x95\xf0\x90\xbd\x96\z
\xf0\x90\xbd\x97\xf0\x90\xbd\x98\xf0\x90\xbd\x99\xf0\x91\x81\x87\xf0\x91\x81\x88\xf0\x91\x81\x89\xf0\x91\x81\x8a\xf0\x91\x81\x8b\z
\xf0\x91\x81\x8c\xf0\x91\x81\x8d\xf0\x91\x82\xbe\xf0\x91\x82\xbf\xf0\x91\x83\x80\xf0\x91\x83\x81\xf0\x91\x85\x80\xf0\x91\x85\x81\z
\xf0\x91\x85\x82\xf0\x91\x85\x83\xf0\x91\x85\xb4\xf0\x91\x85\xb5\xf0\x91\x87\x85\xf0\x91\x87\x86\xf0\x91\x87\x87\xf0\x91\x87\x88\z
\xf0\x91\x87\x8d\xf0\x91\x87\x9a\xf0\x91\x87\x9b\xf0\x91\x87\x9c\xf0\x91\x87\x9d\xf0\x91\x88\xb8\xf0\x91\x88\xb9\xf0\x91\x88\xba\z
\xf0\x91\x88\xbb\xf0\x91\x88\xbc\xf0\x91\x88\xbd\xf0\x91\x8a\xa9\xf0\x91\x91\x8b\xf0\x91\x91\x8c\xf0\x91\x91\x8d\xf0\x91\x91\x8e\z
\xf0\x91\x91\x8f\xf0\x91\x97\x82\xf0\x91\x97\x83\xf0\x91\x97\x84\xf0\x91\x97\x85\xf0\x91\x99\x81\xf0\x91\x99\x82\xf0\x91\x99\x83\z
\xf0\x91\x99\xa0\xf0\x91\x99\xa1\xf0\x91\x99\xa2\xf0\x91\x99\xa3\xf0\x91\x99\xa4\xf0\x91\x99\xa5\xf0\x91\x99\xa6\xf0\x91\x99\xa7\z
\xf0\x91\x99\xa8\xf0\x91\x99\xa9\xf0\x91\x99\xaa\xf0\x91\x99\xab\xf0\x91\x99\xac\xf0\x91\x9c\xbc\xf0\x91\x9c\xbd\xf0\x91\x9c\xbe\z
\xf0\x91\x9c\xbf\xf0\x91\xa0\xbb\xf0\x91\xa9\x81\xf0\x91\xa9\x82\xf0\x91\xa9\x83\xf0\x91\xa9\x84\xf0\x91\xaa\x9a\xf0\x91\xaa\x9b\z
\xf0\x91\xaa\x9c\xf0\x91\xb1\x81\xf0\x91\xb1\x82\xf0\x91\xb1\x83\xf0\x91\xb1\xb0\xf0\x91\xb1\xb1\xf0\x91\xbb\xb7\xf0\x91\xbb\xb8\z
\xf0\x92\x91\xb0\xf0\x92\x91\xb1\xf0\x92\x91\xb2\xf0\x92\x91\xb3\xf0\x92\x91\xb4\xf0\x96\xa9\xae\xf0\x96\xa9\xaf\xf0\x96\xab\xb5\z
\xf0\x96\xac\xb7\xf0\x96\xac\xb8\xf0\x96\xac\xb9\xf0\x96\xac\xba\xf0\x96\xac\xbb\xf0\x96\xad\x84\xf0\x96\xad\x85\xf0\x96\xba\x97\z
\xf0\x96\xba\x98\xf0\x9b\xb2\x9f\xf0\x9d\x84\x94\xf0\x9d\x84\x95\xf0\x9d\xaa\x87\xf0\x9d\xaa\x88\xf0\x9d\xaa\x89\xf0\x9d\xaa\x8a\z
\xf0\x9d\xaa\x8b\xf0\x9e\xa5\x9e\xf0\x9e\xa5\x9f\xf0\x9f\x84\xaa\xf0\x9f\x89\x80\xf0\x9f\x89\x81\xf0\x9f\x89\x82\xf0\x9f\x89\x83\z
\xf0\x9f\x89\x84\xf0\x9f\x89\x85\xf0\x9f\x89\x86\xf0\x9f\x89\x87\xf0\x9f\x89\x88\xf0\x9f\x99\xb6\xf0\x9f\x99\xb7\xf0\x9f\x99\xb8\z
\xf0\x9f\x99\xb9\xf0\x9f\x99\xba\xf0\x9f\x99\xbb\xf0\x9f\x99\xbc\xf0\x9f\x99\xbd"

-- ----------------------------------------------------------------------------
-- list of hex values that are Unicode code-points labelled as punctuation
-- each punctuation character can span from [1..4]
-- values are in order from lowest to highest, which speeds up lookup
--
-- Note: values will be read from file, so there'll be a performance penalty
--       at the very first time of use
--
local sUniPunct		= sUnicodePunct
local sUniPunctFile = ".\\unipunct.lua"

local function LoadPunctuation(inFilename)
	
	-- list already in memory
	--
	if sUniPunct then return sUniPunct end
	
	local fhSrc = io.open(sUniPunctFile, "r")
	if not fhSrc then return nil end
	fhSrc:close()
	
	sUniPunct = dofile(sUniPunctFile)
	
	return sUniPunct
end

-- ----------------------------------------------------------------------------
-- boolean test if a given byte sequence is an Unicode punctuation character
--
local function str_ispunct_u(inUniChar)
	
	-- get the Unicode's punctuation list
	--
	local lsReject = sUniPunct 
	if not lsReject then lsReject = LoadPunctuation() end
	
	-- sanity check
	--
	if not lsReject or not inUniChar then return false end

	local iUniLen = inUniChar:len()
	if 0 == iUniLen then return false end
	
	-- get the selector and the required length
	--
	local chUniMark = inUniChar:byte(1, 1)
	local iUniReq
	
	-- don't care about a selector with invalid values
	-- because the test routine will just fail over
	--
	if		0x80 > chUniMark then iUniReq = 1
	elseif 	0xe0 > chUniMark then iUniReq = 2
	elseif 	0xf0 > chUniMark then iUniReq = 3
	else 						  iUniReq = 4 end		
	
	-- requested length does not match with the input char
	--
	if iUniReq ~= iUniLen then return false end
	
	-- test against list
	--
	local chTestMark
	local iTestReq
	local iOffset = 1
	local iLimit  = lsReject:len() - 4 + 1			-- 4 is the highset known value
	
	while iOffset < iLimit do
	 	
		-- fisrt byte of UTF_8 sequence
		--
		chTestMark = lsReject:byte(iOffset, iOffset)
	 	
		-- test the sequence after the mark byte
		--
		if chTestMark == chUniMark then
			
			-- quick shot, saves a loop
			--
			if 1 == iUniReq then return true
			
			else
				-- test each of the following bytes [2..4]
				--
				local iRun = 1
				
				while iUniReq > iRun do
					
					-- fail test
					--
					if 	lsReject:byte(iOffset + iRun, iOffset + iRun) ~= 
						inUniChar:byte(1 + iRun, 1 + iRun) then break end

					iRun = iRun + 1
				end

				-- character sequences match
				--
				if iUniReq == iRun then return true end
			end
		end
		
		-- we passed over the limit
		--
		if chTestMark > chUniMark then return false end		
		
		-- length of test character in UTF_8 punctuation list
		--
		if		0x80 > chTestMark then iTestReq = 1
		elseif 	0xe0 > chTestMark then iTestReq = 2
		elseif 	0xf0 > chTestMark then iTestReq = 3 
		else 						   iTestReq = 4 end	
		
		-- skip and get next test
		--
		iOffset = iOffset + iTestReq
	end

	return false
end

-- ----------------------------------------------------------------------------
-- boolean test if a given byte value is an ASCII punctuation character
--
local function str_ispunct_a(inByte)
	
	local lsReject = " \t\n\r:.;,°`\'\"<>()[]{}~!?@#£$§%^&*-_+=|\\/"
	local iLength  = #lsReject
	
	for iOffset = 1, iLength do
		if inByte == lsReject:sub(iOffset, iOffset) then return true end
	end

	return false
end

-- ----------------------------------------------------------------------------
-- extract an entire alpha-word (with punctuation) from a buffer
-- stops start and end at puctuation characters
--
local function str_wordsub(inBytes, inPosition)

	-- sanity check
	--
	if not inBytes then return nil end
	
	local iLength = inBytes:len()
	if 1 > inPosition or inPosition > iLength then return nil end

	-- get the first punctuation character before beginning of word
	--
	local ch

	local iStart = inPosition
	while 0 < iStart do

		ch = inBytes:sub(iStart, iStart)
		if str_ispunct_a(ch) then break end

		iStart = iStart - 1
	end

	-- get first space character after end of word
	--
	local iEnd = inPosition
	while iEnd <= iLength do

		ch = inBytes:sub(iEnd, iEnd)
		if str_ispunct_a(ch) then break end

		iEnd = iEnd + 1
	end

	-- extract word from entire line
	--
	return inBytes:sub(iStart + 1, iEnd - 1)
end

-- ----------------------------------------------------------------------------
-- auxiliary function to cleanup extra characters at the end of the buffer
-- remove all characters with binary value below 0x20, except 0x0a and 0x0d
-- this function will process bytes up to the first [cr or lf] or end of buffer
-- thus will fail if the input buffer is a multiline
-- return the number of bytes removed and the cleaned buffer
--
local function str_endwipe(inBuffer)

	local iLength = inBuffer:len()
	local iLast   = 0
	local sReturn = ""
	local sAppend = ""
	local iCurr

	if 0 == iLength then return 0, inBuffer end

	-- scan for \n (and eventual \r)
	--
	for i=1, iLength do

		iCurr = inBuffer:byte(i)

		if     0x20  < iCurr then iLast   = i
		elseif 0x0a == iCurr then sAppend = "\n"   break
		elseif 0x0d == iCurr then sAppend = "\r\n" break
		end
	end

	sReturn = _format("%s%s", inBuffer:sub(1, iLast), sAppend )

	return (iLength - sReturn:len()), sReturn
end

-- ----------------------------------------------------------------------------
-- install in the string library
--
if not string.gcount   then string.gcount  = str_gcount		end
if not string.ltrim    then string.ltrim   = str_ltrim		end
if not string.rtrim    then string.rtrim   = str_rtrim		end
if not string.trim     then string.trim    = str_trim		end
if not string.endwipe  then string.endwipe = str_endwipe	end
if not string.cap1st   then string.cap1st  = str_cap1st		end
if not string.fmtfind  then string.fmtfind = str_fmtfind	end
if not string.wordsub  then string.wordsub = str_wordsub	end
if not string.fmtkilo  then string.fmtkilo = str_fmtkilo	end
if not string.a_punct  then string.a_punct = str_ispunct_a	end

if not string.utf8lkp  then string.utf8lkp = str_lkp_utf_8	end
if not string.utf8sub  then string.utf8sub = str_sub_utf_8	end
if not string.utf8len  then string.utf8len = str_len_utf_8	end
if not string.u_punct  then string.u_punct = str_ispunct_u	end
if not string.i_Uchar  then string.i_Uchar = str_iter_utf_8_char end

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
