-- ----------------------------------------------------------------------------
--
--  Mainframe
--
-- ----------------------------------------------------------------------------

local wx 		= require "wx"				-- uses wxWidgets for Lua 5.1
local trace 	= require "trace"			-- shortcut for tracing
local palette	= require "palette"		-- common colors definition in wxWidgets
local bits  	= require "bits"			-- bit manipulators

local _floor	= math.floor
local _fmt		= string.format
local _find		= string.find
local _insert	= table.insert
local _concat	= table.concat

-- ----------------------------------------------------------------------------
-- window's bag
--
local m_MainFrame = 
{
	hWindow		= nil,	-- main frame
	hMemoryDC	= nil,	-- device context for the window
	hTickTimer	= nil,	-- handle to the timer object
	hStatusBar	= nil,	-- the status bar
	hFontBytes	= nil,	-- the font for the bytes (left) pane
	hFontText	= nil,	-- the font for the text (right) pane
	
	rcClientW	= 0,		-- client rect width
	rcClientH	= 0,		-- client rect height

	iTmInterval	= 3000,	-- diplay msg on status bar for much time
	
	iCursor		= 0,		-- where the cursor is

	iByteRowCount	= 0,		-- number of visibles rows
	iByteFirstRow	= 0,		-- first row visible, left rect
	
	iTextRowCount	= 0,		-- number of visible rows
	iTextFirstRow	= 0,		-- first row visible, right rect
}

-- ----------------------------------------------------------------------------
-- default dialogs' locations
--
local tWinProp =
{
	{"Main Position",	{20,	 20}},
	{"Main Size",		{750,	265}},
}

local m_sSettingsIni = "window.ini"

-- flags in use for the main frame
--
local dwMainFlags = bits.bitoper(wx.wxDEFAULT_FRAME_STYLE,  wx.wxCAPTION,   bits.OR)
dwMainFlags       = bits.bitoper(dwMainFlags,     wx.wxCLIP_CHILDREN,       bits.OR)
dwMainFlags       = bits.bitoper(dwMainFlags,     wx.wxSYSTEM_MENU,         bits.OR)
dwMainFlags       = bits.bitoper(dwMainFlags,     wx.wxCLOSE_BOX,           bits.OR)

-- ----------------------------------------------------------------------------
--
local tFormat =
{
	["Oct"] = {"%04o ", 5},
	["Dec"] = {"%03d ", 4},
	["Hex"] = {"%02x ", 3},
}

-- ----------------------------------------------------------------------------
-- draw a vertical bar of size of 1 page
--
local function DrawVerticalBar(inDrawDC)
	if not inDrawDC then return end
	if 0 >= thisApp.iMemorySize then return end

	-- get the correct spacing here
	--
	inDrawDC:SetFont(m_MainFrame.hFontText)   
 	
	local iSpacerY = inDrawDC:GetCharHeight()	
	local iOffY 	= 10
	local iHeight	= m_MainFrame.rcClientH - iSpacerY - iOffY
	
	local iCurPage	= (m_MainFrame.iTextFirstRow / m_MainFrame.iTextRowCount)
	local iPages	= (thisApp.iNumOfRows / m_MainFrame.iTextRowCount)
	local iPageLen	= (iHeight / iPages)
	local iPosY		= 0
		
	if 0 < m_MainFrame.iTextFirstRow then
		iPosY = (iPageLen * iCurPage)
	end
		
	-- pretty align with some offset
	--
	iPosY = iPosY + iOffY
	
	-- just fix it when too small
	--
	if 10 > iPageLen then iPageLen = 10 end
	
	inDrawDC:SetPen(wx.wxPen(palette.Gray15, 2, wx.wxSOLID))
	inDrawDC:SetBrush(wx.wxBrush(palette.Moccasin, wx.wxFDIAGONAL_HATCH))
	inDrawDC:DrawRectangle(	m_MainFrame.rcClientW - 34, iPosY, 20, iPageLen)
end

-- ----------------------------------------------------------------------------
--
local function DrawFile(inDrawDC)
	if not inDrawDC then return end
	if 0 == thisApp.iMemorySize then return end
	
