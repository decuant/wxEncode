-- ----------------------------------------------------------------------------
--
--  wxFind - window for finding text in the file
--
-- ----------------------------------------------------------------------------

local wx 		= require "wx"			-- uses wxWidgets for Lua 5.2
local palette	= require "wxPalette"	-- common colours definition in wxWidgets
--local trace 	= require "trace"		-- shortcut for tracing

-- ----------------------------------------------------------------------------
-- reference to the application
--
local m_App = nil

-- ----------------------------------------------------------------------------
-- window's private members
--
local m_Frame =
{
	hWindow = nil,		-- main frame
	edFind  = nil,		-- text find edit control
	ckCase	= nil,		-- ignore case option
	ckWrap	= nil,		-- wrap at end of file
	hTimer	= nil,		-- timer for messages
	txMsg	= nil,		-- label for message
}

-- ----------------------------------------------------------------------------
-- preallocated GDI objects
--
local m_clrBack  = palette.Gray15
local m_clrFore  = palette.Honeydew2
local m_clrExtra = palette.OrangeRed

-- ----------------------------------------------------------------------------
-- return the wxWindow handle
--
local function GetHandle()
	return m_Frame.hWindow
end

-- ----------------------------------------------------------------------------
-- handle the show window event
--
local function OnShow(event)
--	trace.line("OnShow")

	if not m_Frame.hWindow then return end

	if event:GetShow() then
		m_Frame.edFind:SetFocus()
	end
end

-- ----------------------------------------------------------------------------
-- just hide the error message
--
local function OnTimer()
--	trace.line("OnTimer")

	m_Frame.txMsg:Show(false)
end

-- ----------------------------------------------------------------------------
--
local function ShowMessage(inText)
--	trace.line("ShowMessage")

	m_Frame.txMsg:SetLabel(inText)
	m_Frame.txMsg:Show(true)
	m_Frame.hTimer:Start(2000, true)
end

-- ----------------------------------------------------------------------------
--
local function OnFindEnter()
--	trace.line("OnFindEnter")

	local sText = m_Frame.edFind:GetValue()
	if 0 == sText:len() then return end

	local iRet = m_App.FindText(sText, nil, m_Frame.ckCase:IsChecked())

	if -1 == iRet and m_Frame.ckWrap:IsChecked() then

		ShowMessage("Passed the end")

		-- if first scan failed then scan again from first byte
		--
		iRet = m_App.FindText(sText, 1, m_Frame.ckCase:IsChecked())
	end

	-- give feedback that the text wasn't found
	-- (this timer will auto-delete)
	--
	if -1 == iRet then ShowMessage("Text not found") end
end

-- ----------------------------------------------------------------------------
--
local function IsWindowVisible()

	local wFrame = m_Frame.hWindow
	if not wFrame then return false end

	return wFrame:IsShown()
end

-- ----------------------------------------------------------------------------
-- show/hide the window
--
local function DisplayWindow(inShowStatus)
--	trace.line("DisplayWindow")

	local wFrame = m_Frame.hWindow
	if not wFrame then return end

	-- display/hide
	--
	wFrame:Show(inShowStatus)
end

-- ----------------------------------------------------------------------------
--
local function OnClose()
--	trace.line("OnClose")

	local wFrame = m_Frame.hWindow
	if not wFrame then return end

	-- finally destroy the window
	--
	wFrame:Destroy(wFrame)
	m_Frame.hWindow = nil
end

-- ----------------------------------------------------------------------------
--
local function CloseWindow()
--	trace.line("CloseWindow")

	OnClose()
end

-- ----------------------------------------------------------------------------
-- assign back and fore colors to all controls in dialog
--
local function SetupColour(inBack, inFront, inExtra, inFont)
--	trace.line("SetupColour")

	m_clrBack  = inBack
	m_clrFore  = inFront
	m_clrExtra = inExtra

	local wlist = m_Frame.hWindow:GetChildren()
	local wNode = wlist:Item(0)
	local ctrl

	-- cycle all controls in the dialog window
	--
	while wNode do

		ctrl = wNode:GetData():DynamicCast("wxWindow")
		ctrl:SetBackgroundColour(m_clrBack)
		ctrl:SetForegroundColour(m_clrFore)

		-- if a font was supplied then change it
		--
		if inFont then ctrl:SetFont(inFont) end

		wNode = wNode:GetNext()
	end

	m_Frame.hWindow:SetBackgroundColour(m_clrBack)
	m_Frame.txMsg:SetForegroundColour(m_clrExtra)

	if IsWindowVisible() then m_Frame.hWindow:Refresh() end
