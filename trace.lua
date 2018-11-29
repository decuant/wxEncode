-- ----------------------------------------------------------------------------
--
--  Trace
--
-- ----------------------------------------------------------------------------

local Trace = Trace or {}

local _write	= io.write
local _flush	= io.flush
local _format	= string.format
local _concat	= table.concat
local _clock	= os.clock

local mLineCounter	= 0
local mTickStart	= _clock()
local mTickTimed	= _clock()

-- ----------------------------------------------------------------------------
--
function Trace.msg(inMessage)
	if not inMessage then return end
	
	mLineCounter = mLineCounter + 1
	
	_write(_format("%05d: ", mLineCounter))
	_write(inMessage)
end

-- ----------------------------------------------------------------------------
--
function Trace.cat(inMessage)
	if not inMessage then return end
	
	_write(inMessage)
end

-- ----------------------------------------------------------------------------
--
function Trace.numArray(inTable, inLabel)

	local tStrings = {inLabel or ""}

	for iIndex, number in ipairs(inTable) do
		tStrings[iIndex + 1] = _format("%.04f", number)
	end

	Trace.line(_concat(tStrings, " ")) 	
end

-- ----------------------------------------------------------------------------
--
function Trace.line(inMessage)
	if not inMessage then return end
		
	Trace.msg(inMessage)
	_write("\n")
	_flush()	
end

-- ----------------------------------------------------------------------------
--
function Trace.lnTimeStart(inMessage)
	if inMessage then Trace.line(inMessage) end
	
	mTickStart = _clock()
end

-- ----------------------------------------------------------------------------
--
function Trace.lnTimeEnd(inMessage)
	
	mTickTimed = _clock()

	inMessage = inMessage or "Stopwatch at"

	Trace.line(_format("%s (%.04f s.)", inMessage, (mTickTimed - mTickStart)))
	
	mTickStart = mTickTimed
end

-- ----------------------------------------------------------------------------
--
return Trace

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
