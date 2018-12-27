-- ----------------------------------------------------------------------------
--
--  translate - translator from old codepages to UTF_8
--
-- ----------------------------------------------------------------------------

package.path = package.path .. ";?.lua;"

local trace	= require "trace"		-- tracing
local winCP = require "cp_win"		-- Windows' codepages
local isoCP = require "cp_iso"		-- ISO's codepages
local oemCP = require "cp_oem"		-- OEM's codepages
			  
local _format	= string.format
local _char		= string.char
local _strrep	= string.rep
local _concat	= table.concat
local _floor	= math.floor

-- ----------------------------------------------------------------------------
--
local m_cpLast	 = nil		-- last cached codepage
local m_cache	 = nil

-- ----------------------------------------------------------------------------
-- get a table of Unicode values and make a new table of UTF_8 values
-- result is in the m_cache
-- note that the input codepage is made of natural numbers
-- whilst the m_cache table is filled with strings
--
local function _compileUtf8(inCodepage)
	
	if not inCodepage then return end
	if inCodepage == m_cpLast then return end
	
	m_cpLast = inCodepage								-- flag codepage
	m_cache  = { }
	
	local iValue										-- original
	local iHigh, iLow									-- 2 * 8 bits
	local tNibbles = {0x00, 0x00, 0x00, 0x00}			-- 4 nibbles
	local iByte1, iByte2, iByte3						-- UTF_8
	local sValue
	
	for i=1, #inCodepage do
		
		iValue = inCodepage[i]
		if not iValue then iValue = 0xfffd end			-- special (err)
		
		iHigh = _floor(iValue / 0x100)					-- split in 2
		iLow  = (iValue % 0x100)
		
		tNibbles[1] = _floor(iHigh / 0x10)				-- split in halves
		tNibbles[2] = (iHigh % 0x10)
		tNibbles[3] = _floor(iLow / 0x10)
		tNibbles[4] = (iLow % 0x10)
		
		if 0x07d0 > iValue then
			
			-- c2-df block (2 bytes)
			------------------------
			
			iByte2 = 0x80 + (tNibbles[4] % 0x10)		+ 0x10 * (tNibbles[3] % 0x04)
			iByte1 = 0xc0 + _floor(tNibbles[3] / 0x04)	+ 0x04 * (tNibbles[2] % 0x08)
			
			sValue = _format("%c%c", iByte1, iByte2)
			
		else
			
			-- e0-ef block (3 bytes)
			------------------------
			
			iByte3 = 0x80 + (tNibbles[4] % 0x10)		+ 0x10 * (tNibbles[3] % 0x04)
			iByte2 = 0x80 + _floor(tNibbles[3] / 0x04)	+ 0x04 * (tNibbles[2] % 0x10)
			iByte1 = 0xe0 + tNibbles[1]
			
			sValue = _format("%c%c%c", iByte1, iByte2, iByte3)			
		end
		
		m_cache[#m_cache + 1] = sValue
	end
end

-- ----------------------------------------------------------------------------
--
local function EnumAllCodepages()

	local sSep = "-- " .. _strrep("-", 30)
	local sFmt = "%d - %s"
	
	trace.line(sSep)
	trace.line("-- OEM")

	local t_OEM_CPList = oemCP.Enum()
	
	for _, iRow in ipairs(t_OEM_CPList) do
		trace.line(_format(sFmt, iRow[1], iRow[2]))
	end

	trace.line(sSep)
	trace.line("-- ISO")

	local t_ISO_CPList = isoCP.Enum()
	
	for _, iRow in ipairs(t_ISO_CPList) do
		trace.line(_format(sFmt, iRow[1], iRow[2]))
	end
	
	trace.line(sSep)
	trace.line("-- Windows")

	local t_WIN_CPList = winCP.Enum()
	
	for _, iRow in ipairs(t_WIN_CPList) do
		trace.line(_format(sFmt, iRow[1], iRow[2]))
	end
	
	trace.line(sSep)
end

-- ----------------------------------------------------------------------------
-- get a codepage table definition
-- {name, id}
-- return the translation table or nil
--
local function GetCodepage(inCodepage)
	
	local codepage = nil
	
	if "Windows" == inCodepage[1] then
		
		codepage = winCP.Table(inCodepage[2])
		
	elseif "ISO" == inCodepage[1] then
		
		codepage = isoCP.Table(inCodepage[2])
		
	elseif "OEM" == inCodepage[1] then
		
		codepage = oemCP.Table(inCodepage[2])
	end
	
	return codepage
end

-- ----------------------------------------------------------------------------
-- given a buffer and a codepage reference will translate
-- all characters to Unicode coded UTF_8
-- return the transcoded buffer
--
local function Processor_UTF8(inBuffer, inCodepage)
	
	-- check for a valid codepage
	--
	if not inCodepage then return nil end

	-- compile from Unicode to UTF_8 the codepage table used for conversion
	-- if the table has been previously processed it won't do anything
	-- after this the reference table is in m_cache
	--
	_compileUtf8(inCodepage)
	
	local iHighest  = 0xff - #m_cache
	local iLimit	= inBuffer:len()
	local outBuffer = { }
	local inValue

	for i=1, iLimit do
		
		inValue	= inBuffer:byte(i)
		
		if iHighest > inValue then			
			outBuffer[#outBuffer + 1] = _char(inValue)
		else
			outBuffer[#outBuffer + 1] = m_cache[inValue - iHighest]
		end
	end
	
	return _concat(outBuffer, nil)
end

-- ----------------------------------------------------------------------------
--
return 
{
	AvailCodepages	= EnumAllCodepages,
	Codepage		= GetCodepage,
	Processor		= Processor_UTF8,
}

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