--	trace.line("DrawFile")

	local ch
	local sToDraw
	local iLine 	= 0
	local iIndex	= 0
	local iCursor	= m_MainFrame.iCursor
	local iNumCols	= thisApp.tConfig.Columns
	local iLimit	= thisApp.iMemorySize
	local sSource	= thisApp.sFileMemory
	local iOffX 	= 20
	local iOffY 	= 10
	local iCurX 	= iOffX
	local iCurY 	= iOffY
	local fmtStr 	= tFormat.Dec							
	
	-- format string to use (oct/dec/hex)
	-- defaults to decimal
	--
	for tag, sText in pairs(tFormat) do
		if _find(thisApp.tConfig.Format, tag, 1, true) then fmtStr = sText break end
	end

	-- foreground
	--
	inDrawDC:SetFont(m_MainFrame.hFontBytes)    	
	inDrawDC:SetTextForeground(palette.Gray15)

	-- get the correct spacing here
	--
	local iSpacerX = inDrawDC:GetTextExtent("0")
	local iSpacerY = inDrawDC:GetCharHeight()
	
	-- decide here the background color
	--
	inDrawDC:SetPen(wx.wxPen(palette.Gray30, 3, wx.wxSOLID))
	inDrawDC:SetBrush(wx.wxBrush(palette.Ivory, wx.wxSOLID))
	inDrawDC:DrawRectangle(0, 0, m_MainFrame.rcClientW, m_MainFrame.rcClientH)
	
	------------------------
	-- print all chars
	--
	local tChars = { }
	
	-- start from first visible row
	--
	iLine  = m_MainFrame.iByteFirstRow
	iIndex = iLine * iNumCols
	m_MainFrame.iByteRowCount = 0
	
	while iIndex <= iLimit do

		for i=1, iNumCols do
			
			iIndex = i + iLine * iNumCols
			if iIndex > iLimit then break end
			
			-- append bytes
			--
			ch = sSource:byte(iIndex)
			sToDraw = _fmt(fmtStr[1], ch)

			_insert(tChars, sToDraw)

			-- highlight chars
			--
			if (0x20 > ch) or (0x7f < ch) or (iIndex == iCursor) then
				
				local xPos = iCurX + ((i - 1) * iSpacerX * fmtStr[2])
				local yPos = iCurY + iSpacerY - 5
				local xLen = iSpacerX * (fmtStr[2] - 1)
				
				if 0x0a == ch then
					inDrawDC:SetPen(wx.wxPen(palette.Gray30, 3, wx.wxSOLID))
					inDrawDC:DrawLine(xPos, yPos, xPos + xLen, yPos)

				elseif 0x20 > ch then
					inDrawDC:SetPen(wx.wxPen(palette.DarkSalmon, 3, wx.wxSOLID))
					inDrawDC:DrawLine(xPos, yPos, xPos + xLen, yPos)
				
				elseif 0xc1 < ch then
					inDrawDC:SetPen(wx.wxPen(palette.Gray30, 1, wx.wxTRANSPARENT))
					inDrawDC:SetBrush(wx.wxBrush(palette.CadetBlue2, wx.wxSOLID))
					inDrawDC:DrawRectangle(xPos, iCurY, xLen, iSpacerY)

				elseif 0x7f < ch then
					inDrawDC:SetPen(wx.wxPen(palette.Gray30, 1, wx.wxTRANSPARENT))
					inDrawDC:SetBrush(wx.wxBrush(palette.DarkSalmon, wx.wxSOLID))
					inDrawDC:DrawRectangle(xPos, iCurY, xLen, iSpacerY)
				end
				
				-- draw the cursor now
				--
				if iIndex == iCursor then

					inDrawDC:SetPen(wx.wxPen(palette.Gray15, 2, wx.wxSOLID))
					inDrawDC:SetBrush(wx.wxBrush(palette.Aquamarine, wx.wxSOLID))
					inDrawDC:DrawRectangle(xPos, iCurY, xLen, iSpacerY)	
				end			

			end

		end
		
		-- draw all the line
		--
		sToDraw = _concat(tChars)
		inDrawDC:DrawText(sToDraw, iCurX, iCurY)
		tChars = { }
		
		-- check if we are writing off the client area
		--
		iCurY = iCurY + iSpacerY
		
		if (m_MainFrame.rcClientH - iOffY - iSpacerY) <= iCurY then break end

		iLine = iLine + 1
		
		-- update the number of visible rows
		--
		m_MainFrame.iByteRowCount = m_MainFrame.iByteRowCount + 1
	end
	
	-- -----------------------------------------------
	-- this is the right part with the text formatting
	--
	iCurX = iOffX + iNumCols * iSpacerX * fmtStr[2]
	
	-- get the correct spacing here
	--
	inDrawDC:SetFont(m_MainFrame.hFontText)    	
	
	iSpacerX = inDrawDC:GetTextExtent("0")
	iSpacerY = inDrawDC:GetCharHeight()

	-- decide here the background color
	--
	inDrawDC:SetPen(wx.wxPen(palette.Gray55, 3, wx.wxSOLID))
	inDrawDC:SetBrush(wx.wxBrush(palette.Gray15, wx.wxSOLID))
	inDrawDC:DrawRectangle(iCurX, 0, m_MainFrame.rcClientW, m_MainFrame.rcClientH)

	-- check which line will be the first
	--	
	local iNumLines 	= 0
	local iStopLine 	= -1
	local iStopOffset = -1
	local iStopLength	= 0
	local iFirstRow	= 0
	
	-- hook for possible further spacing
	--
