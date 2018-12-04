-- ----------------------------------------------------------------------------
--
--  Magnify - window for displaying a single char
--
-- ----------------------------------------------------------------------------

local wx 		= require "wx"			-- uses wxWidgets for Lua 5.2
local palette	= require "palette"		-- common Colours definition in wxWidgets
local bits  	= require "bits"		-- bit manipulators
-- local trace 	= require "trace"		-- shortcut for tracing

local _floor	= math.floor
local _format	= string.format

-- ----------------------------------------------------------------------------
-- window's bag
--
local m_Frame = 
{
	hWindow   = nil,	-- main frame
	bVisible  = false,	-- last visibile status
	hMemoryDC = nil,	-- device context for the window
	fnDraw    = nil,	-- font big size
	fnText	  = nil, 	-- font for details
	sData	  = " ",	-- current character
	
	rcClientW = 0,
	rcClientH = 0,
}

-- ----------------------------------------------------------------------------
-- preallocated GDI objects
--
local penNULL = wx.wxPen(palette.Black, 0, wx.wxTRANSPARENT)
local brBack  = wx.wxBrush(palette.Gray15, wx.wxSOLID)	

local penRect = wx.wxPen(palette.Bisque, 2, wx.wxDOT)
local brNULL  = wx.wxBrush(palette.White, wx.wxTRANSPARENT)

-- ----------------------------------------------------------------------------
-- flags in use for the frame
--
local dwMainFlags = bits.bitoper(wx.wxFRAME_TOOL_WINDOW, wx.wxCAPTION,    bits.OR)
	  dwMainFlags = bits.bitoper(dwMainFlags, wx.wxRESIZE_BORDER,         bits.OR)
	  dwMainFlags = bits.bitoper(dwMainFlags, wx.wxFRAME_FLOAT_ON_PARENT, bits.OR)

-- ----------------------------------------------------------------------------
--
local function DrawChar(inDrawDC) 
--	trace.line("DrawChar")

	if not m_Frame.fnDraw then return end

	-- get the char extent
	--
	inDrawDC:SetFont(m_Frame.fnDraw)
		
	local chCurrent = m_Frame.sData
	local iSpacerX  = inDrawDC:GetTextExtent(chCurrent)
	local iSpacerY  = inDrawDC:GetCharHeight()
	
	-- align the character to the middle of the client area
	--
	local iLeft = _floor((m_Frame.rcClientW - iSpacerX) / 2)
	local iTop  = _floor((m_Frame.rcClientH - iSpacerY) / 2)
	
	if 0 > iLeft then iLeft = 0 end
	if 0 > iTop  then iTop  = 0 end
	
	-- actual char
	--
	inDrawDC:SetTextForeground(palette.White)
	inDrawDC:DrawText(chCurrent, iLeft, iTop)
	
	-- draw a shallow bounding box for the char
	--
	inDrawDC:SetPen(penRect)
	inDrawDC:SetBrush(brNULL)
	
	inDrawDC:DrawRectangle(iLeft, iTop, iSpacerX, iSpacerY)
	
	-- draw the details
	--
--	inDrawDC:SetFont(m_Frame.fnText)
--	inDrawDC:SetTextForeground(palette.Bisque)
	
--	local sToDraw = _format("iLeft = %d  iTop = %d", iLeft, iTop)
--	inDrawDC:DrawText(sToDraw, 5, 5)	

--	local iSum = (iLeft + iSpacerX)
--	local iTot = iLeft * 2 + iSpacerX
--	sToDraw = _format("iSum = %d  iTot = %d", iSum, iTot)
--	inDrawDC:DrawText(sToDraw, 5, 20)
	
--	sToDraw = _format("Width = %d  Height = %d", m_Frame.rcClientW, m_Frame.rcClientH)
--	inDrawDC:DrawText(sToDraw, 5, 35)

end

-- ----------------------------------------------------------------------------
--
local function NewMemDC() 
--	trace.line("NewMemDC")

	-- create a bitmap wide as the client area
	--
	local memDC  = wx.wxMemoryDC()
 	local bitmap = wx.wxBitmap(m_Frame.rcClientW, m_Frame.rcClientH)
	memDC:SelectObject(bitmap)

	DrawChar(memDC)

	return memDC
end

-- ----------------------------------------------------------------------------
--
local function Refresh()
--	trace.line("Refresh")

	if m_Frame.hMemoryDC then
		m_Frame.hMemoryDC:delete()
		m_Frame.hMemoryDC = nil
	end

	m_Frame.hMemoryDC = NewMemDC()
	
	if m_Frame.hWindow then
		m_Frame.hWindow:Refresh()   
	end	
end

