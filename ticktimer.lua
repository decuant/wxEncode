-- ----------------------------------------------------------------------------
--
--  TickTimer
-- 
-- counts the time elapsed between a start time and time now
-- the accurancy of this timer object relies on the frequency
-- its methods are called
-- ----------------------------------------------------------------------------

local TickTimer = { }

TickTimer.__index = TickTimer

local _clock = os.clock

-- ----------------------------------------------------------------------------
--
function TickTimer.new(inName)

	inName = inName or "ANY"
	
	local t = 
	{
		m_Name		= inName,	-- a name for the object
		m_NextTick	= 0,		-- next time to fire
		m_TickFrame	= 0,		-- firing delay
		m_Enabled	= false,	-- timer is actually enabled
	}

	return setmetatable(t, TickTimer)
end

-- ----------------------------------------------------------------------------
--
function TickTimer.Setup(self, inInterval, inEnabled)
	
	self.m_Enabled	 = inEnabled
	self.m_TickFrame = inInterval * 1
	self.m_NextTick  = _clock() + self.m_TickFrame
end

-- ----------------------------------------------------------------------------
--
function TickTimer.Reset(self)
	
	self.m_NextTick = _clock() + self.m_TickFrame
end

-- ----------------------------------------------------------------------------
--
function TickTimer.Enable(self, inEnable)
	
	self.m_Enabled = inEnable
end

-- ----------------------------------------------------------------------------
--
function TickTimer.IsEnabled(self)
	
	return self.m_Enabled
end

-- ----------------------------------------------------------------------------
--
function TickTimer.HasFired(self)
	
	if self.m_Enabled then return _clock( ) > self.m_NextTick end
	
	-- timer is disabled
	--
	return false
end

-- ----------------------------------------------------------------------------
--
function TickTimer.ElapsedTime(self)

	return self.m_NextTick - _clock()
end

-- ----------------------------------------------------------------------------
--
function TickTimer.ShowInterval(self)

	local iEnabled = 0
	if  self.m_Enabled then iEnabled = 1 end
	
	local sText = string.format("[%s] enable: [%d] elapsed: [%.4f]", 
								self.m_Name, iEnabled, self:ElapsedTime())
	return sText
end
	
-- ----------------------------------------------------------------------------
--
return TickTimer

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