--	iCurX = iCurX + iOffX
	iCurY = iOffY
	
	-- perform a progressive scan of memory for newlines
	--
	local iCntPrev = 0
	local iCntNew	= 0
	local iStart 	= 1
	local iEnd	 	= sSource:find("\n", iStart, true)
	
	while iEnd do
		
		-- understand if the cursor is in the current line
		--
		iCntNew = iCntPrev + (iEnd - iStart + 1)		
		if iCntPrev < iCursor and iCursor <= iCntNew then
			iStopLine	= iNumLines
	
			-- get the underline to work properly when the cursor
			-- is in one of the 2 bytes of the pair
			--
			local ch			= sSource:sub(iCursor, iCursor)
			local iToByte = ch:byte()
			
			if (iCursor < iLimit) and (0xc2 <= iToByte) then
				ch =  sSource:sub(iCursor, iCursor + 1)
			
				iStopOffset = inDrawDC:GetTextExtent(sSource:sub(iStart, iCursor - 1))	
				
			elseif (iCursor > 1) and (0x80 <= iToByte and 0xbf >= iToByte) then
				
				ch =  sSource:sub(iCursor - 1, iCursor)
				
				iStopOffset = inDrawDC:GetTextExtent(sSource:sub(iStart, iCursor - 2))
				
			else
				
				iStopOffset = inDrawDC:GetTextExtent(sSource:sub(iStart, iCursor - 1))
			end
			
			-- here ch might be a duouble byte sequence
			--
			iStopLength = inDrawDC:GetTextExtent(ch)

			break
		end
		iCntPrev = iCntNew
			
		iNumLines = iNumLines + 1
		
		iStart = iEnd + 1
		iEnd	 = sSource:find("\n", iStart, true)
	end
	
	-- get the number of rows * font height and
	-- correct the y offset
	--
	local iLowLimit= m_MainFrame.rcClientH - iSpacerY * 2		-- drawing bottom bound
	local iNumRows = _floor(iLowLimit / iSpacerY)				-- allowed rows
	iOffY = ((iLowLimit - (iSpacerY * iNumRows)) / 2)			-- vertical offset
	
	-- align indexes for the line currently highlighted
	-- (basically a list view)
	--
	iFirstRow = m_MainFrame.iTextFirstRow
	if iFirstRow > iStopLine then iFirstRow = iStopLine end
	if iStopLine > (iFirstRow + iNumRows) then iFirstRow = (iStopLine - iNumRows) end
	if 0 > iFirstRow then iFirstRow = 0 end
	
	m_MainFrame.iTextFirstRow = iFirstRow	
	m_MainFrame.iTextRowCount = iNumRows
	
	------------------
	-- print all chars
	--
	local iCurLine = 0

	-- restart the same process as before
	-- but print text this time
	--
	iCurX = iCurX + iOffX
	iCurY = iOffY
	
	iStart 	= 1
	iEnd	 	= sSource:find("\n", iStart, true)
		
	while iEnd do
	
		-- find the correct sequence of lines
		--
		if iCurLine >= iFirstRow then

			-- check for the highlight
			-- 
			if iCurLine == iStopLine then
				inDrawDC:SetTextForeground(palette.Salmon1)
			else
				inDrawDC:SetTextForeground(palette.Gray55)
			end

			-- do the draw
			--
			sToDraw = sSource:sub(iStart, iEnd)			
