-- ----------------------------------------------------------------------------
--  
--  some bit manipulators
-- 
-- ----------------------------------------------------------------------------

local bit = function(p)
	
	return 2 ^ (p - 1)  -- 1-based indexing
end

-- ----------------------------------------------------------------------------
-- Typical call:  if hasbit(x, bit(3)) then ...
--
local hasbit = function(x, p)
	
	return x % (p + p) >= p       
end

-- ----------------------------------------------------------------------------
--
--
local setbit = function(x, p)
	
	return hasbit(x, p) and x or x + p
end

-- ----------------------------------------------------------------------------
--
--
local clearbit = function(x, p)
	
	return hasbit(x, p) and x - p or x
end

-- ----------------------------------------------------------------------------
-- print(bitoper(6,3,OR))   --> 7
-- print(bitoper(6,3,XOR))  --> 5
-- print(bitoper(6,3,AND))  --> 2
--
local OR, XOR, AND = 1, 3, 4

local bitoper = function(a, b, oper)

	local r, m, s = 0, 2^52

	repeat
		
		s, a, b	= a + b + m, a % m, b % m
		r, m		= r + m * oper % (s - a - b), m / 2
		
	until m < 1

	return r
end

-- ----------------------------------------------------------------------------
-- make functions accesible as fields of the require call
--
return {
	bit      = bit,
	hasbit   = hasbit,
	setbit   = setbit,
	clearbit = clearbit,

	bitoper  = bitoper,
	OR       = OR,
	XOR      = XOR,
	AND      = AND
}

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
