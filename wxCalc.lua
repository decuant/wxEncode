-- ----------------------------------------------------------------------------
--
--  wxCalc - window for conversion Unicode <-> UTF_8
--
-- ----------------------------------------------------------------------------

local wx 		= require "wx"			-- uses wxWidgets for Lua 5.2
local palette	= require "wxPalette"	-- common colours definition in wxWidgets
				  require "extrastr"	-- check UTF_8 byte sequence validity
				  
local _floor	= math.floor
local _format	= string.format
local _utf8lup	= string.utf8lup
local _insert	= table.insert

-- ----------------------------------------------------------------------------
-- window's private members
--
local m_Frame = 
{
	hWindow		= nil,		-- main frame
	edUnicode	= nil,		-- Unicode edit control
	edSequence	= nil,		-- bytes' sequence control
	ckSequence	= nil,		-- check sequence against Unicode ABNF
	txMsg		= nil,		-- label for message	
}

-- ----------------------------------------------------------------------------
-- flags in use for the frame
--
local dwFrameFlags = bit32.bor(wx.wxFRAME_TOOL_WINDOW, wx.wxCAPTION)
	  dwFrameFlags = bit32.bor(dwFrameFlags, wx.wxRESIZE_BORDER)
	  dwFrameFlags = bit32.bor(dwFrameFlags, wx.wxFRAME_FLOAT_ON_PARENT)
	
-- ----------------------------------------------------------------------------
-- preallocated GDI objects
--
local clrBack = palette.Gray15
local clrFore = palette.Honeydew2	

-- ----------------------------------------------------------------------------
-- string for error reporting
--
local sErrors = 
{
	"format",
	"syntax",
	"convert",
}

-- ----------------------------------------------------------------------------
-- check the bytes' sequence to be a proper Unicode sequence
-- as described in the RFC 3629 document
-- wants a normalized hex string
--
local function _checkUTF_8(inText)

	local sByte = inText:sub(1, 2)
	local iByte = tonumber(sByte, 16)
	
	-- trick to check for the second byte
	--
	if "C0" == sByte or "C1" == sByte then sByte = "C2" end
	
	-- get the scrutiny row using the first byte
	--
	local tUtf8Row = _utf8lup(iByte)
	
	if not tUtf8Row then return "UTF8 row no found"	end
	
	-- check the number of required bytes
	--
	if #tUtf8Row > #inText then return "Too few bytes"  end
	if #tUtf8Row < #inText then return "Too many bytes" end
	
	-- check the remaining bytes against the description
	--
	for i=3, #tUtf8Row, 2 do
		
		sByte = inText:sub(i, i + 1)
		iByte = tonumber(sByte, 16)
		
		-- check if within bounds
		--
		if tUtf8Row[i] > iByte or iByte > tUtf8Row[i + 1] then
			
			return _format("At: %d offending: %s", i, sByte)
		end
	end

	-- alles good
	--
	return ""
end