--			sToDraw = sToDraw:gsub("\t", "    ")
			
			inDrawDC:DrawText(sToDraw, iCurX, iCurY)
			iCurY = iCurY + iSpacerY
		
			if iLowLimit <= iCurY then break end
		end

		iCurLine = iCurLine + 1

		iStart = iEnd + 1
		iEnd	 = sSource:find("\n", iStart, true)
	end
	
	-- underline the corresponding letter for the cursor
	--
	if 0 <= iStopOffset then
		
		local pStartX = iCurX + iStopOffset
		local pStartY = iOffY + (iStopLine - iFirstRow) * iSpacerY + iSpacerY
		local pEndX = pStartX + iStopLength
		local pEndY = pStartY

		inDrawDC:SetPen(wx.wxPen(palette.DarkSeaGreen, 5, wx.wxSOLID))
		inDrawDC:DrawLine(pStartX, pStartY, pEndX, pEndY)		
	end

end

-- ----------------------------------------------------------------------------
-- cell number starts at 1, using the Lua convention
-- using the second cell as default position
--
local function SetStatusText(inText, inCellNo)
	local hCtrl = m_MainFrame.hStatusBar	
	if not hCtrl then return end
	
--	trace.line("SetStatusText")

	inText	= inText or ""
	inCellNo = inCellNo or 2
	
	inCellNo = inCellNo - 1
	if 0 > inCellNo or 2 < inCellNo then inCellNo = 1 end
	
	hCtrl:SetStatusText(inText, inCellNo)
	
	-- start a one-shot timer
	--	
	if 1 == inCellNo and 0 < #inText then m_MainFrame.hTickTimer:Start(m_MainFrame.iTmInterval, true) end
end

-- ----------------------------------------------------------------------------
-- read dialogs' settings from settings file
--
local function ReadSettings()
	
--	trace.line("ReadSettings")
	
	local fd = io.open(m_sSettingsIni, "r")
	if not fd then return end

	fd:close()

	local settings = dofile(m_sSettingsIni)

	if settings then tWinProp = settings end
end

-- ----------------------------------------------------------------------------
-- do recurse the object's structure
-- wants a valid file's descriptor and the actual object
--
local function Serialize(inFD, inObject)
  
	if type(inObject) == "number" then
		inFD:write(inObject)

	elseif type(inObject) == "string" then
		inFD:write(string.format("%q", inObject))

	elseif type(inObject) == "table" then    
		
		inFD:write("{ ")
		
		local test = false
		for k,v in pairs(inObject) do

	--      inFD:write("  [")
	--      Serialize(inFD, k)      --  recurse key
	--      inFD:write("] = ")

			if test then inFD:write(", ")  end
			
			Serialize(inFD, v)      --  recurse value      
			test = true
		end

		inFD:write(" }\n")
	else

		error("Cannot serialize a " .. type(inObject))
	
	end
	
end

-- ----------------------------------------------------------------------------
-- save a table to the settings file
--
local function SaveSettings(inFilename, inTable)
  