end

-- ----------------------------------------------------------------------------
-- create the main window
--
local function CreateWindow(inApp, inParent, inConfig)
--	trace.line("CreateWindow")

	inParent = inParent or wx.NULL

	-- flags in use for the frame - note that lacks the resize border
	--
	local dwFrameFlags = bit32.bor(wx.wxFRAME_TOOL_WINDOW, wx.wxCAPTION)
		  dwFrameFlags = bit32.bor(dwFrameFlags, wx.wxFRAME_FLOAT_ON_PARENT)

	-- create a window
	--
	local ptLeft	= inConfig[1]
	local ptTop		= inConfig[2]
	local siWidth	= inConfig[3]
	local siHeight	= inConfig[4]

	local frame = wx.wxFrame(inParent, wx.wxID_ANY, "Find Text",
							 wx.wxPoint(ptLeft, ptTop),
							 wx.wxSize(siWidth, siHeight),
							 dwFrameFlags)

	-- standard event handlers
	--
	frame:Connect(wx.wxEVT_SHOW,			OnShow)
	frame:Connect(wx.wxEVT_TIMER,			OnTimer)
	frame:Connect(wx.wxEVT_CLOSE_WINDOW,	OnClose)

	-- edit controls for typing values
	--
    local edFind, ckCase, ckWrap, txMsg

	wx.wxStaticText(frame, wx.wxID_ANY, "Search:",
					wx.wxPoint(10, 40), wx.wxSize(100, 50))

    edFind = wx.wxTextCtrl(frame, wx.wxID_ANY, "",
                            wx.wxPoint(120, 36), wx.wxSize(360, 40),
                            wx.wxTE_PROCESS_ENTER, wx.wxTextValidator(wx.wxFILTER_NONE))

	ckCase = wx.wxCheckBox(frame, wx.wxID_ANY, "Ignore Case",
							wx.wxPoint(120, 80), wx.wxSize(250, 40))

	ckWrap = wx.wxCheckBox(frame, wx.wxID_ANY, "Wrap Search",
							wx.wxPoint(120, 120), wx.wxSize(250, 40))

	txMsg  = wx.wxStaticText(frame, wx.wxID_ANY, "",
							 wx.wxPoint(120, 160), wx.wxSize(250, 50))

	txMsg:Show(false)		-- error message is hidden by default

	-- event handlers
	--
	edFind:Connect(wx.wxEVT_COMMAND_TEXT_ENTER, OnFindEnter)

	-- set the checks enabled
	-- (useful when viewing blocks samples)
	--
	ckCase:SetValue(true)
	ckWrap:SetValue(true)

	--  store for later
	--
	m_Frame.hWindow	= frame
	m_Frame.edFind	= edFind
	m_Frame.ckCase	= ckCase
	m_Frame.ckWrap	= ckWrap
	m_Frame.txMsg	= txMsg

	m_App = inApp

	-- assign colours and font
	--
	local fnText = wx.wxFont(-1 * 17.5, wx.wxFONTFAMILY_SWISS, wx.wxFONTFLAG_ANTIALIASED,
							 wx.wxFONTWEIGHT_LIGHT, false, "Lucida Sans Unicode")

	SetupColour(m_clrBack, m_clrFore, m_clrExtra, fnText)

	-- create the timer for messages
	--
	m_Frame.hTimer = wx.wxTimer(frame, wx.wxID_ANY)
end

-- ----------------------------------------------------------------------------
--
return
{
	GetHandle	= GetHandle,
	Create		= CreateWindow,
	Display		= DisplayWindow,
	Close		= CloseWindow,
	IsVisible	= IsWindowVisible,
	SetupColour	= SetupColour,
}

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
