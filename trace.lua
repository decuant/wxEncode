-- ----------------------------------------------------------------------------
--
--  Trace
--
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--
module(..., package.seeall)

local Trace = Trace or {}
local _wrt  = io.write
local _flush=io.flush
local _fmt	= string.format
local _cat	= table.concat
local _clk	= os.clock

local mLineCounter	= 0
local mTickStart		= _clk()
local mTickTimed		= _clk()

-- ----------------------------------------------------------------------------
--
function Trace.msg(inMessage)
	if not inMessage then return end
	
	mLineCounter = mLineCounter + 1
	
	_wrt(_fmt("%05d: ", mLineCounter))
	_wrt(inMessage)
end

-- ----------------------------------------------------------------------------
--
function Trace.append(inMessage)
	if not inMessage then return end
	
	_wrt(inMessage)
end

-- ----------------------------------------------------------------------------
--
function Trace.numArray(inTable, inLabel)

	local tStrings = {inLabel or ""}

	for iIndex, number in ipairs(inTable) do
		tStrings[iIndex + 1] = _fmt("%.04f", number)
	end

	Trace.line(_cat(tStrings, " ")) 	
end

-- ----------------------------------------------------------------------------
--
function Trace.line(inMessage)
	if not inMessage then return end
		
	Trace.msg(inMessage)
	_wrt("\n")
	_flush()	
end

-- ----------------------------------------------------------------------------
--
function Trace.lnTimeStart(inMessage)
	if inMessage then Trace.line(inMessage) end
	
	mTickStart = _clk()
end

-- ----------------------------------------------------------------------------
--
function Trace.lnTimeEnd(inMessage)
	
	mTickTimed = _clk()

	inMessage = inMessage or "Stopwatch at"
	local sText = _fmt("%s - %.03f secs\n", inMessage, (mTickTimed - mTickStart))
	Trace.msg(sText)
	_flush()
	
	mTickStart = mTickTimed
end

--------------------------------------------------------------------------------
-- dump a buffer
--
function Trace.dump(_title, buf)
  
  local blockText = "---- [" .. _title .. "] ----\n"  
  _wrt(blockText)

  for byte=1, #buf, 16 do
     local chunk = buf:sub(byte, byte + 15)

     _wrt(string.format('%08X  ', byte - 1))

     chunk:gsub('.', function (c) io.write(string.format('%02X ', string.byte(c))) end)
     _wrt(string.rep(' ', 3 * (16 - #chunk)))
     _wrt(' ', chunk:gsub('%c','.'), "\n") 
  end

  _wrt(blockText)
  io.flush()  
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