--	trace.line("SaveSettings")
  
	local fd = io.open(inFilename, "w")
	if not fd then return end

	fd:write("local ls = ")
	Serialize(fd, inTable)
	fd:write(" return ls")
	io.close(fd)
  
end

-- ----------------------------------------------------------------------------
--
local function UpdateXYPos(inRow, inWxPoint)
  
	if #tWinProp >= inRow then
		local pos = tWinProp[inRow][2]

		pos[1] = inWxPoint:GetX()
		pos[2] = inWxPoint:GetY()
	end
  
end

-- ----------------------------------------------------------------------------
-- Generate a unique new wxWindowID
--
local ID_IDCOUNTER = wx.wxID_HIGHEST + 1
local NewMenuID = function()
	
	ID_IDCOUNTER = ID_IDCOUNTER + 1
	return ID_IDCOUNTER
  
end

-- ----------------------------------------------------------------------------
-- Simple interface to pop up a message
--
local function DlgMessage(message)
	wx.wxMessageBox(message, thisApp.sAppName,
						 wx.wxOK + wx.wxICON_INFORMATION, m_MainFrame.hWindow)  
end

-- ----------------------------------------------------------------------------
--
local function OnAbout(event)
	
	wx.wxMessageBox(thisApp.sAppName .. " [" .. thisApp.sAppVersion .. "]\n" ..
						 wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING,
						 thisApp.sAppName, wx.wxOK + wx.wxICON_INFORMATION, m_MainFrame.hWindow) 
end

-- ----------------------------------------------------------------------------
--
local function OnClose(event)
	if not m_MainFrame.hWindow then return end
	
--	trace.line("OnClose")

	wx.wxGetApp():Disconnect(wx.wxEVT_TIMER)
	 
	-- need to convert from size to pos
	--
	local size = m_MainFrame.hWindow:GetSize()

	UpdateXYPos(1, m_MainFrame.hWindow:GetPosition())
	UpdateXYPos(2, wx.wxPoint(size:GetWidth(), size:GetHeight()))

	m_MainFrame.hWindow.Destroy(m_MainFrame.hWindow)
	m_MainFrame.hWindow = nil
end

-- wxPaintDC				-- drawing to the screen, during EVT_PAINT
-- wxClientDC				-- drawing to the screen, outside EVT_PAINT
-- wxBufferedPaintDC		-- drawing to a buffer, then the screen, during EVT_PAINT
-- wxBufferedDC			-- drawing to a buffer, then the screen, outside EVT_PAINT
-- wxMemoryDC				-- drawing to a bitmap

-- ----------------------------------------------------------------------------
-- we just splat the off screen dc over the current dc
--
local function OnPaint(event)  
	if not m_MainFrame.hWindow then return end
	
--	trace.line("OnPaint")

	local dc     = wx.wxPaintDC(m_MainFrame.hWindow)
	local rcSize = m_MainFrame.hWindow:GetClientSize()

	if m_MainFrame.hMemoryDC then
		dc:Blit(0, 0, rcSize:GetWidth(), rcSize:GetHeight(), m_MainFrame.hMemoryDC, 0, 0, wx.wxCOPY)
	end

	dc:delete()
end
-- ----------------------------------------------------------------------------
--
local function NewMemDC()  
	if not m_MainFrame.hWindow then return end
	
--	trace.line("NewMemDC")
	 
	-- create a bitmap wide as the client area
	--
	local memDC  = wx.wxBufferedDC()
 	local bitmap = wx.wxBitmap(m_MainFrame.rcClientW, m_MainFrame.rcClientH)
	memDC:SelectObject(bitmap)
	
	-- if file is open then handle the draw
	--
	DrawFile(memDC)
	DrawVerticalBar(memDC)

	return memDC
end

-- ----------------------------------------------------------------------------
--
local function Refresh()
	if not m_MainFrame.hWindow then return end
	
--	trace.line("Refresh")

	if m_MainFrame.hMemoryDC then
		m_MainFrame.hMemoryDC:delete()
		m_MainFrame.hMemoryDC = nil
	end

	m_MainFrame.hMemoryDC = NewMemDC()
	m_MainFrame.hWindow:Refresh()   
