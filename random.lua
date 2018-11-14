--[[
* routine for a very-long-cycle random-number sequences
*
*	this random number generator was proved to generate random sequences
*	between 0 to 1 which if 100 numbers were calculated every second, it
*	would NOT repeat itself for over 220 years.
*
*	reference:
*
*	Wichmann B.A. and I.D. Hill. "Building A Random Number Generator."
*	Byte Magazine. March 1987. pp.127.
]]

-------------------------------------------------------------------------------
--
module(..., package.seeall)

local Random  = Random or {}
local _floor	= math.floor

-------------------------------------------------------------------------------
--	default seed values
--
local _x 		= 1
local	_y 		= 10000
local	_z 		= 3000
local _last 	= 0

local INT_MAX	= 0x7fffffff

-------------------------------------------------------------------------------
--	seed generator
--
local function seedStart()
	
	_x = os.time() % INT_MAX
	_y = (_x ^ 2)  % INT_MAX
	_z = (_y ^ 2)  % INT_MAX
end

-------------------------------------------------------------------------------
--	shortcut for seed start and first cycle run
--
function Random.initialize()
	
	seedStart()
	
	-- load a proper value into _last
	--
	Random.get()
end

-------------------------------------------------------------------------------
-- return the _last computed value
--
function Random.last()
	
	return _last
end

-------------------------------------------------------------------------------
-- produce a new value and store it in _last
--
function Random.get()
	
	_x = 171 * (_x % 177) - 2 * (_x / 177)
	if 0 > _x then _x = _x + 30269 end
	
	_y = 172 * (_y % 176) - 35 * (_y / 176)
	if 0 > _y then _y = _y + 30307 end

	_z = 170 * (_z % 178) - 63 * (_z / 178)
	if 0 > _z then _z = _z + 30323 end
		
	_last = _x / 30269.0 + _y / 30307.0 + _z / 30323.0	
	
	-- remove the integral part
	--
	_last = _last - _floor(_last)
	
	return _last
end

-------------------------------------------------------------------------------
-- produce a new value inside the given interval
--
function Random.getInRange(inMinimum, inMaximum)
	
	_last = ((inMaximum - inMinimum) * Random.get()) + inMinimum
	
	return _last
end

-------------------------------------------------------------------------------
--
return Random

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
