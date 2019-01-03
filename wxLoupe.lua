-- ----------------------------------------------------------------------------
--
--  wxLoupe - window for displaying a single char
--
-- ----------------------------------------------------------------------------

local wx 		= require "wx"			-- uses wxWidgets for Lua 5.2
local palette	= require "wxPalette"	-- common colours definition in wxWidgets
-- local trace 	= require "trace"		-- shortcut for tracing

local _floor	= math.floor
local _format	= string.format
local _find		= string.find
local _concat	= table.concat

-- ----------------------------------------------------------------------------
-- reference to the application
--
local m_App = nil

-- ----------------------------------------------------------------------------
-- window's private members
--
local m_Frame =
{
	hWindow		= nil,		-- main frame
	hBackDC		= nil,		-- background device context
	hMemoryDC	= nil,		-- device context for the window
	bTreat		= true,		-- append fix '\n' to character
	fnDraw		= nil,		-- font big size
	fnText		= nil, 		-- font for details
	sData		= "",		-- current character
	sUnicode	= "",		-- Unicode number value
	sDescription= " ",		-- Unicode's description
	sFontName	= "",		-- selected font name
	iFontSize	= -50,		-- selected font size

	rcClientW	= 0,
	rcClientH	= 0,
}

-- ----------------------------------------------------------------------------
-- font names that do not need treatment
--
local m_tNames =
{
	sNamesFile	= nil,		-- file name for Unicode's names
	fhNames		= nil,		-- file handle "	"	"	"	"
	tFileCache	= { },		-- file's indexing
}

-- ----------------------------------------------------------------------------
-- font names that do not need treatment
--
local m_tTreat =
{
	"Unifont",
	"Gulim",
	"Batang",
	"Gungsuh",
}

-- ----------------------------------------------------------------------------
-- preallocated GDI objects
--
local m_penNULL  = wx.wxPen(palette.Black, 0, wx.wxTRANSPARENT)
local m_brNULL   = wx.wxBrush(palette.White, wx.wxTRANSPARENT)

local m_penRect  = wx.wxPen(palette.White, 3, wx.wxDOT)
local m_brBack   = wx.wxBrush(palette.Black, wx.wxSOLID)
local m_clrFore  = palette.White
local m_clrExtra = palette.OrangeRed

-- ----------------------------------------------------------------------------
-- return the wxWindow handle
--
local function GetHandle()
	return m_Frame.hWindow
end

-- ----------------------------------------------------------------------------
-- get a string and convert it to an Unicode reference number
-- expect an array made of 8 characters maximum
-- where each character is a nibble
--
local function _text2uni(inText)

	if 1 == inText:len() then return string.byte(inText) end

	local tBytes	= { }			-- split values
	local iRefUTF8	= -1
	
	for i=1, inText:len() do
		tBytes[i] = inText:byte(i)
	end

	-- if the code entered is invalid these arithmetics will overflow
	--
	if 4 == #tBytes then
		iRefUTF8 = ((tBytes[1] - 0xf0) * 0x40000) + ((tBytes[2] - 0x80) * 0x1000) + ((tBytes[3] - 0x80) * 0x40) + (tBytes[4] - 0x80)
	elseif 3 == #tBytes then
		iRefUTF8 = ((tBytes[1] - 0xe0) * 0x1000) + ((tBytes[2] - 0x80) * 0x40) + (tBytes[3] - 0x80)
	else -- if 2 == #tBytes then
		iRefUTF8 = ((tBytes[1] - 0xc0) * 0x40) + (tBytes[2] - 0x80)
	end

	-- Unicode prints its documents with uppercase letters
	-- Unicode uses a 5 nibbles format (not 6) for long codes
	--
	return iRefUTF8
end