end

-- ----------------------------------------------------------------------------
--
local function OnReadFile(event)
--	trace.line("OnReadFile")
	
	-- reset the cursor position
	--
	m_MainFrame.iCursor			= 1
	m_MainFrame.iByteFirstRow	= 0
	m_MainFrame.iByteRowCount	= 0
	m_MainFrame.iTextFirstRow	= 0
	m_MainFrame.iTextRowCount	= 0
	
	local iBytes, sText = thisApp.LoadFile()
	if 0 == iBytes then m_MainFrame.iCursor = 0 end
		
	SetStatusText("" .. m_MainFrame.iCursor, 3)
	SetStatusText(sText, 2)
	
	Refresh()
end

-- ----------------------------------------------------------------------------
--
local function OnCheckEncoding(event)
--	trace.line("OnCheckEncoding")

	local r, sText = thisApp.CheckEncoding()
	
	SetStatusText(sText, 2)
end

-- ----------------------------------------------------------------------------
--
local function OnEncode_UTF_8(event)
--	trace.line("OnEncode_UTF_8")

	local r, sText = thisApp.Encode_UTF_8()
	
	SetStatusText(sText, 2)
end

-- ----------------------------------------------------------------------------
--
local function OnCreateFile(event)
--	trace.line("OnCreateFile")
	
	local iLines = thisApp.CreateTest()
	
	SetStatusText("" .. iLines .. " lines written", 2)
end

-- ----------------------------------------------------------------------------
-- align view of file based on the current cursor position
--
local function AlignBytesToCursor(inNewValue)
	
	local iNumCols		= thisApp.tConfig.Columns
	local iLimit		= thisApp.iMemorySize
	local iNumRows		= m_MainFrame.iByteRowCount
	local iFirstRow	= m_MainFrame.iByteFirstRow

	if 0 >= inNewValue then inNewValue = 1 end
	if iLimit < inNewValue then inNewValue = iLimit end

	local iTopLine = _floor((inNewValue - 1) / iNumCols)

	if iFirstRow < (iTopLine - iNumRows) then iFirstRow = (iTopLine - iNumRows) end
	if iFirstRow > iTopLine then iFirstRow = iTopLine end
		
	m_MainFrame.iCursor			= inNewValue
	m_MainFrame.iByteFirstRow	= iFirstRow
	
	SetStatusText("" .. inNewValue, 3)
end

-- ----------------------------------------------------------------------------
-- handle the mouse left button click
--
local function OnLeftBtnDown(event)
	if 0 >= thisApp.iMemorySize then return end
	
--	trace.line("OnLeftBtnDown")

end

-- ----------------------------------------------------------------------------
-- handle the mouse left button click
--
local function OnLeftBtnUp(event)
	if 0 >= thisApp.iMemorySize then return end

--	trace.line("OnLeftBtnUp")

end

-- ----------------------------------------------------------------------------
-- handle the mouse wheel
--
local function OnMouseWheel(event)
	if 0 >= thisApp.iMemorySize then return end
	
--	trace.line("OnMouseWheel")
	
	local iCurrent	= m_MainFrame.iCursor
	local iNumCols	= thisApp.tConfig.Columns
	local iLines	= event:GetLinesPerAction()
	local iScroll	= iNumCols * iLines

	-- works reversed
	--
	if 0 < event:GetWheelRotation() then iScroll = -1 * iScroll end
	
	AlignBytesToCursor(iCurrent + iScroll)
	
	Refresh()
end

-- ----------------------------------------------------------------------------
--
local function OnKeyDown(event)
	if 0 >= thisApp.iMemorySize then return end
	