-- ----------------------------------------------------------------------------
-- make a string array represent a valid hexadecimal code
--
local function _norm(inText)
	
	if 0 == inText:len() then return "00" end
	
	inText = inText:gsub(" ", "")
	inText = inText:upper()
	inText = inText:sub(1, math.min(#inText, 8))
	if 1 == (inText:len() % 2) then inText = "0" .. inText end
	
	return inText
end

-- ----------------------------------------------------------------------------
-- convert an ASCII string of hex values into a table of bytes
--
local function _text2hex(inText)
	
	local tBytes = { }
	local iHexVal

	for i=1, #inText do
		
		iHexVal = (inText:byte(i) - 0x30)
		if 0x09 < iHexVal then iHexVal = iHexVal - 0x07 end
		
		_insert(tBytes, iHexVal)
	end
	
	return tBytes
end

-- ----------------------------------------------------------------------------
-- split a string into a table of bytes
-- (converts from text hex to number)
-- assume the string evenly aligned
--
local function _text2num(inText)
	
	local iNibbleH, iNibbleL
	local tBytes = { }
	
	-- convert from hex text to number
	-- byte by byte (2 chars at time)
	--
	for i=1, #inText, 2 do
		
		iNibbleH = (inText:byte(i) - 0x30)
		if 0x09 < iNibbleH then iNibbleH = iNibbleH - 0x07 end
		iNibbleH = iNibbleH * 0x10
		
		iNibbleL = (inText:byte(i+1) - 0x30)
		if 0x09 < iNibbleL then iNibbleL = iNibbleL - 0x07 end

		_insert(tBytes, iNibbleH + iNibbleL)
	end
	
	return tBytes
end

-- ----------------------------------------------------------------------------
-- get a Unicode reference number and convert it to its UTF_8 representation
-- (assume a properly formatted hex number was passed as argument)
--
local function _uni2bytes(inText)
	
	local iSumUp = tonumber(inText, 16)
	local tBytes = _text2hex(inText)
	local sValue = ""
	local iByte1 = 0
	local iByte2 = 0
	local iByte3 = 0
	local iByte4 = 0
	
	-- sanity check
	--
	if not iSumUp then return sValue end
	
	if 0x07d0 > iSumUp then
		
		-- c2-df block (2 bytes)
		------------------------
		
		iByte4 = 0x80	+ (tBytes[4] % 0x10)		+ 0x10 * (tBytes[3] % 0x04)
		iByte3 = 0xc0	+ _floor(tBytes[3] / 0x04)	+ 0x04 * (tBytes[2] % 0x08)
		
		sValue = _format("%02x %02x", iByte3, iByte4)
		
	elseif 0x010000 > iSumUp then
		
		-- e0-ef block (3 bytes)
		------------------------
		
		iByte4 = 0x80	+ (tBytes[4] % 0x10) 		+ 0x10 * (tBytes[3] % 0x04)
		iByte3 = 0x80	+ _floor(tBytes[3] / 0x04) 	+ 0x04 * (tBytes[2] % 0x10)
		iByte2 = 0xe0	+ tBytes[1]
		
		sValue = _format("%02x %02x %02x", iByte2, iByte3, iByte4)
		
	else
		
		-- f0-f4 block (4 bytes)
		------------------------
		
		iByte4 = 0x80	+ (tBytes[6] % 0x10) 		+ 0x10 * (tBytes[5] % 0x04)
		iByte3 = 0x80	+ _floor(tBytes[5] / 0x04) 	+ 0x04 * (tBytes[4] % 0x10)			
		iByte2 = 0x80	+ (tBytes[3] % 0x10)		+ 0x10 * (tBytes[2] % 0x04)
		iByte1 = 0xf0	+ (tBytes[2] / 0x04)
		
		sValue = _format("%02x %02x %02x %02x", iByte1, iByte2, iByte3, iByte4)
	end

	return sValue
end

-- ----------------------------------------------------------------------------
-- get a byte array and try to convert it to an Unicode reference number
-- expect an array made of 8 characters maximum
-- where each character is a nibble
--
local function _bytes2uni(inText)

	local tBytes	= _text2num(inText)			-- split values
	local iRefUTF8	= -1
	
	-- if the code entered is invalid these arithmetics will overflow
	--
	if 4 == #tBytes then		
		iRefUTF8 = ((tBytes[1] - 0xf0) * 0x40000) + ((tBytes[2] - 0x80) * 0x1000) + ((tBytes[3] - 0x80) * 0x40) + (tBytes[4] - 0x80)		
	elseif 3 == #tBytes then		
		iRefUTF8 = ((tBytes[1] - 0xe0) * 0x1000) + ((tBytes[2] - 0x80) * 0x40) + (tBytes[3] - 0x80)		
	elseif 2 == #tBytes then		
		iRefUTF8 = ((tBytes[1] - 0xc0) * 0x40) + (tBytes[2] - 0x80)		
	else
		-- this is not strictly an error
		-- mark with a negative number
		--
	end
	
	if 0 > iRefUTF8 then return "" end
	
	-- Unicode prints its documents with uppercase letters
	-- Unicode uses a 5 nibbles format (not 6) for long codes
	--
	return _format("%04X", iRefUTF8)
end

-- ----------------------------------------------------------------------------
--
local function OnUnicodeEnter(event)
--	trace.line("OnUnicodeEnter")

	local edUnico = m_Frame.edUnicode
	local edBytes = m_Frame.edSequence
	local txMsg   = m_Frame.txMsg
	
	local sText = edUnico:GetValue()
	if 3 >= sText:len() then return end
	
	sText = _norm(sText)		-- normalize
	sText = _uni2bytes(sText)	-- convert it
	edBytes:SetValue(sText)		-- show result
	txMsg:SetLabel("")			-- auto cleanup
end

-- ----------------------------------------------------------------------------
--
local function OnSequenceEnter(event)
--	trace.line("OnSequenceEnter")

	local edUnico = m_Frame.edUnicode
	local edBytes = m_Frame.edSequence
	local txMsg   = m_Frame.txMsg
	
	local sText = edBytes:GetValue()
	if 3 >= sText:len() then return end
	
	sText = _norm(sText)		-- normalize
	sText = _bytes2uni(sText)	-- convert it
	edUnico:SetValue(sText)		-- show result
	txMsg:SetLabel("")			-- auto cleanup

	-- do the extra check
	--
	if true == m_Frame.ckSequence:IsChecked() then

		local sChecked = _checkUTF_8(_norm(edBytes:GetValue()))
		
		m_Frame.txMsg:SetLabel(sChecked)
	end
end

-- ----------------------------------------------------------------------------
-- handle the show window event, starts the timer
--
local function OnShow(event)
--	trace.line("OnShow")

	if not m_Frame.hWindow then return end
	
	if event:GetShow() then		
		m_Frame.edUnicode:SetFocus()
	end	
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
local function SetupColour(inBack, inFront, inFont)
--	trace.line("SetupColour")

	clrBack = inBack
	clrFore = inFront
	
	local wlist = m_Frame.hWindow:GetChildren()
	local wNode = wlist:Item(0)
	local ctrl
	
	-- cycle all controls in the dialog window
	--
	while wNode do
		
		ctrl = wNode:GetData():DynamicCast("wxWindow")
		ctrl:SetBackgroundColour(clrBack)
		ctrl:SetForegroundColour(clrFore)
		
		-- if a font was supplied then change it
		--
		if inFont then ctrl:SetFont(inFont) end
			
		wNode = wNode:GetNext()
	end
	
	m_Frame.hWindow:SetBackgroundColour(clrBack)
	
	-- a little tweak to show the error message in red
	--
	m_Frame.txMsg:SetForegroundColour(palette.OrangeRed)	
	
	if IsWindowVisible() then m_Frame.hWindow:Refresh() end
end

-- ----------------------------------------------------------------------------
-- create the main window
--
local function CreateWindow(inParent, inConfig)
--	trace.line("CreateMainWindow")

	inParent = inParent or wx.NULL
	
	-- create a window
	--	
	local ptLeft	= inConfig[1]
	local ptTop		= inConfig[2]
	local siWidth	= inConfig[3]
	local siHeight	= inConfig[4]
	
	local frame = wx.wxFrame(inParent, wx.wxID_ANY, "Calculator",
							 wx.wxPoint(ptLeft, ptTop), 
							 wx.wxSize(siWidth, siHeight),
							 dwFrameFlags)
	
	-- standard event handlers
	--
	frame:Connect(wx.wxEVT_SHOW,			OnShow)
	frame:Connect(wx.wxEVT_CLOSE_WINDOW,	OnClose)

	-- validator for the text controls
	--
	local validator = wx.wxTextValidator(wx.wxFILTER_INCLUDE_CHAR_LIST)
	local tFilter	= { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
					    "a", "b", "c", "d", "e", "f",
						"A", "B", "C", "D", "E", "F", " ",
					  }
	
	validator:SetIncludes(tFilter)

	-- edit controls for typing values
	--
    local edUnico, edBytes, ckSeqnc, txMsg
	
    wx.wxStaticText(frame, wx.wxID_ANY, "Unicode Value:  U+",
					wx.wxPoint(10, 40), wx.wxSize(200, 50))
							
    edUnico = wx.wxTextCtrl(frame, wx.wxID_ANY, "",
                            wx.wxPoint(250, 38), wx.wxSize(150, 40),
                            wx.wxTE_PROCESS_ENTER, validator)
						
	wx.wxStaticText(frame, wx.wxID_ANY, "Hex Sequence:",
					wx.wxPoint(10, 100), wx.wxSize(200, 50))    

    edBytes = wx.wxTextCtrl(frame, wx.wxID_ANY, "",
							wx.wxPoint(250, 98), wx.wxSize(230, 40),
                            wx.wxTE_PROCESS_ENTER, validator)

	ckSeqnc = wx.wxCheckBox(frame, wx.wxID_ANY, "Check Sequence",
							wx.wxPoint(250, 150), wx.wxSize(230, 40))
						
	txMsg  = wx.wxStaticText(frame, wx.wxID_ANY, "",
							 wx.wxPoint(250, 190), wx.wxSize(230, 40))						
	-- event handlers
	--
	edUnico:Connect(wx.wxEVT_COMMAND_TEXT_ENTER, OnUnicodeEnter)
	edBytes:Connect(wx.wxEVT_COMMAND_TEXT_ENTER, OnSequenceEnter)
	
	-- set the error check enabled
	--
	ckSeqnc:SetValue(true)	
	
	--  store for later
	--
	m_Frame.hWindow		= frame
	m_Frame.edUnicode	= edUnico
	m_Frame.edSequence	= edBytes
	m_Frame.ckSequence	= ckSeqnc
	m_Frame.txMsg		= txMsg
	
	-- assign colours and font
	--
	local fnText = wx.wxFont(-1 * 17.5, wx.wxFONTFAMILY_SWISS, wx.wxFONTFLAG_ANTIALIASED,
							 wx.wxFONTWEIGHT_LIGHT, false, "Lucida Sans Unicode")

	SetupColour(clrBack, clrFore, fnText)
	
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
	SetupColour = SetupColour,
}

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