-- ----------------------------------------------------------------------------
-- we just splat the off screen dc over the current dc
--
local function OnPaint() 
--	trace.line("OnPaint")
	
	if not m_Frame.hMemoryDC then return end

	local dc = wx.wxPaintDC(m_Frame.hWindow)
	
	dc:Blit(0, 0, m_Frame.rcClientW, m_Frame.rcClientH, m_Frame.hMemoryDC, 0, 0, wx.wxBLIT_SRCCOPY)
	dc:delete()
end

-- ----------------------------------------------------------------------------
--
local function OnSize(event)
--	trace.line("OnSize")

	local size = event:GetSize()

	m_Frame.rcClientW = size:GetWidth() - 4
	m_Frame.rcClientH = size:GetHeight() - 36
	
	-- regenerate the offscreen buffer
	--
	Refresh()
end

-- ----------------------------------------------------------------------------
-- handle the show window event, starts the timer
--
local function OnShow(event)
	if not m_Frame.hWindow then return end
	
	if event:GetShow() then
		
		m_Frame.bVisible = true
		Refresh()

	else
		m_Frame.bVisible = false
	end	
end

-- ----------------------------------------------------------------------------
--
local function IsWindowVisible()
	
	if not m_Frame.hWindow then return false end
	
	return m_Frame.bVisible
end

-- ----------------------------------------------------------------------------
-- show the window
--
local function SetFont(inFontName, inFontSize)
	
	local dwFlags = bits.bitoper(wx.wxFONTFLAG_ANTIALIASED, wx.wxFONTFLAG_MASK, bits.OR)
	
	-- allocate
	--
	local fnDraw = wx.wxFont(-1 * inFontSize, wx.wxFONTFAMILY_MODERN, dwFlags,
							wx.wxFONTWEIGHT_NORMAL, false, inFontName, wx.wxFONTENCODING_SYSTEM)
						
	local fnText = wx.wxFont(-1 * 12.5, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL,
							wx.wxFONTWEIGHT_NORMAL, false, "Source Code Pro", wx.wxFONTENCODING_SYSTEM)
	
	m_Frame.fnDraw = fnDraw
	m_Frame.fnText = fnText	
end

-- ----------------------------------------------------------------------------
-- show the window
--
local function SetChar(inBytes)
	
	-- check if character can be printed
	--
	if 0x20 > inBytes:byte(1) then inBytes = "�" end

	m_Frame.sData = inBytes
	
	if m_Frame.bVisible then Refresh() end	
end

-- ----------------------------------------------------------------------------
-- show the window
--
local function DisplayWindow(inShowStatus)
--	trace.line("ShowWindow")
	
	if not m_Frame.hWindow then return end
	
	-- display
	--
	m_Frame.bVisible = inShowStatus
	if m_Frame.hWindow then m_Frame.hWindow:Show(inShowStatus) end
end

-- ----------------------------------------------------------------------------
--
local function OnClose()
--	trace.line("OnClose")
	
	if not m_Frame.hWindow then return end

	-- finally destroy the window
	--
	m_Frame.hWindow:Destroy(m_Frame.hWindow)
	m_Frame.hWindow = nil
end

-- ----------------------------------------------------------------------------
--
local function CloseWindow()
--	trace.line("CloseWindow")

	OnClose()
end

-- ----------------------------------------------------------------------------
-- create the main window
--
local function CreateWindow(inParent)
--	trace.line("CreateMainWindow")

	wx.wxBeginBusyCursor()
		
	inParent = inParent or wx.NULL
	
	-- create a window
	--
	local frame = wx.wxFrame(inParent, wx.wxID_ANY, "Magnify",
							 wx.wxPoint(20, 20), wx.wxSize(500, 560),
							 dwMainFlags)
	
	-- standard event handlers
	--
	frame:Connect(wx.wxEVT_SHOW,			OnShow)
	frame:Connect(wx.wxEVT_PAINT,			OnPaint)
	frame:Connect(wx.wxEVT_SIZE,			OnSize)
	frame:Connect(wx.wxEVT_CLOSE_WINDOW,	OnClose)
	
	-- this is necessary to avoid flickering
	-- (comment the line if running with the debugger
	-- and the Lua's version is below 5.2)
	--
	frame:SetBackgroundStyle(wx.wxBG_STYLE_CUSTOM)
	
	--  store for later
	--
	m_Frame.hWindow = frame	
	
	wx.wxEndBusyCursor()
	
	return frame
end

-- ----------------------------------------------------------------------------
--
return
{
	Create	  = CreateWindow,
	Display	  = DisplayWindow,
	Close	  = CloseWindow,
	IsVisible = IsWindowVisible,
	SetFont	  = SetFont,
	SetChar	  = SetChar,
}

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