--	trace.line("OnKeyDown")	
	
	local iCursor	= m_MainFrame.iCursor
	local iNumCols	= thisApp.tConfig.Columns
	local iPgJump	= _floor((iNumCols * m_MainFrame.iByteRowCount) / 2)
	
	local key = event:GetKeyCode()

	if wx.WXK_LEFT == key then
		iCursor = iCursor - 1

	elseif wx.WXK_RIGHT == key then
		iCursor = iCursor + 1

	elseif wx.WXK_UP == key then
		iCursor = iCursor - iNumCols

	elseif wx.WXK_DOWN == key then
		iCursor = iCursor + iNumCols

	elseif wx.WXK_PAGEDOWN == key then
		iCursor = iCursor + iPgJump

	elseif wx.WXK_PAGEUP == key then
		iCursor = iCursor - iPgJump

	elseif wx.WXK_HOME == key then
		iCursor = 1

	elseif wx.WXK_END == key then
		iCursor = thisApp.iMemorySize

	else
		return
	end
	
	AlignBytesToCursor(iCursor)

	Refresh()
end

-- ----------------------------------------------------------------------------
--
local function OnTimer(event)
	if not m_MainFrame.hWindow then return end 

	-- cleanup the status bar
	--
	SetStatusText(nil, 2)

end

-- ----------------------------------------------------------------------------
--
--
local function OnSize(event)
	if not m_MainFrame.hWindow then return end
	if not m_MainFrame.hStatusBar then return end

	--	trace.line("OnSize")

	local size = event:GetSize()

	m_MainFrame.rcClientW = size:GetWidth()
	m_MainFrame.rcClientH = size:GetHeight() - 80	-- subtract the status bar height

	m_MainFrame.hStatusBar:SetStatusWidths({150, m_MainFrame.rcClientW - 150 - 100, 100})
	
	-- regenerate the offscreen buffer
	--
	Refresh()
end

-- ----------------------------------------------------------------------------
-- allocate the fonts
--
local function SetupFonts()
	
	-- font properties read from the config file
	--
	local specBytes = thisApp.tConfig.ByteFont
	local specText  = thisApp.tConfig.TextFont
	
	-- allocate
	--
	local fBytes = wx.wxFont(specBytes[1], wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL,
									 wx.wxFONTWEIGHT_NORMAL, false, specBytes[2])
					
	local fText  = wx.wxFont(specText[1], wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL,
									 wx.wxFONTWEIGHT_NORMAL, false, specText[2])
		
	-- setup
	--
	m_MainFrame.hFontBytes	= fBytes
	m_MainFrame.hFontText	= fText

	return (fBytes and fText)
end