-- ----------------------------------------------------------------------------
--
local function DrawChar(inDrawDC)
--	trace.line("DrawChar")

	if not m_Frame.fnDraw then return end

	local chCurrent = m_Frame.sData
	if 0 == #chCurrent then return end

	inDrawDC:SetFont(m_Frame.fnDraw)
	inDrawDC:SetTextForeground(m_clrFore)

	local iWidth, iHeight, iExtent, iLeading = inDrawDC:GetTextExtent(chCurrent)

	-- center the character to the middle of the client area width
	-- and leave some room on the top
	--
	local iLeft = _floor((m_Frame.rcClientW - iWidth) / 2)
	local iTop  = _floor((m_Frame.rcClientH - iHeight) / 8)

	if 0 > iLeft then iLeft = 0 end
	if 0 > iTop  then iTop  = 0 end

	-- with wxWidgets many characters won't display at all
	-- if the text is not completed with a '\n' or '\r',
	-- there are exceptions that must be treated
	--
	if not m_Frame.bTreat then
		inDrawDC:DrawText(chCurrent, iLeft, iTop)
	else
		inDrawDC:DrawText(chCurrent .. "\n", iLeft, iTop)
	end

	-- draw a thin bounding box for the char
	--
	inDrawDC:SetPen(m_penRect)
	inDrawDC:SetBrush(m_brNULL)

	inDrawDC:DrawRoundedRectangle(iLeft, iTop, iWidth, iHeight, 10)

	if 0 < iLeading then
		local iOffsetY = iTop + iLeading
		inDrawDC:DrawLine(iLeft, iOffsetY, iLeft + iWidth, iOffsetY)
	end

	if 0 < iExtent then
		local iOffsetY = iTop + iHeight - iExtent
		inDrawDC:DrawLine(iLeft, iOffsetY, iLeft + iWidth, iOffsetY)
	end
	
	-- switch font
	--
	inDrawDC:SetFont(m_Frame.fnText)
	inDrawDC:SetTextForeground(m_clrExtra)

	-- draw the details
	--
	local iLength = chCurrent:len()
	local sHexFmt = "0x%02x"
	local sText

	if 1 == iLength then

		sText = _format(sHexFmt, chCurrent:byte(i))
	else

		local tToDraw = { }

		for i=1, iLength do
			tToDraw[#tToDraw + 1] = _format(sHexFmt, chCurrent:byte(i))
		end

		sText = _concat(tToDraw, " ")
	end

	-- do draw the char as UTF_8
	--
	local iExtX, iExtY = inDrawDC:GetTextExtent(sText)
	local iPosX	= iLeft + iWidth / 2 - iExtX / 2		-- center on X
	local iPosY	= iTop  + iHeight + 25					-- align to bounding box bottom

	inDrawDC:DrawText(sText, iPosX, iPosY)
	
	-- corresponding Unicode value (16 bits)
	--
	sText = m_Frame.sUnicode
	iExtX = inDrawDC:GetTextExtent(sText)
	iPosX = iLeft + iWidth / 2 - iExtX / 2
	iPosY = iPosY + iExtY
	
	inDrawDC:DrawText(sText, iPosX, iPosY)	
	
	-- if got a Unicode's description then write it
	-- (break at 'WITH' word to span on 2 lines, note
	-- that Unicode's descriptions are uppercase)
	--
	if 0 < m_Frame.sDescription:len() then
		
		local sLine1, sLine2
		local iStart, iEnd = m_Frame.sDescription:find("WITH")
		
		if iStart then
			sLine1 = m_Frame.sDescription:sub(1, iStart - 1)
			sLine2 = m_Frame.sDescription:sub(iEnd + 1)
		else
			sLine1 = m_Frame.sDescription
			sLine2 = ""
		end
		
		if 0 < sLine1:len() then
			iExtX = inDrawDC:GetTextExtent(sLine1)
			iPosX = iLeft + iWidth / 2 - iExtX / 2
			iPosY = iPosY + iExtY
			
			inDrawDC:DrawText(sLine1, iPosX, iPosY)
		end
		
		if 0 < sLine2:len() then
			iExtX = inDrawDC:GetTextExtent(sLine2)
			iPosX = iLeft + iWidth / 2 - iExtX / 2
			iPosY = iPosY + iExtY
			
			inDrawDC:DrawText(sLine2, iPosX, iPosY)
		end
	end
end

-- ----------------------------------------------------------------------------
--
local function NewMemDC()
--	trace.line("NewMemDC")

	-- create a bitmap wide as the client area
	--
	local memDC = m_Frame.hMemoryDC

	if not memDC then

		local bitmap = wx.wxBitmap(m_Frame.rcClientW, m_Frame.rcClientH)
		memDC  = wx.wxMemoryDC()
		memDC:SelectObject(bitmap)
	end

	-- draw the background
	--
	if not m_Frame.hBackDC then return end
	memDC:Blit(0, 0, m_Frame.rcClientW, m_Frame.rcClientH, m_Frame.hBackDC, 0, 0, wx.wxBLIT_SRCCOPY)

	-- draw the current char
	--
	DrawChar(memDC)

	return memDC
end

-- ----------------------------------------------------------------------------
--
local function NewBackground()
--	trace.line("NewBackground")

	-- create a bitmap wide as the client area
	--
	local memDC  = wx.wxMemoryDC()
 	local bitmap = wx.wxBitmap(m_Frame.rcClientW, m_Frame.rcClientH)
	memDC:SelectObject(bitmap)

	-- draw the background
	--
	memDC:SetPen(m_penNULL)
	memDC:SetBrush(m_brBack)

	memDC:DrawRectangle(0, 0, m_Frame.rcClientW, m_Frame.rcClientH)

	-- select font and do the draw in the middle
	--
	if m_Frame.fnText then

		memDC:SetFont(m_Frame.fnText)
		memDC:SetTextForeground(m_clrFore)					-- colour follows big font

		-- show the current font selected
		--
		local sDraw = _format("(%d %s)", m_Frame.iFontSize, m_Frame.sFontName)
		local iExtX, iExtY = memDC:GetTextExtent(sDraw)

		local iLeft = _floor(m_Frame.rcClientW / 2)
		local iPosX = iLeft - iExtX / 2						-- center on X
		local iTopY	= m_Frame.rcClientH - iExtY - 10		-- align to bottom of window

		memDC:DrawText(sDraw, iPosX, iTopY)
	end

	return memDC
end

-- ----------------------------------------------------------------------------
--
local function RefreshBackground()
--	trace.line("RefreshBackground")

	if m_Frame.hBackDC then
		m_Frame.hBackDC:delete()
		m_Frame.hBackDC = nil
	end

	m_Frame.hBackDC = NewBackground()
end

-- ----------------------------------------------------------------------------
--
local function Refresh()
--	trace.line("Refresh")

	m_Frame.hMemoryDC = NewMemDC()

	if m_Frame.hWindow then
		m_Frame.hWindow:Refresh(false)
	end
end

-- ----------------------------------------------------------------------------
-- regenerate the offscreen buffer
--
local function RefreshAll()
--	trace.line("RefreshAll")

	RefreshBackground()
	Refresh()
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

	if m_Frame.hMemoryDC then
		m_Frame.hMemoryDC:delete()
		m_Frame.hMemoryDC = nil
	end

	RefreshAll()
end

-- ----------------------------------------------------------------------------
-- handle the show window event, starts the timer
--
local function OnShow(event)
--	trace.line("OnShow")

	if not m_Frame.hWindow then return end

	if event:GetShow() then	RefreshAll() end
end

-- ----------------------------------------------------------------------------
--
local function IsWindowVisible()
--	trace.line("IsWindowVisible")

	local wFrame = m_Frame.hWindow
	if not wFrame then return false end

	return wFrame:IsShown()
end

-- ----------------------------------------------------------------------------
-- set the font properties
--
local function SetupFont(inFontSize, inFontName)
--	trace.line("SetupFont")

	-- allocate the requested font name with specified font size
	--
	local fnDraw = wx.wxFont(-1 * inFontSize, wx.wxFONTFAMILY_DEFAULT, wx.wxFONTFLAG_ANTIALIASED,
							wx.wxFONTWEIGHT_NORMAL, false, inFontName, wx.wxFONTENCODING_SYSTEM)

	-- this font instead has hardcoded properties
	--
	local fnText = wx.wxFont(-14, wx.wxFONTFAMILY_MODERN, wx.wxFONTFLAG_ANTIALIASED,
							wx.wxFONTWEIGHT_NORMAL, false, "DejaVu Sans Mono")

	-- check if characters must be treated
	--
	m_Frame.bTreat = true
	for _, fontName in ipairs(m_tTreat) do
		if fontName == inFontName then m_Frame.bTreat = false break end
	end

	-- store for later
	--
	m_Frame.fnDraw = fnDraw
	m_Frame.fnText = fnText

	m_Frame.sFontName = inFontName		-- selected font name
	m_Frame.iFontSize = inFontSize		-- selected font size

	if IsWindowVisible() then RefreshAll() end
end

-- ----------------------------------------------------------------------------
-- set the colour properties
--
local function SetupColour(inBack, inFront, inExtra)
--	trace.line("SetupColour")

	m_brBack   = wx.wxBrush(inBack, wx.wxSOLID)
	m_clrFore  = inFront
	m_clrExtra = inExtra

	-- this is the colour used for the bounding rectangle
	--
	local colour = wx.wxColour(0xff - inBack:Red(),
							   0xff - inBack:Green(),
							   0xff - inBack:Blue())

	m_penRect = wx.wxPen(colour, 3, wx.wxDOT)

	if IsWindowVisible() then RefreshAll() end
end

-- ----------------------------------------------------------------------------
-- binary search for the index in this special table for the file in memory
-- table's rows are:
-- {Unicode value, seek position}
--
local function SeekPosLookup(inUnicode)

	local tCached = m_tNames.tFileCache
	local iStart  = 1
	local iEnd	  = #tCached
	local iIndex

	-- check for the very first row that happens to start with a zero
	--
	if (0 == inUnicode) and (0 < #tCached) then return tCached[1][2] end

	-- do the scan
	--
	while iStart <= iEnd do

		iIndex = _floor(iStart + (iEnd - iStart) / 2)

		if tCached[iIndex][1] == inUnicode then return tCached[iIndex][2] end

		if tCached[iIndex][1] < inUnicode then iStart = iIndex + 1 else iEnd = iIndex - 1 end
	end

	return -1
end

-- ----------------------------------------------------------------------------
-- check for a description in the name's file
--
local function GetDescription(inUnicode)
	
	-- sanity check
	--
	if 0 > inUnicode then return "" end
	if not m_tNames.fhNames then return "" end
	
	-- get the seek position
	--
	local iSeekPos	= SeekPosLookup(inUnicode)
	local sText		= ""
	
	if -1 < iSeekPos then
		
		m_tNames.fhNames:seek("set", iSeekPos)		-- seek pos
		sText = m_tNames.fhNames:read("*l")			-- read line
		sText = sText:sub(sText:find("\t") + 1)		-- extract description
	end
	
	return sText
end

-- ----------------------------------------------------------------------------
-- update the current character
--
local function SetData(inBytes)
--	trace.line("SetData")

	if inBytes ~= m_Frame.sData then

		m_Frame.sData = inBytes or ""
		m_Frame.sUnicode 	 = ""
		m_Frame.sDescription = ""
		
		if 0 < m_Frame.sData:len() then
			
			local iUnicode = _text2uni(inBytes)
			
			m_Frame.sUnicode	 = _format("U+%04X", iUnicode)
			m_Frame.sDescription = GetDescription(iUnicode)
		end
		
		Refresh()
	end
end

-- ----------------------------------------------------------------------------
-- associate the Unicode's names file (if any)
-- bare file format has
-- Unicode value    tab   description
-- file indexing is made of rows like
-- {Unicode value, seek offset}
--
local function SetNamesFile(inFilename)
--	trace.line("SetNamesFile")

	m_tNames.sNamesFile	= inFilename
	m_tNames.fhNames	= nil			-- reset
	m_tNames.tFileCache = { }
	
	-- sanity check
	--
	if not inFilename then return end
	local fhSrc = io.open(inFilename, "r")
	if not fhSrc then return end
	
	-- read all lines (with newline)
	--
	local tLines = { }
	local tCurr  = {0, 0}
	local iSeek  = 0
	local iStart, iEnd
	local iUnicode
	
	wx.wxBeginBusyCursor()
	
	local sLine = fhSrc:read("*L")			-- note that we must read all the line

	while sLine do
		
		iStart = _find(sLine, "\t")
		
		if iStart and 1 < iStart then
			
			iUnicode = tonumber(sLine:sub(1, iStart - 1), 16)
			if iUnicode then
				
				tCurr[1] = iUnicode					-- Unicode value
				tCurr[2] = iSeek					-- seek position
				tLines[#tLines + 1] = tCurr			-- add row to lookup
				
				tCurr = {0, 0}						-- make new row
			end
		end

		-- update bytes counter and read next line
		--
		iSeek = iSeek + sLine:len()
		sLine = fhSrc:read("*L")
	end

	-- store for reading
	--
	m_tNames.fhNames	= fhSrc						-- valid file's handle
	m_tNames.tFileCache = tLines					-- lookup table

	wx.wxEndBusyCursor()
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

	if m_tNames.fhNames then				-- if left open release file
		m_tNames.fhNames:close()
		m_tNames.tFileCache = { }			-- .. and release any memory
	end

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
-- create the main window
--
local function CreateWindow(inApp, inParent, inConfig)
--	trace.line("CreateWindow")

	inParent = inParent or wx.NULL

	-- flags in use for the frame
	--
	local dwFrameFlags = bit32.bor(wx.wxFRAME_TOOL_WINDOW, wx.wxCAPTION)
		  dwFrameFlags = bit32.bor(dwFrameFlags, wx.wxRESIZE_BORDER)
		  dwFrameFlags = bit32.bor(dwFrameFlags, wx.wxFRAME_FLOAT_ON_PARENT)

	-- create a window
	--
	local ptLeft	= inConfig[1]
	local ptTop		= inConfig[2]
	local siWidth	= inConfig[3]
	local siHeight	= inConfig[4]

	local frame = wx.wxFrame(inParent, wx.wxID_ANY, "Loupe",
							 wx.wxPoint(ptLeft, ptTop),
							 wx.wxSize(siWidth, siHeight),
							 dwFrameFlags)

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
	m_App = inApp
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
	SetupFont	= SetupFont,
	SetupColour	= SetupColour,
	SetData		= SetData,
	SetNames	= SetNamesFile,
}

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
