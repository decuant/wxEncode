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
function Trace.append(inMessage)
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

--------------------------------------------------------------------------------
-- dump a buffer
--
function Trace.dump(_title, buf)
  
	local blockText = "---- [" .. _title .. "] ----\n"  
	_write(blockText)

	for iIndex=1, #buf, 16 do
		
		local chunk = buf:sub(iIndex, iIndex + 15)

		_write(_format('%08X  ', iIndex - 1))

		chunk:gsub('.', function (c) _write(_format('%02X ', string.byte(c))) end)
		_write(string.rep(' ', 3 * (16 - #chunk)))
		_write(' ', chunk:gsub('%c','.'), "\n") 
	end

	_write(blockText)
	_flush()  
	
end

-- ----------------------------------------------------------------------------
--  print a table in memory
--
function Trace.table(t)
  
  local print_r_cache = {}
  
  local function sub_print_r(t, indent)
    
    if (print_r_cache[tostring(t)]) then
      
      print(indent.."*"..tostring(t))
      
    else
      
      print_r_cache[tostring(t)] = true
      
      if (type(t)=="table") then
        for pos,val in pairs(t) do
          if (type(val)=="table") then
            print(indent.."["..pos.."] => "..tostring(t).." {")
            sub_print_r(val,indent..string.rep(" ",string.len(pos)+4))
            print(indent..string.rep(" ",string.len(pos)+2).."}")
          elseif (type(val)=="string") then
            print(indent.."["..pos..'] => "'..val..'"')
          else
            print(indent.."["..pos.."] => "..tostring(val))
          end
        end
      else
        print(indent..tostring(t))
      end
    end
  end
  
  if (type(t)=="table") then
    print(tostring(t).." {")
    sub_print_r(t,"  ")
    print("}")
  else
    sub_print_r(t,"  ")
  end
  
  print()
  _flush()
  
end

-- ----------------------------------------------------------------------------
--
return Trace

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
