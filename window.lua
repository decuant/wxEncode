-- ----------------------------------------------------------------------------
--
--  Mainframe
--
-- ----------------------------------------------------------------------------

local wx 		= require "wx"			-- uses wxWidgets for Lua 5.1
local palette	= require "palette"		-- common colors definition in wxWidgets
local bits  	= require "bits"		-- bit manipulators
local trace 	= require "trace"		-- shortcut for tracing

local _floor	= math.floor
local _format	= string.format
local _find		= string.find
local _insert	= table.insert
local _concat	= table.concat

-- ----------------------------------------------------------------------------
-- status bar panes width
--
local tStbarWidths =
{
	200, 			-- application
	750, 			-- message
	100,			-- file check format
	75,				-- current line
	100,			-- cursor position
}

-- ----------------------------------------------------------------------------
--
local tFormat =
{
	["Oct"] = {"%04o ", 5},
	["Dec"] = {"%03d ", 4},
	["Hex"] = {"%02x ", 3},
}

-- ----------------------------------------------------------------------------
-- window's bag
--
local m_MainFrame = 
{
	hWindow		= nil,		-- main frame
	hMemoryDC	= nil,		-- device context for the window
	hTickTimer	= nil,		-- handle to the timer object
	hStatusBar	= nil,		-- the status bar
	hFontBytes	= nil,		-- the font for the bytes (left) pane
	hFontText	= nil,		-- the font for the text (right) pane
	
	rcClientW		= 0,	-- client rect width
	rcClientH		= 0,	-- client rect height

	iTmInterval		= 3000,	-- diplay msg on status bar for much time
	
	iCursor			= 0,	-- where the cursor is
	tFormatBytes	= nil,	-- format string for the bytes display
	iByteRowCount	= 0,	-- number of visibles rows
	iByteFirstRow	= 0,	-- first row visible, left rect
	
	iTextRowCount	= 0,	-- number of visible rows
	iTextFirstRow	= 0,	-- first row visible, right rect
	iStopLine		= -1,	-- line where the cursor is in
	iStopStart		= 0,	-- byte offset of stopline in buffer
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
-- draw a vertical bar of size of 1 page
--
local function DrawVerticalBar(inDrawDC)
--	trace.line("DrawVerticalBar")
	
	if not inDrawDC then return end
	if 0 >= thisApp.iMemorySize then return end
	if not m_MainFrame.hFontText then return end

	-- get the correct spacing here
	--
	inDrawDC:SetFont(m_MainFrame.hFontText)   
 	
	local iSpacerY = inDrawDC:GetCharHeight()	
	local iOffY 	= 10
	local iHeight	= m_MainFrame.rcClientH - iSpacerY - iOffY
	
	local iCurPage	= (m_MainFrame.iTextFirstRow / m_MainFrame.iTextRowCount)
	local iPages	= (thisApp.iNumOfRows / m_MainFrame.iTextRowCount)
	local iPageLen	= (iHeight / iPages)
	local iPosY		= (iPageLen * iCurPage) + iOffY
			
	-- just fix it when too small
	--
	if 10 > iPageLen then iPageLen = 25 end
	
	inDrawDC:SetPen(wx.wxPen(palette.Gray15, 2, wx.wxSOLID))
	inDrawDC:SetBrush(wx.wxBrush(palette.Moccasin, wx.wxFDIAGONAL_HATCH))
	inDrawDC:DrawRectangle(m_MainFrame.rcClientW - 34, iPosY, 20, iPageLen)
end

-- ----------------------------------------------------------------------------
-- draw highlight for each even column
--
local function DrawColumns(inDrawDC)
--	trace.line("DrawColumns")
	
	if not inDrawDC then return end
	if 0 >= thisApp.iMemorySize then return end
	if not m_MainFrame.hFontBytes then return end
	
	local iOffX 	= 20
	local iOffY 	= 10
	local iCurX		= iOffX
	local iColumns	= thisApp.tConfig.Columns
	
	-- get the correct spacing here
	--
	inDrawDC:SetFont(m_MainFrame.hFontBytes)   
 	
	local sTest		= _format(m_MainFrame.tFormatBytes[1], 0)
	local iSpacerX	= inDrawDC:GetTextExtent(sTest)
	local iSpacerY	= inDrawDC:GetCharHeight()	
	local iHeight	= m_MainFrame.rcClientH - iSpacerY - iOffY * 2
	
	inDrawDC:SetPen(wx.wxPen(palette.Gray15, 1, wx.wxTRANSPARENT))
	inDrawDC:SetBrush(wx.wxBrush(palette.Seashell2, wx.wxSOLID))

	-- center the highlight on the number of chars written (hex/dec/oct)
	--
	iCurX = iCurX - (iSpacerX / (m_MainFrame.tFormatBytes[2] * 2)) + iSpacerX
	
	while iColumns > 0 do
		
		inDrawDC:DrawRectangle(iCurX, iOffY, iSpacerX, iHeight)
		
		iCurX = iCurX + iSpacerX * 2
		
		iColumns = iColumns - 2
	end
	
end

-- ----------------------------------------------------------------------------
--
local function DrawFile(inDrawDC)
	--	trace.line("DrawFile")
	
	if not inDrawDC then return end
	if 0 == thisApp.iMemorySize then return end
	if not m_MainFrame.hFontBytes then return end

	local ch
	local sToDraw
	local iLine 	= 0
	local iIndex	= 0
	local iCursor	= m_MainFrame.iCursor
	local iNumCols	= thisApp.tConfig.Columns
	local iTabSize	= thisApp.tConfig.TabSize
	local iLimit	= thisApp.iMemorySize
	local sSource	= thisApp.sFileMemory
	local iOffX 	= 20
	local iOffY 	= 10
	local iCurX 	= iOffX
	local iCurY 	= iOffY
	local tFmtBytes	= m_MainFrame.tFormatBytes			-- format table to use (hex/dec/oct)
	local bUnderline = thisApp.tConfig.Underline		-- underline bytes below 0x20
	local bUnicode	= thisApp.tConfig.ColorCodes		-- highlight Unicode codes

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
	local iRectW = iOffX + iNumCols * tFmtBytes[2] * iSpacerX
	local iRectH = m_MainFrame.rcClientH - iOffY * 2 - iSpacerY
		
	inDrawDC:SetPen(wx.wxPen(palette.Gray30, 1, wx.wxTRANSPARENT))
	inDrawDC:SetBrush(wx.wxBrush(palette.Snow1, wx.wxSOLID))
	inDrawDC:DrawRectangle(0, 0, iRectW, m_MainFrame.rcClientH)

	
	-- draw the colums' on/off color
	--
	DrawColumns(inDrawDC)
	
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
			sToDraw = _format(tFmtBytes[1], ch)

			_insert(tChars, sToDraw)

			-- highlight chars
			--				
			if (0x20 > ch) or (0x7f < ch) or (iIndex == iCursor) then
				
				local xPos = iCurX + ((i - 1) * iSpacerX * tFmtBytes[2])
				local yPos = iCurY + iSpacerY - 5
				local xLen = iSpacerX * (tFmtBytes[2] - 1)
				
				if bUnderline then
					if 0x0a == ch then
						inDrawDC:SetPen(wx.wxPen(palette.Gray30, 2, wx.wxSOLID))
						inDrawDC:DrawLine(xPos, yPos, xPos + xLen, yPos)

					elseif 0x20 > ch then
						inDrawDC:SetPen(wx.wxPen(palette.Magenta, 4, wx.wxSOLID))
						inDrawDC:DrawLine(xPos, yPos, xPos + xLen, yPos)
					end
				end

				if bUnicode then
					if 0xbf < ch then
						inDrawDC:SetPen(wx.wxPen(palette.Gray30, 1, wx.wxTRANSPARENT))
						inDrawDC:SetBrush(wx.wxBrush(palette.CadetBlue2, wx.wxSOLID))
						inDrawDC:DrawRectangle(xPos, iCurY, xLen, iSpacerY)

					elseif 0x7f < ch then
						inDrawDC:SetPen(wx.wxPen(palette.Gray30, 1, wx.wxTRANSPARENT))
						inDrawDC:SetBrush(wx.wxBrush(palette.DarkSalmon, wx.wxSOLID))
						inDrawDC:DrawRectangle(xPos, iCurY, xLen, iSpacerY)
					end
				end

				-- draw the cursor now
				--
				if iIndex == iCursor then

					inDrawDC:SetPen(wx.wxPen(palette.Gray15, 2, wx.wxSOLID))
					inDrawDC:SetBrush(wx.wxBrush(palette.DarkSeaGreen2, wx.wxSOLID))
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
		
		if iRectH < iCurY then break end

		iLine = iLine + 1
		
		-- update the number of visible rows
		--
		m_MainFrame.iByteRowCount = m_MainFrame.iByteRowCount + 1
	end
	
	-- -----------------------------------------------
	-- this is the right part with the text formatting
	--
	
	-- get the correct spacing here
	--
	inDrawDC:SetFont(m_MainFrame.hFontText)    	
	
	iSpacerX = inDrawDC:GetTextExtent("0")
	iSpacerY = inDrawDC:GetCharHeight()
	
	iCurX	= iOffX + iNumCols * iSpacerX * tFmtBytes[2]
	iRectW	= m_MainFrame.rcClientW - iCurX
	iRectH	= m_MainFrame.rcClientH - iOffY - iSpacerY
	
	-- decide here the background color
	--
	inDrawDC:SetPen(wx.wxPen(palette.Gray30, 1, wx.wxTRANSPARENT))	
	inDrawDC:SetBrush(wx.wxBrush(palette.Gray15, wx.wxSOLID))
	inDrawDC:DrawRectangle(iCurX, 0, iRectW, m_MainFrame.rcClientH)

	-- check which line will be the first
	--	
	local iNumLines 	= 0
	local iStopLine		= -1
	local iStopStart	= 0
	local iStopOffset	= -1
	local iStopLength	= 0
	local iFirstRow		= 0
	
	-- hook for possible further spacing
	--
--	iCurX = iCurX + iOffX
	iCurY = iOffY
	
	-- perform a progressive scan of memory for newlines
	--
	local sTabRep	= string.rep(" ", iTabSize)
	local iCntPrev	= 0
	local iCntNew	= 0
	local iStart 	= 1
	local iEnd	 	= sSource:find("\n", iStart, true)
	
	while iEnd do
		
		-- understand if the cursor is in the current line
		--
		iCntNew = iCntPrev + (iEnd - iStart + 1)		
		if iCntPrev < iCursor and iCursor <= iCntNew then
			
			iStopLine	= iNumLines
			iStopStart	= iStart 
			
			-- here the trick to handle tab(s) conversion to spaces
			--
			local sExtract  = sSource:sub(iStart, iCursor)
			local iExtEnd	= iCursor - iStart + 1
			local iNumSubs	
			
			sExtract, iNumSubs = sExtract:gsub("\t", sTabRep)
			
			iExtEnd = iExtEnd + iNumSubs * iTabSize - iNumSubs
			
			-- get 2 more bytes to check for a Unicode value
			--
			sExtract  = sSource:sub(iStart, iCursor + 2):gsub("\t", sTabRep)
			
			-- get the underline to work properly when the cursor
			-- is in one of the 2 bytes of the pair
			--
			local ch		= sExtract:sub(iExtEnd, iExtEnd)
			local iToByte	= ch:byte()
			
			if (iExtEnd < #sExtract) and (0xc0 < iToByte) then
				
				if 0xdf < iToByte then
					ch =  sExtract:sub(iExtEnd, iExtEnd + 2)
				else
					ch =  sExtract:sub(iExtEnd, iExtEnd + 1)
				end
							
				iStopOffset = inDrawDC:GetTextExtent(sExtract:sub(1, iExtEnd - 1))	
				
			elseif (iExtEnd > 1) and (0x7f < iToByte and 0xc0 > iToByte) then
				
				ch =  sExtract:sub(iExtEnd - 1, iExtEnd)
				
				iStopOffset = inDrawDC:GetTextExtent(sExtract:sub(1, iExtEnd - 2))
				
			else
				
				iStopOffset = inDrawDC:GetTextExtent(sExtract:sub(1, iExtEnd - 1))
			end
			
			-- here ch might be a double byte sequence
			--
			iStopLength = inDrawDC:GetTextExtent(ch)

			break
		end
		iCntPrev = iCntNew
			
		iNumLines = iNumLines + 1
		
		iStart	= iEnd + 1
		iEnd	= sSource:find("\n", iStart, true)
		
		-- last check because a line might not be completed with a lf
		--
		if not iEnd and iStart < iLimit then iEnd = iLimit end
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
	m_MainFrame.iStopLine	  = iStopLine + 1
	m_MainFrame.iStopStart 	  = iStopStart
	
	------------------
	-- print all chars
	--
	local iCurLine = 0

	-- restart the same process as before
	-- but print text this time
	--
	inDrawDC:SetTextForeground(palette.Gray55)
					
	iCurX = iCurX + iOffX
	iCurY = iOffY
	
	iStart	= 1
	iEnd	= sSource:find("\n", iStart, true)
		
	while iEnd do
	
		-- find the correct sequence of lines
		--
		if iCurLine >= iFirstRow then

			-- check for the highlight
			-- 
			if iCurLine == iStopLine then inDrawDC:SetTextForeground(palette.Salmon1) end

			-- do the draw
			--
			sToDraw = sSource:sub(iStart, iEnd)			
			sToDraw = sToDraw:gsub("\t", sTabRep)
			
			inDrawDC:DrawText(sToDraw, iCurX, iCurY)
			iCurY = iCurY + iSpacerY
		
			if iLowLimit <= iCurY then break end
			
			-- restore
			--
			if iCurLine == iStopLine then inDrawDC:SetTextForeground(palette.Gray55) end			
		end

		iCurLine = iCurLine + 1

		iStart	= iEnd + 1
		iEnd	= sSource:find("\n", iStart, true)
		
		if not iEnd and iStart < iLimit then iEnd = iLimit end
	end
	
	-- underline the corresponding letter for the cursor
	--
	if 0 <= iStopOffset then
		
		local pStartX	= iCurX + iStopOffset
		local pStartY	= iOffY + (iStopLine - iFirstRow) * iSpacerY + iSpacerY
		local pEndX		= pStartX + iStopLength
		local pEndY		= pStartY

		inDrawDC:SetPen(wx.wxPen(palette.DarkSeaGreen, 5, wx.wxSOLID))
		inDrawDC:DrawLine(pStartX, pStartY, pEndX, pEndY)		
	end
end

-- ----------------------------------------------------------------------------
-- cell number starts at 1, using the Lua convention
-- using the second cell as default position
--
local function SetStatusText(inText, inCellNo)
--	trace.line("SetStatusText")
	
	local hCtrl = m_MainFrame.hStatusBar	
	if not hCtrl then return end

	inText	 = inText or ""
	inCellNo = inCellNo or 2
	
	inCellNo = inCellNo - 1
	if 0 > inCellNo or #tStbarWidths < inCellNo then inCellNo = 2 end
	
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
		for _, v in pairs(inObject) do

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
local iRCEntry = wx.wxID_HIGHEST + 1

local function UniqueID()
	
	iRCEntry = iRCEntry + 1
	return iRCEntry
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

	DlgMessage(thisApp.sAppName .. " [" .. thisApp.sAppVersion .. "]\n" ..
				wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING)
end

-- ----------------------------------------------------------------------------
--
local function OnClose(event)
--	trace.line("OnClose")
	
	if not m_MainFrame.hWindow then return end

	wx.wxGetApp():Disconnect(wx.wxEVT_TIMER)
	 
	-- need to convert from size to pos
	--
	local size = m_MainFrame.hWindow:GetSize()

	UpdateXYPos(1, m_MainFrame.hWindow:GetPosition())
	UpdateXYPos(2, wx.wxPoint(size:GetWidth(), size:GetHeight()))

	m_MainFrame.hWindow.Destroy(m_MainFrame.hWindow)
	m_MainFrame.hWindow = nil
end

-- wxPaintDC			-- drawing to the screen, during EVT_PAINT
-- wxClientDC			-- drawing to the screen, outside EVT_PAINT
-- wxBufferedPaintDC	-- drawing to a buffer, then the screen, during EVT_PAINT
-- wxBufferedDC			-- drawing to a buffer, then the screen, outside EVT_PAINT
-- wxMemoryDC			-- drawing to a bitmap

-- ----------------------------------------------------------------------------
-- we just splat the off screen dc over the current dc
--
local function OnPaint(event) 
--	trace.line("OnPaint")

	if not m_MainFrame.hWindow then return end

	local dc     = wx.wxPaintDC(m_MainFrame.hWindow)
	local rcSize = m_MainFrame.hWindow:GetClientSize()

	if m_MainFrame.hMemoryDC then
		if thisApp.tConfig.Inverted then
			dc:Blit(0, 0, rcSize:GetWidth(), rcSize:GetHeight(), m_MainFrame.hMemoryDC, 0, 0, wx.wxBLIT_NOTSCRCOPY)
		else
			dc:Blit(0, 0, rcSize:GetWidth(), rcSize:GetHeight(), m_MainFrame.hMemoryDC, 0, 0, wx.wxBLIT_SRCCOPY)
		end
	end

	dc:delete()
end
-- ----------------------------------------------------------------------------
--
local function NewMemDC() 
--	trace.line("NewMemDC")

	if not m_MainFrame.hWindow then return end
	 
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
--	trace.line("Refresh")

	if not m_MainFrame.hWindow then return end

	if m_MainFrame.hMemoryDC then
		m_MainFrame.hMemoryDC:delete()
		m_MainFrame.hMemoryDC = nil
	end

	m_MainFrame.hMemoryDC = NewMemDC()
	m_MainFrame.hWindow:Refresh()   
end

-- ----------------------------------------------------------------------------
--
local function OnEditCut(event)
--	trace.line("OnEditCut")

end

-- ----------------------------------------------------------------------------
--
local function OnEditCopy(event)
--	trace.line("OnEditCopy")
	
	if 0 > m_MainFrame.iStopLine then return end
	
	local iRetCode, sCopyBuff = thisApp.GetTextAtPos(m_MainFrame.iStopStart, m_MainFrame.iCursor)

	if 0 < iRetCode then
		local clipBoard = wx.wxClipboard.Get()
		if clipBoard and clipBoard:Open() then

			clipBoard:SetData(wx.wxTextDataObject(sCopyBuff))
			clipBoard:Close()

	--		trace.line("Data in clipboard")
		end
	end
end

-- ----------------------------------------------------------------------------
--
local function OnEditPaste(event)
--	trace.line("OnEditPaste")

end

-- ----------------------------------------------------------------------------
--
local function OnEditSelectAll(event)
--	trace.line("OnEditSelectAll")

end

-- ----------------------------------------------------------------------------
--

--function OnEdit(event)
	
--    local menu_id = event:GetId()
--    local editor = GetEditor()
--    if editor == nil then return end

--    if     menu_id == ID_CUT       then editor:Cut()
--    elseif menu_id == ID_COPY      then editor:Copy()
--    elseif menu_id == ID_PASTE     then editor:Paste()
--    elseif menu_id == ID_SELECTALL then editor:SelectAll()
--    elseif menu_id == ID_UNDO      then editor:Undo()
--    elseif menu_id == ID_REDO      then editor:Redo()
--    end
--end

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
	m_MainFrame.iStopLine		= -1
	
	local iBytes, sText = thisApp.LoadFile()
	if 0 == iBytes then m_MainFrame.iCursor = 0 end
	
	Refresh()
	
	SetStatusText("" .. m_MainFrame.iCursor, 5)
	SetStatusText("" .. m_MainFrame.iStopLine, 4)
	SetStatusText(sText, 2)
end

-- ----------------------------------------------------------------------------
--
local function OnCheckEncoding(event)
--	trace.line("OnCheckEncoding")

	local _, sText = thisApp.CheckEncoding()
	
	SetStatusText(sText, 2)
end

-- ----------------------------------------------------------------------------
--
local function OnEncode_UTF_8(event)
--	trace.line("OnEncode_UTF_8")

	local _, sText = thisApp.Encode_UTF_8()
	
	SetStatusText(sText, 2)
end

-- ----------------------------------------------------------------------------
--
local function OnCreateSamples(event)
--	trace.line("OnCreateSamples")
	
	local bRet = thisApp.CreateTest()
	
	if bRet then
		SetStatusText("Samples file created", 2)
	else
		SetStatusText("Samples fle creation failed", 2)
	end
	
end

-- ----------------------------------------------------------------------------
-- align view of file based on the current cursor position
--
local function AlignBytesToCursor(inNewValue)
--	trace.line("AlignBytesToCursor")

	local iNumCols	= thisApp.tConfig.Columns
	local iLimit	= thisApp.iMemorySize
	local iNumRows	= m_MainFrame.iByteRowCount
	local iFirstRow	= m_MainFrame.iByteFirstRow

	if 0 >= inNewValue then inNewValue = 1 end
	if iLimit < inNewValue then inNewValue = iLimit end

	local iTopLine = _floor((inNewValue - 1) / iNumCols)

	if iFirstRow < (iTopLine - iNumRows) then iFirstRow = (iTopLine - iNumRows) end
	if iFirstRow > iTopLine then iFirstRow = iTopLine end
		
	m_MainFrame.iCursor			= inNewValue
	m_MainFrame.iByteFirstRow	= iFirstRow
end

-- ----------------------------------------------------------------------------
-- get the cell selected by the user
-- this function works only if a monospaced font is used for the bytes pane
--
local function OnLeftBtnDown(event)
--	trace.line("OnLeftBtnDown")

	if 0 >= thisApp.iMemorySize then return end

	-- get the position where the users made a choice
	--
	local dcClient = m_MainFrame.hMemoryDC
	
	local pos = event:GetLogicalPosition(dcClient)
	local x, y = pos:GetXY()
	
	-- get the width and height of a byte display
	-- (might be 2, 3 or 4 chars long)
	--
	dcClient:SetFont(m_MainFrame.hFontBytes)
	
	local sTest		= _format(m_MainFrame.tFormatBytes[1], 0)
	local iSpacerX	= dcClient:GetTextExtent(sTest)
	local iSpacerY	= dcClient:GetCharHeight()

	-- (don't bother to resume the original font)
	--

	-- get the cell (row,col)
	-- align to rectangle boundary
	--
	local iRow = _floor((y - y % iSpacerY) / iSpacerY)
	local iCol = _floor((x + x % iSpacerX) / iSpacerX)
	
	-- check for the pane's boundaries
	--
	local iNumCols	= thisApp.tConfig.Columns
	local rcWidth	= iSpacerX * iNumCols
	local rcHeight	= iSpacerY * (m_MainFrame.iByteRowCount + 1)
	
	if x > rcWidth then return end
	if y > rcHeight then return end
	
	-- get the logical selection
	--	
	local iFirstByte	= m_MainFrame.iByteFirstRow * iNumCols	
	local iNewCursor	= iFirstByte + iCol + iRow * iNumCols
	
--	trace.line("Mouse on cell [" .. iRow .. ", " .. iCol .. "] --> " .. iNewCursor)
	
	if iNewCursor ~= m_MainFrame.iCursor then
	
		AlignBytesToCursor(iNewCursor)
		
		Refresh()
		
		SetStatusText("" .. m_MainFrame.iCursor, 5)
		SetStatusText("" .. m_MainFrame.iStopLine, 4)
	end
	
end

-- ----------------------------------------------------------------------------
-- handle the mouse wheel
--
local function OnMouseWheel(event)
--	trace.line("OnMouseWheel")

	if 0 >= thisApp.iMemorySize then return end
	
	local iCurrent	= m_MainFrame.iCursor
	local iNumCols	= thisApp.tConfig.Columns
	local iLines	= event:GetLinesPerAction()
	local iScroll	= iNumCols * iLines

	-- works reversed
	--
	if 0 < event:GetWheelRotation() then iScroll = -1 * iScroll end
	
	AlignBytesToCursor(iCurrent + iScroll)
	
	Refresh()
	
	SetStatusText("" .. m_MainFrame.iCursor, 5)
	SetStatusText("" .. m_MainFrame.iStopLine, 4)
end

-- ----------------------------------------------------------------------------
--
local function OnKeyDown(event)
--	trace.line("OnKeyDown")

	if 0 >= thisApp.iMemorySize then return end
	
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
	
	SetStatusText("" .. m_MainFrame.iCursor, 5)
	SetStatusText("" .. m_MainFrame.iStopLine, 4)
end

-- ----------------------------------------------------------------------------
--
local function OnTimer(event)
--	trace.line("OnTimer")

	if not m_MainFrame.hWindow then return end 

	-- cleanup the status bar
	--
	SetStatusText(nil, 2)
end

-- ----------------------------------------------------------------------------
--
--
local function OnSize(event)
--	trace.line("OnSize")

	if not m_MainFrame.hWindow then return end
	if not m_MainFrame.hStatusBar then return end

	local size = event:GetSize()

	m_MainFrame.rcClientW = size:GetWidth()
	m_MainFrame.rcClientH = size:GetHeight() - 80	-- subtract the status bar height

	-- -------------------
	-- statusbar panes
	-- get the sum of all panes except the second
	--
	local iWidth = tStbarWidths[1]
	for i=3, #tStbarWidths do
		iWidth = iWidth + tStbarWidths[i]
	end
	tStbarWidths[2] = m_MainFrame.rcClientW - iWidth
	
	m_MainFrame.hStatusBar:SetStatusWidths(tStbarWidths)
	
	-- regenerate the offscreen buffer
	--
	Refresh()
	
	SetStatusText("" .. m_MainFrame.iCursor, 5)
	SetStatusText("" .. m_MainFrame.iStopLine, 4)
end

-- ----------------------------------------------------------------------------
-- allocate the fonts
--
local function SetupFonts()
--	trace.line("SetupFonts")

	-- font properties read from the config file
	--
	local specBytes = thisApp.tConfig.ByteFont
	local specText  = thisApp.tConfig.TextFont
	local tFmtBytes = tFormat.Dec	
	
	-- allocate
	--
	local fBytes = wx.wxFont(specBytes[1], wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL,
									 wx.wxFONTWEIGHT_NORMAL, false, specBytes[2])
					
	local fText  = wx.wxFont(specText[1], wx.wxFONTFAMILY_DEFAULT, wx.wxFONTSTYLE_NORMAL,
									 wx.wxFONTWEIGHT_NORMAL, false, specText[2])
		
	-- format string to use (oct/dec/hex)
	-- defaults to decimal
	--
	for tag, tFormat in pairs(tFormat) do
		if _find(thisApp.tConfig.Format, tag, 1, true) then tFmtBytes = tFormat break end
	end	
	
	-- setup
	--
	m_MainFrame.hFontBytes	= fBytes
	m_MainFrame.hFontText	= fText
	m_MainFrame.tFormatBytes= tFmtBytes


	return (fBytes and fText)
end

-- ----------------------------------------------------------------------------
-- create the main window
--
local function CreateMainWindow()
--	trace.line("SetupFonts")

	-- read deafult positions for the dialogs
	--
	ReadSettings()
  
	-- unique IDs for the menu
	--  
	local rcMnuReadFile = UniqueID()
	local rcMnuTestFile = UniqueID()
	local rcMnuCheckFmt = UniqueID()
	local rcMnuEncUTF8  = UniqueID()

	local rcMnuEdCut   = wx.wxID_CUT
	local rcMnuEdCopy  = wx.wxID_COPY
	local rcMnuEdPaste = wx.wxID_PASTE
	local rcMnuEdSelAll= wx.wxID_SELECTALL
	
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
	mnuFile:Append(rcMnuReadFile, "Import File\tCtrl-L",  "Read the file in memory")
	mnuFile:Append(rcMnuEncUTF8,  "Encode UTF_8\tCtrl-U", "Overwrite file with new encoding")
	mnuFile:Append(wx.wxID_EXIT,  "E&xit\tAlt-X",		  "Quit the program")
	
	-- create the EDIT menu
	--
	local mnuEdit = wx.wxMenu("", wx.wxMENU_TEAROFF)
	mnuEdit:Append(rcMnuEdCut,	  "Cu&t\tCtrl-X",        "Cut selected text to clipboard")
	mnuEdit:Append(rcMnuEdCopy,	  "&Copy\tCtrl-C",       "Copy selected text to the clipboard")
	mnuEdit:Append(rcMnuEdPaste,  "&Paste\tCtrl-V",      "Insert clipboard text at cursor")
	mnuEdit:Append(rcMnuEdSelAll, "Select A&ll\tCtrl-A", "Select all text in the editor")
	
	-- create the COMMANDS menu
	--
	local mnuCmds = wx.wxMenu("", wx.wxMENU_TEAROFF)
	mnuCmds:Append(rcMnuCheckFmt, "Check Format\tCtrl-F", "Check bytes in current file")
	mnuCmds:Append(rcMnuTestFile, "Create File\tCtrl-T",  "Create a binary test file")

	-- create the HELP menu
	--
	local mnuHelp = wx.wxMenu("", wx.wxMENU_TEAROFF)  
	mnuHelp:Append(wx.wxID_ABOUT, "&About\tAlt-A", "About Application")

	-- create the menu bar and associate sub-menus
	--
	local mnuBar
	mnuBar = wx.wxMenuBar()  
	mnuBar:Append(mnuFile,	"&File")
	mnuBar:Append(mnuEdit,	"&Edit")
	mnuBar:Append(mnuCmds,	"&Commands")
	mnuBar:Append(mnuHelp,	"&Help")

	frame:SetMenuBar(mnuBar)

	-- create the bottom status bar
	--
	local hStatusBar	
	hStatusBar = frame:CreateStatusBar(#tStbarWidths, wx.wxST_SIZEGRIP)
	hStatusBar:SetFont(wx.wxFont(11, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_BOLD))      
	hStatusBar:SetStatusWidths(tStbarWidths)
	
	-- standard event handlers
	--
	frame:Connect(wx.wxEVT_PAINT,			OnPaint)
	frame:Connect(wx.wxEVT_TIMER,			OnTimer)
	frame:Connect(wx.wxEVT_SIZE,			OnSize)
	frame:Connect(wx.wxEVT_KEY_DOWN,		OnKeyDown)
	frame:Connect(wx.wxEVT_LEFT_DOWN,		OnLeftBtnDown)
	frame:Connect(wx.wxEVT_MOUSEWHEEL,		OnMouseWheel)	
	frame:Connect(wx.wxEVT_CLOSE_WINDOW,	OnClose)

	-- menu event handlers
	--
	frame:Connect(rcMnuReadFile, wx.wxEVT_COMMAND_MENU_SELECTED, OnReadFile)
	frame:Connect(rcMnuTestFile, wx.wxEVT_COMMAND_MENU_SELECTED, OnCreateSamples)
	frame:Connect(rcMnuCheckFmt, wx.wxEVT_COMMAND_MENU_SELECTED, OnCheckEncoding)
	frame:Connect(rcMnuEncUTF8,	 wx.wxEVT_COMMAND_MENU_SELECTED, OnEncode_UTF_8)
	frame:Connect(wx.wxID_EXIT,	 wx.wxEVT_COMMAND_MENU_SELECTED, OnClose)
	frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED, OnAbout)
	
	frame:Connect(rcMnuEdCut,	 wx.wxEVT_COMMAND_MENU_SELECTED, OnEditCut)
	frame:Connect(rcMnuEdCopy,   wx.wxEVT_COMMAND_MENU_SELECTED, OnEditCopy)
	frame:Connect(rcMnuEdPaste,  wx.wxEVT_COMMAND_MENU_SELECTED, OnEditPaste)
	frame:Connect(rcMnuEdSelAll, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditSelectAll)
	  
	-- set up the frame
	--
	frame:SetMinSize(wx.wxSize(500, 250))  
	frame:SetStatusBarPane(1)                   -- this is reserved for the menu
	
	-- this is necessary to avoid flickering
	-- (comment the line if running with the debugger)
	--
	frame:SetBackgroundStyle(wx.wxBG_STYLE_CUSTOM)
	
	--  store for later
	--
	m_MainFrame.hWindow 	= frame	
	m_MainFrame.hStatusBar	= hStatusBar
	m_MainFrame.hMemoryDC	= NewMemDC()
	
	return frame
end

-- ----------------------------------------------------------------------------
-- show the main window and runs the main loop
--
local function ShowMainWindow()
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
local function CloseMainWindow()
--	trace.line("CloseMainWindow")
	
	SaveSettings(m_sSettingsIni, tWinProp) 
	
  if m_MainFrame.hWindow then OnClose() end
  
end

-- ----------------------------------------------------------------------------
--
return
{
	Show	= ShowMainWindow,
	Close	= CloseMainWindow,
}

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