-- ----------------------------------------------------------------------------
-- create the main window
--
local function CreateMainWindow()

	-- read deafult positions for the dialogs
	--
	ReadSettings()
  
	-- unique IDs for the menu
	--  
	local rcMnuReadFile = NewMenuID()
	local rcMnuTestFile = NewMenuID()
	local rcMnuCheckFmt = NewMenuID()
	local rcMnuEnc_UTF_8= NewMenuID()
	
	-- create a window
	--
	local pos  = tWinProp[1][2]
	local size = tWinProp[2][2]

	local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, thisApp.sAppName,
									 wx.wxPoint(pos[1], pos[2]), wx.wxSize(size[1], size[2]),
									 dwMainFlags)

	-- create the FILE menu
	--
	local mnuFile = wx.wxMenu("", wx.wxMENU_TEAROFF)
	mnuFile:Append(rcMnuReadFile,		"Import File\tCtrl-L",	"Read the file in memory")
	mnuFile:Append(rcMnuEnc_UTF_8,	"Encode UTF_8",			"Overwrite file with new encoding")
	mnuFile:Append(wx.wxID_EXIT,		"E&xit\tAlt-X",			"Quit the program")

	-- create the COMMANDS menu
	--
	local mnuCmds = wx.wxMenu("", wx.wxMENU_TEAROFF)
	mnuCmds:Append(rcMnuCheckFmt,		"Check Format\tCtrl-F",	"Check bytes in current file")
	mnuCmds:Append(rcMnuTestFile,		"Create File\tCtrl-T",	"Create a binary test file")

	-- create the HELP menu
	--
	local mnuHelp = wx.wxMenu("", wx.wxMENU_TEAROFF)  
	mnuHelp:Append(wx.wxID_ABOUT,     "&About\tAlt-A",			"About Application")

	-- create the menu bar and associate sub-menus
	--
	local mnuBar
	mnuBar = wx.wxMenuBar()  
	mnuBar:Append(mnuFile,	"&File")
	mnuBar:Append(mnuCmds,	"&Commands")
	mnuBar:Append(mnuHelp,	"&Help")

	frame:SetMenuBar(mnuBar)

	-- create the bottom status bar
	--
	local hStatusBar	
	hStatusBar = frame:CreateStatusBar(3, wx.wxST_SIZEGRIP)
	hStatusBar:SetFont(wx.wxFont(10, wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL))      
	hStatusBar:SetStatusWidths({150, 750, 100}); 

	-- standard event handlers
	--
	frame:Connect(wx.wxEVT_PAINT,			OnPaint)
	frame:Connect(wx.wxEVT_TIMER,			OnTimer)
	frame:Connect(wx.wxEVT_SIZE,			OnSize)
	frame:Connect(wx.wxEVT_KEY_DOWN,		OnKeyDown)
	frame:Connect(wx.wxEVT_LEFT_UP,		OnLeftBtnUp)
	frame:Connect(wx.wxEVT_LEFT_DOWN,	OnLeftBtnDown)
	frame:Connect(wx.wxEVT_MOUSEWHEEL,	OnMouseWheel)	
	frame:Connect(wx.wxEVT_CLOSE_WINDOW,OnClose)
      
	-- menu event handlers
	--
	frame:Connect(rcMnuReadFile,	wx.wxEVT_COMMAND_MENU_SELECTED,	OnReadFile)
	frame:Connect(rcMnuTestFile,	wx.wxEVT_COMMAND_MENU_SELECTED,	OnCreateFile)
	frame:Connect(rcMnuCheckFmt,	wx.wxEVT_COMMAND_MENU_SELECTED,	OnCheckEncoding)
	
	frame:Connect(rcMnuEnc_UTF_8,	wx.wxEVT_COMMAND_MENU_SELECTED,	OnEncode_UTF_8)
	
	frame:Connect(wx.wxID_EXIT,	wx.wxEVT_COMMAND_MENU_SELECTED,   OnClose)
	frame:Connect(wx.wxID_ABOUT,	wx.wxEVT_COMMAND_MENU_SELECTED,   OnAbout)
  
	-- set up the frame
	--
	frame:SetMinSize(wx.wxSize(600, 250))  
	frame:SetStatusBarPane(1)                   -- this is reserved for the menu
	
	-- this is necessary to avoid flickering
	-- (comment the line if running with the debugger)
	--
	frame:SetBackgroundStyle(wx.wxBG_STYLE_CUSTOM)
	
	--  store for later
	--
	m_MainFrame.hWindow 		= frame	
	m_MainFrame.hStatusBar	= hStatusBar
	m_MainFrame.hMemoryDC	= NewMemDC()
	
	return frame
end

-- ----------------------------------------------------------------------------
-- show the main window and runs the main loop
--
function ShowMainWindow()
--	trace.line("ShowMainWindow")
	
	if m_MainFrame.hWindow then return false end
	
	-- create a new window
	--
	if not CreateMainWindow() then return false end
	
	-- pre-allocate the necessary fonts
	--
	if not SetupFonts() then return false end
	
	-- display
	--
	m_MainFrame.hWindow:Show(true)
	
	-- create a timer object
	--
	m_MainFrame.hTickTimer = wx.wxTimer(m_MainFrame.hWindow, wx.wxID_ANY)

	-- display the release
	--
	SetStatusText(thisApp.sAppName .. " [" .. thisApp.sAppVersion .. "]", 1)
	  
	-- run the main loop
	--
	wx.wxGetApp():MainLoop()	
end

-- ----------------------------------------------------------------------------
--
function CloseMainWindow()
--	trace.line("CloseMainWindow")
	
	SaveSettings(m_sSettingsIni, tWinProp) 
	
  if m_MainFrame.hWindow then OnClose() end
  
end

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
