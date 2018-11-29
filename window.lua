-- ----------------------------------------------------------------------------
--
--  Mainframe
--
-- ----------------------------------------------------------------------------

local wx 		= require "wx"			-- uses wxWidgets for Lua 5.1
local palette	= require "palette"		-- common Colours definition in wxWidgets
local bits  	= require "bits"		-- bit manipulators
local trace 	= require "trace"		-- shortcut for tracing
local ticktime  = require "ticktimer"	-- timer object constructor

local _floor	= math.floor
local _format	= string.format
local _find		= string.find
local _strrep	= string.rep
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
	70,				-- current line
	150,			-- cursor position
}

-- ----------------------------------------------------------------------------
--
local tSchemeWhite =
{
	["LeftBack"]	= palette.White,
	["ColourColumn"]= palette.Honeydew,
	["LeftText"]	= palette.Black,
	["LeftCursor"]	= palette.Orchid2,
	["Linefeed"]	= palette.Gray20,
	["Unprintable"]	= palette.Purple3,
	["MarkStart"]	= palette.CadetBlue2,
	["HighBits"]	= palette.NavajoWhite1,
	
	["RightBack"]	= palette.White,
	["RightText"]	= palette.Black,
	["RightCursor"]	= palette.Blue1,	
	["VerticalBar"]	= palette.SlateGray2,
	["StopRow"]		= palette.Wheat2,
}

local tSchemeLight =
{
	["LeftBack"]	= palette.Gray90,
	["ColourColumn"]= palette.Gray94,
	["LeftText"]	= palette.Gray30,
	["LeftCursor"]	= palette.DarkSeaGreen3,
	["Linefeed"]	= palette.Gray15,
	["Unprintable"]	= palette.Magenta,
	["MarkStart"]	= palette.LightPink2,
	["HighBits"]	= palette.LightBlue2,
	
	["RightBack"]	= palette.Seashell2,
	["RightText"]	= palette.Gray40,
	["RightCursor"]	= palette.Black,	
	["VerticalBar"]	= palette.Khaki3,
	["StopRow"]		= palette.Burlywood1,
}

local tSchemeDark =
{
	["LeftBack"]	= palette.MidnightBlue,
	["ColourColumn"]= palette.NavyBlue,
	["LeftText"]	= palette.Gray75,
	["LeftCursor"]	= palette.VioletRed1,
	["Linefeed"]	= palette.Gray80,
	["Unprintable"]	= palette.Magenta,
	["MarkStart"]	= palette.Sienna,
	["HighBits"]	= palette.SeaGreen4,
	
	["RightBack"]	= palette.DarkSlateGray,
	["RightText"]	= palette.Gray70,
	["RightCursor"]	= palette.VioletRed1,	
	["VerticalBar"]	= palette.Ivory3,
	["StopRow"]		= palette.Firebrick4,
}

local tSchemeBlack =
{
	["LeftBack"]	= palette.Black,
	["ColourColumn"]= palette.Gray20,
	["LeftText"]	= palette.Gray90,
	["LeftCursor"]	= palette.SeaGreen3,
	["Linefeed"]	= palette.Thistle1,
	["Unprintable"]	= palette.Magenta,
	["MarkStart"]	= palette.SlateBlue,
	["HighBits"]	= palette.DarkGoldenrod,
	
	["RightBack"]	= palette.Black,
	["RightText"]	= palette.Gray80,
	["RightCursor"]	= palette.LightGoldenrod,	
	["VerticalBar"]	= palette.LightSteelBlue3,
	["StopRow"]		= palette.IndianRed4,
}

-- prealloc the pens and brushes
--
-- bytes pane
--
local penLF = wx.wxPen(tSchemeWhite.Linefeed, 3, wx.wxSOLID)
local penXX = wx.wxPen(tSchemeWhite.Unprintable, 3, wx.wxSOLID)
local brMrk = wx.wxBrush(tSchemeWhite.MarkStart, wx.wxSOLID)
local brHBt = wx.wxBrush(tSchemeWhite.HighBits, wx.wxSOLID)
local brCur = wx.wxBrush(tSchemeWhite.LeftCursor, wx.wxSOLID)

-- text pane
--
local brStp	= wx.wxBrush(tSchemeWhite.StopRow, wx.wxSOLID)
local brUnd = wx.wxPen(tSchemeWhite.RightCursor, 6, wx.wxSOLID)

-- ----------------------------------------------------------------------------
--
local tFormat =
{
	["Oct"] = {"%04o ", 5},
	["Dec"] = {"%03d ", 4},
	["Hex"] = {"%02x ", 3},
}

-- ----------------------------------------------------------------------------
-- Generate a unique new wxWindowID
--
local iRCEntry = wx.wxID_HIGHEST + 1

local function UniqueID()
	
	iRCEntry = iRCEntry + 1
	return iRCEntry
end

-- ----------------------------------------------------------------------------
--
local tTimers =
{
	-- name        interval		last fired
	--
	["Display"] = ticktime.new("Display"),
	["Garbage"] = ticktime.new("Garbage"),
}

-- ----------------------------------------------------------------------------
-- window's bag
--
local m_MainFrame = 
{
	hWindow			= nil,	-- main frame
	bVisible		= false,-- last visibile status
	hStatusBar		= nil,	-- the status bar
	hSlidesDC		= nil,	-- background for the 2 slides
	hMemoryDC		= nil,	-- device context for the window	
	hTickTimer		= nil,	-- timer for messages in the statusbar

	hFontBytes		= nil,	-- the font for the bytes (left) pane
	hFontText		= nil,	-- the font for the text (right) pane
	tColourScheme	= tSchemeLight, -- assign colours' table

	rcClientW		= 0,	-- client rect width
	rcClientH		= 0,	-- client rect height
	iOffsetX		= 14,	-- offset for writing text
	iOffsetY		= 14,	-- offset for writing text
	
	iLeftMonoWidth	= 0,	-- pixels for 1 byte display
	iLeftSpacerX	= 0,	-- pixels for formatted string (oct/dec/hex)
	iLeftSpacerY	= 0,	-- pixels for the height
	
	iRightSpacerX	= 0,	-- not used
	iRightSpacerY	= 0,	-- height in pixels of character
	
	iTmInterval		= 3000,	-- diplay msg on status bar for much time
	
	iCursor			= 0,	-- where the cursor is
	tFormatBytes	= nil,	-- format string for the bytes display
	sTabReplace		= "",	-- replacement for tab on text slide
	iByteRowCount	= 0,	-- number of visibles rows
	iByteFirstRow	= 0,	-- first row visible, left rect
	
	iTextRowCount	= 0,	-- number of visible rows
	iTextFirstRow	= 0,	-- first row visible, right rect
	iStopLine		= -1,	-- line where the cursor is in
	iStopStart		= 0,	-- byte offset of stopline in buffer	
}

-- ----------------------------------------------------------------------------
--
local m_PenNull = wx.wxPen(palette.Black, 1, wx.wxTRANSPARENT)

-- ----------------------------------------------------------------------------
-- default dialogs' locations
--
local tWinProp =
{
	{"Main Position",	{20,	 20}},
	{"Main Size",		{750,	250}},
}

local m_sSettingsIni = "window.ini"

-- flags in use for the main frame
--
local dwMainFlags = bits.bitoper(wx.wxDEFAULT_FRAME_STYLE,  wx.wxCAPTION,   bits.OR)
dwMainFlags       = bits.bitoper(dwMainFlags,     wx.wxCLIP_CHILDREN,       bits.OR)
dwMainFlags       = bits.bitoper(dwMainFlags,     wx.wxSYSTEM_MENU,         bits.OR)
dwMainFlags       = bits.bitoper(dwMainFlags,     wx.wxCLOSE_BOX,           bits.OR)

-- ----------------------------------------------------------------------------
-- get the correct spacing
--
local function CalcFontSpacing(inDrawDC)
	
	if not inDrawDC then return end
	if not m_MainFrame.hFontBytes then return end
	if not m_MainFrame.hFontText then return end
	
	-- left pane
	--
	inDrawDC:SetFont(m_MainFrame.hFontBytes)   
 	
	local sTest	= _format(m_MainFrame.tFormatBytes[1], 0)
	
	m_MainFrame.iLeftMonoWidth	= inDrawDC:GetTextExtent("0")
	m_MainFrame.iLeftSpacerX	= inDrawDC:GetTextExtent(sTest)
	m_MainFrame.iLeftSpacerY	= inDrawDC:GetCharHeight()	
	
	-- right pane
	--
	inDrawDC:SetFont(m_MainFrame.hFontText)   
 	
	m_MainFrame.iRightSpacerX	= 0
	m_MainFrame.iRightSpacerY	= inDrawDC:GetCharHeight()	
	
end

-- ----------------------------------------------------------------------------
-- draw a vertical bar of size of 1 page
--
local function DrawVerticalBar(inDrawDC)
--	trace.line("DrawVerticalBar")

	if not inDrawDC then return end
	if 0 == thisApp.iFileBytes then return end

	-- get the correct spacing here
	-- 	
	local iSpacerY	= m_MainFrame.iRightSpacerY
	local iOffY 	= m_MainFrame.iOffsetY
	local iHeight	= m_MainFrame.rcClientH - iSpacerY - iOffY
	
	local iNumRows	= #thisApp.tFileLines
	local iCurPage	= (m_MainFrame.iTextFirstRow / m_MainFrame.iTextRowCount)
	local iPages	= (iNumRows / m_MainFrame.iTextRowCount)
	local iPageLen	= (iHeight / iPages)
	local iPosY		= (iPageLen * iCurPage) + iOffY
			
	-- just fix it when too small
	--
	if 10 > iPageLen then iPageLen = 25 end
	
	inDrawDC:SetPen(m_PenNull)
	inDrawDC:SetBrush(wx.wxBrush(m_MainFrame.tColourScheme.VerticalBar, wx.wxSOLID))
	inDrawDC:DrawRectangle(m_MainFrame.rcClientW - 25, iPosY, 25, iPageLen)
end

-- ----------------------------------------------------------------------------
-- draw highlight for each even column
--
local function DrawColumns(inDrawDC)
--	trace.line("DrawColumns")
	
	if not inDrawDC then return end
	if not m_MainFrame.hFontBytes then return end
	
	local iCurX		= m_MainFrame.iOffsetX
	local iColumns	= thisApp.tConfig.Columns
	local iSpacerX	= m_MainFrame.iLeftSpacerX
	local tScheme	= m_MainFrame.tColourScheme
	
	inDrawDC:SetPen(m_PenNull)
	inDrawDC:SetBrush(wx.wxBrush(tScheme.ColourColumn, wx.wxSOLID))

	-- center the highlight on the number of chars written (hex/dec/oct)
	--
	iCurX = iCurX - (iSpacerX / (m_MainFrame.tFormatBytes[2] * 2)) + iSpacerX
	
	while iColumns > 0 do
		
		inDrawDC:DrawRectangle(iCurX, 0, iSpacerX, m_MainFrame.rcClientH)
		
		iCurX = iCurX + iSpacerX * 2
		
		iColumns = iColumns - 2
	end	
end

-- ----------------------------------------------------------------------------
--
local function DrawBytes(inDrawDC)
--	trace.line("DrawBytes start")
	
	-- quit if no data
	--
	if 0 >= thisApp.iFileBytes then return end

	-- here we go
	--
	local iCursor	= m_MainFrame.iCursor
	local iNumCols	= thisApp.tConfig.Columns
	local tFile		= thisApp.tFileLines
	local iOffX 	= m_MainFrame.iOffsetX
	local iOffY 	= m_MainFrame.iOffsetY
	local iCurX 	= iOffX
	local iCurY 	= iOffY
	local tFmtBytes	= m_MainFrame.tFormatBytes			-- format table to use (hex/dec/oct)
	local bUnderline = thisApp.tConfig.Underline		-- underline bytes below 0x20
	local bUnicode	= thisApp.tConfig.ColourCodes		-- highlight Unicode codes
	local tScheme	= m_MainFrame.tColourScheme			-- colour scheme in use
		
	-- this is the number oof visible rows in the drawing area
	-- refresh it now
	--
	m_MainFrame.iByteRowCount = 0

	-- foreground
	--
	inDrawDC:SetFont(m_MainFrame.hFontBytes)
	inDrawDC:SetTextForeground(tScheme.LeftText)

	-- get the correct spacing here
	--
	local iSpacerX	= m_MainFrame.iLeftMonoWidth
	local iSpacerY	= m_MainFrame.iLeftSpacerY
	local iRectH	= m_MainFrame.rcClientH - iOffY * 2 - iSpacerY
	
	------------------------
	-- print all chars
	--
	local tChars = { }						-- current set of tokens
	local tDraw1 = { }						-- underline \n
	local tDraw2 = { }						-- underline unprintable
	local tDraw3 = { }						-- rect under UTF_8 mark byte
	local tDraw4 = { }						-- rect under UTF_8 code
	local tDraw5 = { }						-- cursor
	
	-- start from first visible row
	--	
	local iOffset 	 = iNumCols * m_MainFrame.iByteFirstRow
	local iFileIndex = thisApp.LookupInterval(tFile, iOffset)
	local tCurr 	 = tFile[iFileIndex]
	local iCurColumn = 1
	local iBufIndex  = iOffset - tCurr[1] + 1
	local sSpaceSub  = _strrep(" ", tFmtBytes[2])
	local bHideSpace = thisApp.tConfig.HideSpaces
	local sToDraw
	local ch
	
	while tCurr do
		
		while iNumCols >= iCurColumn do
			
			if #tCurr[2] < iBufIndex then
				
				-- query next row in table
				--
				iFileIndex = iFileIndex + 1
				tCurr = tFile[iFileIndex]
				iBufIndex = 1
				
				-- safety check
				--
				if not tCurr then break end				
			end

			ch = tCurr[2]:byte(iBufIndex)
			
			-- check for replacing the space byte
			--
			if bHideSpace and 0x20 == ch then 
				sToDraw = sSpaceSub
			else
				sToDraw = _format(tFmtBytes[1], ch)
			end
			
			_insert(tChars, sToDraw)
			
			-- highlight chars
			--				
			if (0x20 > ch) or (0x7f < ch) or (tCurr[1] + iBufIndex) == iCursor then
				
				local xPos = iCurX + ((iCurColumn - 1) * iSpacerX * tFmtBytes[2])
				local yPos = iCurY + iSpacerY - 3
				local xLen = iSpacerX * (tFmtBytes[2] - 1)
				
				if bUnderline then
					if 0x0a == ch 	 then _insert(tDraw1, {xPos, yPos, xPos + xLen, yPos})
					elseif 0x20 > ch then _insert(tDraw2, {xPos, yPos, xPos + xLen, yPos}) end
				end

				if bUnicode then
					if 0xbf < ch 	 then _insert(tDraw3, {xPos, iCurY, xLen, iSpacerY})
					elseif 0x7f < ch then _insert(tDraw4, {xPos, iCurY, xLen, iSpacerY}) end
				end
				
				-- draw the cursor now
				-- (make it slightly bigger)
				--
				if (tCurr[1] + iBufIndex) == iCursor then _insert(tDraw5, {xPos - 2, iCurY - 2, xLen + 4, iSpacerY + 4}) end				
			end		

			-- get next
			--
			iBufIndex	= iBufIndex + 1			
			iCurColumn	= iCurColumn + 1
		end
		
		-- draw all the cosmetics
		--
		if 0 < #tDraw1 then
			inDrawDC:SetPen(penLF)
			for _, coords in ipairs(tDraw1) do inDrawDC:DrawLine(coords[1], coords[2], coords[3], coords[4]) end
			tDraw1 = { }
		end

		if 0 < #tDraw2 then
			inDrawDC:SetPen(penXX)
			for _, coords in ipairs(tDraw2) do inDrawDC:DrawLine(coords[1], coords[2], coords[3], coords[4]) end
			tDraw2 = { }
		end
		
		inDrawDC:SetPen(m_PenNull)	-- remove bounding box

		if 0 < #tDraw3 then
			inDrawDC:SetBrush(brMrk)
			for _, coords in ipairs(tDraw3) do inDrawDC:DrawRectangle(coords[1], coords[2], coords[3], coords[4]) end
			tDraw3 = { }
		end
		
		if 0 < #tDraw4 then
			inDrawDC:SetBrush(brHBt)
			for _, coords in ipairs(tDraw4) do inDrawDC:DrawRectangle(coords[1], coords[2], coords[3], coords[4]) end
			tDraw4 = { }
		end
		
		if 0 < #tDraw5 then
			inDrawDC:SetBrush(brCur)
			for _, coords in ipairs(tDraw5) do inDrawDC:DrawRectangle(coords[1], coords[2], coords[3], coords[4]) end
			tDraw5 = { }
		end		
		
		-- draw all the text line
		--
		inDrawDC:DrawText(_concat(tChars), iCurX, iCurY)
		tChars = { }
		
		-- check if we are writing off the client area
		--
		iCurY = iCurY + iSpacerY
		
		if iRectH < iCurY then break end

		-- restart from first column
		--
		iCurColumn = 1
		
		-- update the number of visible rows
		--
		m_MainFrame.iByteRowCount = m_MainFrame.iByteRowCount + 1		
	end
end

-- ----------------------------------------------------------------------------
-- this is the right part with the text formatting
--
local function DrawText(inDrawDC)
--	trace.line("DrawText")
	
	if 0 >= thisApp.iFileBytes then return end
	if 0 >= m_MainFrame.iCursor then return end

	local iCursor	= m_MainFrame.iCursor
	local tScheme	= m_MainFrame.tColourScheme						-- colour scheme in use
	local sTabRep	= m_MainFrame.sTabReplace						-- replace tab with chars
	local iOffX 	= m_MainFrame.iOffsetX
	local iOffY 	= m_MainFrame.iOffsetY
--	local iSpacerX	= m_MainFrame.iRightSpacerX
	local iSpacerY	= m_MainFrame.iRightSpacerY						-- height of each line
	local iNumCols	= thisApp.tConfig.Columns
	local iCurX		= iOffX + iNumCols * m_MainFrame.iLeftSpacerX	-- use left spacer
	local iCurY		= iOffY
	
	-- check which line will be the first
	--	
	local tFile			= thisApp.tFileLines
	local iStopLine		= thisApp.LookupInterval(tFile, iCursor - 1)
	if 0 == iStopLine then return end								-- failed to get text
	
	local tCurrent		= tFile[iStopLine]
	local iStopStart	= tCurrent[1]
	local iStopOffset	= -1
	local iStopLength	= 0
	
--[[	
	-- perform a progressive scan of memory for newlines
	--
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
			
			iExtEnd = iExtEnd + iNumSubs * #sTabRep - iNumSubs
			
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
]]	
	-- get the number of rows * font height and
	-- correct the y offset
	--
	local iLowLimit= m_MainFrame.rcClientH - (iOffY * 2) - (iSpacerY * 2)	-- drawing height bound
	local iNumRows = _floor(iLowLimit / iSpacerY)							-- allowed rows
	
	-- update
	--
	iOffY	  = _floor(((iLowLimit - (iSpacerY * iNumRows)) / 2))			-- vertical offset updated
	iLowLimit = m_MainFrame.rcClientH - iOffY - iSpacerY					-- vertical limit
	
	-- align indexes for the line currently highlighted
	-- (basically a list view)
	--	
	local iFirstRow = m_MainFrame.iTextFirstRow
	if iFirstRow > iStopLine then iFirstRow = iStopLine end								-- passing the top
	if iStopLine > (iFirstRow + iNumRows) then iFirstRow = (iStopLine - iNumRows) end	-- passing the bottom
	if 0 >= iFirstRow then iFirstRow = 1 end

	-- store for later use outside the drawing function
	--
	m_MainFrame.iTextFirstRow = iFirstRow	
	m_MainFrame.iTextRowCount = iNumRows
	m_MainFrame.iStopLine	  = iStopLine
	m_MainFrame.iStopStart 	  = iStopStart
	
	------------------
	-- print all chars
	--
	iCurX = iCurX + iOffX
	iCurY = iOffY + iSpacerY
	
	-- highlight the background of the stopline
	--
	if 0 < iStopLine then
		
		local pStartX	= iCurX
		local pStartY	= iOffY + (iStopLine - iFirstRow + 1) * iSpacerY
		local iWidth	= m_MainFrame.rcClientW - pStartX
		local iHeight	= iSpacerY
		
		inDrawDC:SetPen(m_PenNull)
		inDrawDC:SetBrush(brStp)
		inDrawDC:DrawRectangle(pStartX, pStartY - 2, iWidth, iHeight + 4)		
	end

	-- assign font for drawing text
	--
	inDrawDC:SetFont(m_MainFrame.hFontText)
	inDrawDC:SetTextForeground(tScheme.RightText)

	-- draw the list
	--
	local sToDraw
	local iCurLine = iFirstRow
	local iLastLine= iFirstRow + iNumRows + 1
	
	while tFile[iCurLine] and (iLastLine > iCurLine) do
		
		sToDraw = tFile[iCurLine][2]
		sToDraw = sToDraw:gsub("\t", sTabRep)
		
		inDrawDC:DrawText(sToDraw, iCurX, iCurY)
		iCurY = iCurY + iSpacerY
		
		iCurLine = iCurLine + 1
	end
	
	-- underline the corresponding letter for the cursor
	--
--	if 0 <= iStopOffset then
		
--		local pStartX	= iCurX + iStopOffset
--		local pStartY	= iOffY + (iStopLine - iFirstRow + 2) * iSpacerY
--		local pEndX		= pStartX + iStopLength
--		local pEndY		= pStartY
		
--		inDrawDC:SetPen(brUnd)
--		inDrawDC:DrawLine(pStartX, pStartY, pEndX, pEndY)		
--	end

end

-- ----------------------------------------------------------------------------
--
local function DrawFile(inDrawDC)
--	trace.line("DrawFile")
	
	-- draw the background
	--
	if not m_MainFrame.hSlidesDC then return end
	inDrawDC:Blit(0, 0, m_MainFrame.rcClientW, m_MainFrame.rcClientH, m_MainFrame.hSlidesDC, 0, 0, wx.wxBLIT_SRCCOPY)
	
	if not m_MainFrame.bVisible then return end
	
	if not m_MainFrame.hFontBytes then return end
	DrawBytes(inDrawDC)

	if not m_MainFrame.hFontText then return end
	DrawText(inDrawDC)
	DrawVerticalBar(inDrawDC)
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
	if 1 == inCellNo and 0 < #inText then 
		tTimers.Display:Reset()
		tTimers.Display:Enable(true) 
	end
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
-- Simple interface to pop up a message
--
local function DlgMessage(message)
	
	wx.wxMessageBox(message, thisApp.sAppName,
					wx.wxOK + wx.wxICON_INFORMATION, m_MainFrame.hWindow)  
end

-- ----------------------------------------------------------------------------
--
local function OnAbout()

	DlgMessage(thisApp.sAppName .. " [" .. thisApp.sAppVersion .. "]\n" ..
				wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING)
end

-- ----------------------------------------------------------------------------
--
local function OnClose()
--	trace.line("OnClose")
	
	if not m_MainFrame.hWindow then return end

	wx.wxGetApp():Disconnect(wx.wxEVT_TIMER)
	
	-- need to convert from size to pos
	--`
	local size = m_MainFrame.hWindow:GetSize()

	UpdateXYPos(1, m_MainFrame.hWindow:GetPosition())
	UpdateXYPos(2, wx.wxPoint(size:GetWidth(), size:GetHeight()))

	-- finally destroy the window
	--
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
local function OnPaint() 
--	trace.line("OnPaint")
	
	if not m_MainFrame.hMemoryDC then return end

	local dc = wx.wxPaintDC(m_MainFrame.hWindow)
	
	dc:Blit(0, 0, m_MainFrame.rcClientW, m_MainFrame.rcClientH, m_MainFrame.hMemoryDC, 0, 0, wx.wxBLIT_SRCCOPY)
	dc:delete()
end

-- ----------------------------------------------------------------------------
--
local function DrawSlides(inDrawDC) 
--	trace.line("DrawSlides")

	if not m_MainFrame.hWindow then return end
	
	if not inDrawDC then return end
	if not m_MainFrame.hFontBytes then return end

	local iNumCols	= thisApp.tConfig.Columns
	local iOffX 	= m_MainFrame.iOffsetX
	local iOffY 	= m_MainFrame.iOffsetY
	local iCurX 	= iOffX
--	local iCurY 	= iOffY
	local tFmtBytes	= m_MainFrame.tFormatBytes			-- format table to use (hex/dec/oct)
	local tScheme	= m_MainFrame.tColourScheme			-- Colour scheme in use

	-- get the correct spacing here
	--
	local iSpacerX = m_MainFrame.iLeftMonoWidth
	local iSpacerY = m_MainFrame.iLeftSpacerY
	
	-- decide here the background Colour
	--
	local iRectW = iOffX + iNumCols * tFmtBytes[2] * iSpacerX
	local iRectH = m_MainFrame.rcClientH - iOffY * 2 - iSpacerY

	-- background
	--
	inDrawDC:SetPen(m_PenNull)
	inDrawDC:SetBrush(wx.wxBrush(tScheme.LeftBack, wx.wxSOLID))
	inDrawDC:DrawRectangle(0, 0, iRectW, m_MainFrame.rcClientH)
	
	-- draw the colums' on/off colour
	--
	if thisApp.tConfig.Interleave then DrawColumns(inDrawDC) end

	-- -----------------------------------------------
	-- this is the right part with the text formatting
	--
	
	-- still use the left pane font for correct start offset
	--
	iCurX	= iOffX + iNumCols * iSpacerX * tFmtBytes[2]

	-- get the correct spacing here
	--
	iSpacerX = m_MainFrame.iRightSpacerX
	iSpacerY = m_MainFrame.iRightSpacerY
		
	-- bounds
	--
	iRectW	= m_MainFrame.rcClientW - iCurX
	iRectH	= m_MainFrame.rcClientH - iOffY - iSpacerY

	-- background colour
	--
	inDrawDC:SetPen(m_PenNull)	
	inDrawDC:SetBrush(wx.wxBrush(tScheme.RightBack, wx.wxSOLID))
	inDrawDC:DrawRectangle(iCurX, 0, iRectW, m_MainFrame.rcClientH)
	
	-- gutter
	--
	inDrawDC:SetBrush(wx.wxBrush(tScheme.VerticalBar, wx.wxSOLID))
	inDrawDC:DrawRectangle(iCurX - iOffX / 2, 0, iOffX, m_MainFrame.rcClientH)	
end

-- ----------------------------------------------------------------------------
--
local function NewSlidesDC() 
--	trace.line("NewSlidesDC")

	-- create a bitmap wide as the client area
	--
	local memDC  = wx.wxMemoryDC()
 	local bitmap = wx.wxBitmap(m_MainFrame.rcClientW, m_MainFrame.rcClientH)
	memDC:SelectObject(bitmap)
	
	-- refresh the font spacing
	--
	if 0 == m_MainFrame.iLeftSpacerX then CalcFontSpacing(memDC) end
	
	-- if file is open then handle the draw
	--
	DrawSlides(memDC)

	return memDC
end

-- ----------------------------------------------------------------------------
--
local function NewMemDC() 
--	trace.line("NewMemDC")

	-- create a bitmap wide as the client area
	--
	local memDC  = wx.wxMemoryDC()
 	local bitmap = wx.wxBitmap(m_MainFrame.rcClientW, m_MainFrame.rcClientH)
	memDC:SelectObject(bitmap)
	
	-- refresh the font spacing
	--
	if 0 == m_MainFrame.iLeftSpacerX then CalcFontSpacing(memDC) end
	
	-- if file is open then handle the draw
	--
	DrawFile(memDC)

	return memDC
end

-- ----------------------------------------------------------------------------
--
local function RefreshSlides()
--	trace.line("RefreshSlides")

	if m_MainFrame.hSlidesDC then
		m_MainFrame.hSlidesDC:delete()
		m_MainFrame.hSlidesDC = nil
	end

	m_MainFrame.hSlidesDC = NewSlidesDC()
end

-- ----------------------------------------------------------------------------
--
local function Refresh()
--	trace.line("Refresh")

	if m_MainFrame.hMemoryDC then
		m_MainFrame.hMemoryDC:delete()
		m_MainFrame.hMemoryDC = nil
	end

	m_MainFrame.hMemoryDC = NewMemDC()
	
	if m_MainFrame.hWindow then
		m_MainFrame.hWindow:Refresh()   
	end	
end

-- ----------------------------------------------------------------------------
--
local function SetWindowTitle(inString)
--	trace.line("SetWindowTitle")
	
	if not m_MainFrame.hWindow then return false end
	
	inString = inString or thisApp.sAppName
	m_MainFrame.hWindow:SetTitle(inString)
	
	return true
end

-- ----------------------------------------------------------------------------
--
local function OnEditCut()
--	trace.line("OnEditCut")

end

-- ----------------------------------------------------------------------------
--
local function OnEditCopy()
--	trace.line("OnEditCopy")
	
	if 0 >= m_MainFrame.iStopLine then return end
	
	local iRetCode, sCopyBuff = thisApp.GetTextAtPos(m_MainFrame.iStopStart, m_MainFrame.iCursor - 1)

	if 0 < iRetCode then
		local clipBoard = wx.wxClipboard.Get()
		if clipBoard and clipBoard:Open() then

			clipBoard:SetData(wx.wxTextDataObject(sCopyBuff))
			clipBoard:Close()
		end
	else
		SetStatusText("Clipboard error: " .. sCopyBuff)
	end
end

-- ----------------------------------------------------------------------------
--
local function OnEditPaste()
--	trace.line("OnEditPaste")

end

-- ----------------------------------------------------------------------------
--
local function OnEditSelectAll()
--	trace.line("OnEditSelectAll")

end

-- ----------------------------------------------------------------------------
-- read file into memory
--
local function OnReadFile()
--	trace.line("OnReadFile")
	
	wx.wxBeginBusyCursor()
	
	-- reset the cursor position
	--
	m_MainFrame.iCursor			= 1
	m_MainFrame.iByteFirstRow	= 0
	m_MainFrame.iByteRowCount	= 0
	m_MainFrame.iTextFirstRow	= 0
	m_MainFrame.iTextRowCount	= 0
	m_MainFrame.iStopLine		= -1
	
	local iBytes, sText = thisApp.LoadFile()
	
	if 0 == iBytes then 
		m_MainFrame.iCursor = 0
		SetWindowTitle()
	else
		SetWindowTitle(thisApp.tConfig.InFile)
	end
	
	Refresh()
	
	SetStatusText("" .. m_MainFrame.iCursor, 5)
	SetStatusText("" .. m_MainFrame.iStopLine, 4)
	SetStatusText(sText, 2)
	
	wx.wxEndBusyCursor()
end

-- ----------------------------------------------------------------------------
-- save memory to file
--
local function OnSaveFile()
--	trace.line("OnSaveFile")

	wx.wxBeginBusyCursor()
	
	local _, sText = thisApp.SaveFile()
	
	SetStatusText(sText, 2)
	
	wx.wxEndBusyCursor()
end

-- ----------------------------------------------------------------------------
--
local function OnCheckEncoding()
--	trace.line("OnCheckEncoding")

	wx.wxBeginBusyCursor()
	
	local _, sText = thisApp.CheckEncoding()
	
	SetStatusText(sText, 2)
	
	wx.wxEndBusyCursor()
end

-- ----------------------------------------------------------------------------
--
local function OnCreateSamples()
--	trace.line("OnCreateSamples")
	
	wx.wxBeginBusyCursor()
	
	local bRet = thisApp.CreateSamples()
	
	if bRet then
		SetStatusText("Samples file created", 2)
	else
		SetStatusText("Samples fle creation failed", 2)
	end
	
	wx.wxEndBusyCursor()
end

-- ----------------------------------------------------------------------------
--
local function OnCreateByBlock()
--	trace.line("OnCreateByBlock")
	
	wx.wxBeginBusyCursor()
	
	local bRet = thisApp.CreateByBlock()
	
	if bRet then
		SetStatusText("Samples file created", 2)
	else
		SetStatusText("Samples fle creation failed", 2)
	end
	
	wx.wxEndBusyCursor()
end

-- ----------------------------------------------------------------------------
-- align view of file based on the current cursor position
--
local function AlignBytesToCursor(inNewValue)
--	trace.line("AlignBytesToCursor")

	local iNumCols	= thisApp.tConfig.Columns
	local iLimit	= thisApp.iFileBytes
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
--
local function OnEncode_UTF_8()
--	trace.line("OnEncode_UTF_8")

	wx.wxBeginBusyCursor()
	
	local _, sText = thisApp.Encode_UTF_8()
	
	-- do a complete redraw
	--
	AlignBytesToCursor(m_MainFrame.iCursor)

	Refresh()
	
	SetStatusText("" .. m_MainFrame.iCursor, 5)
	SetStatusText("" .. m_MainFrame.iStopLine, 4)
	
	SetStatusText(sText, 2)
	
	wx.wxEndBusyCursor()
end

-- ----------------------------------------------------------------------------
-- get the cell selected by the user
-- this function works only if a monospaced font is used for the bytes pane
--
local function OnLeftBtnDown(event)
--	trace.line("OnLeftBtnDown")

	if 0 >= thisApp.iFileBytes then return end

	-- get the position where the users made a choice
	--
	local iOffX		 = m_MainFrame.iOffsetX
	local iOffY		 = m_MainFrame.iOffsetY
	local iSpacerX	 = m_MainFrame.iLeftSpacerX
	local iSpacerY	 = m_MainFrame.iLeftSpacerY

	local dcClient	 = m_MainFrame.hMemoryDC
	local iPtX, iPtY = event:GetLogicalPosition(dcClient):GetXY()

	-- check for the pane's boundaries
	--
	local iNumCols	= thisApp.tConfig.Columns
	local rcWidth	= iSpacerX * iNumCols + iOffX
	local rcHeight	= iSpacerY * (m_MainFrame.iByteRowCount + 1) -- - iOffY

	if iOffX > iPtX then return end
	if iOffY > iPtY then return end	
	if iPtX  > rcWidth then return end
	if iPtY  > rcHeight then return end
	
	-- align to offsets
	--
	iPtX = iPtX + iOffX
	iPtY = iPtY - iOffY

	-- get the cell (row,col)
	-- align to rectangle boundary
	--
	local iRow = _floor((iPtY - iPtY % iSpacerY) / iSpacerY)
	local iCol = _floor((iPtX + iPtX % iSpacerX) / iSpacerX)

	-- get the logical selection
	--	
	local iFirstByte = m_MainFrame.iByteFirstRow * iNumCols	
	local iNewCursor = iFirstByte + iCol + iRow * iNumCols

	-- query refresh if new selection
	--
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

	if 0 == thisApp.iFileBytes then return end
	
	local iCurrent	= m_MainFrame.iCursor
	local iNumCols	= thisApp.tConfig.Columns
	local iLines	= thisApp.tConfig.WheelMult
	local iScroll	= iNumCols * iLines		-- works reversed
	
	-- works reversed
	--
	if 0 < event:GetWheelRotation() then iScroll = -1 * iScroll end
	
	iLines = iCurrent + iScroll
	
	if m_MainFrame.iCursor ~= iLines then
		
		AlignBytesToCursor(iLines)
	
		Refresh()
	
		SetStatusText("" .. m_MainFrame.iCursor, 5)
		SetStatusText("" .. m_MainFrame.iStopLine, 4)
	end
end

-- ----------------------------------------------------------------------------
--
local function OnKeyDown(event)
--	trace.line("OnKeyDown")

	if 0 >= thisApp.iFileBytes then return end
	
	local iCursor	= m_MainFrame.iCursor
	local iNumCols	= thisApp.tConfig.Columns
	local iPgJump	= _floor((iNumCols * m_MainFrame.iByteRowCount) / 1)
	
	local key	= event:GetKeyCode()
	local ctrl	= event:ControlDown()
	local shift	= event:ShiftDown()

	if wx.WXK_LEFT == key then
		iCursor = iCursor - 1

	elseif wx.WXK_RIGHT == key then
		iCursor = iCursor + 1

	elseif wx.WXK_UP == key then
		iCursor = iCursor - iNumCols

	elseif wx.WXK_DOWN == key then
		iCursor = iCursor + iNumCols

	elseif wx.WXK_PAGEDOWN == key then
		if shift then
			iCursor = iCursor + iPgJump * 3
		else
			iCursor = iCursor + iPgJump
		end		

	elseif wx.WXK_PAGEUP == key then
		if shift then
			iCursor = iCursor - iPgJump * 3
		else
			iCursor = iCursor - iPgJump
		end
		
	elseif wx.WXK_HOME == key then
		if ctrl then 
			iCursor = 1 									-- start of file
		else 
			iCursor = iCursor - ((iCursor - 1) % iNumCols) 	-- start of line
		end

	elseif wx.WXK_END == key then
		if ctrl then 
			iCursor = thisApp.iFileBytes 					-- end of file
		else 
			if 0 ~= (iCursor % iNumCols) then				-- end of line
				iCursor = iCursor + (iNumCols - (iCursor % iNumCols)) 
			end
				
		end

	else
		return
	end
	
	if iCursor ~= m_MainFrame.iCursor then
		
		AlignBytesToCursor(iCursor)

		Refresh()
	
		SetStatusText("" .. m_MainFrame.iCursor, 5)
		SetStatusText("" .. m_MainFrame.iStopLine, 4)
	end
end

-- ----------------------------------------------------------------------------
-- one time initialization of tick timers and the frame's timer
-- the lower the frame's timer interval the more accurate are the tick timers
--
local function InstallTimers()
	
	if not m_MainFrame.hWindow then return false end
	if m_MainFrame.hTickTimer then return true end
	
	if not tTimers.Display:IsEnabled() then
		
		local iInterval = thisApp.tConfig.TimeDisplay
		if 1 >= iInterval then iInterval = 2 end
		
		tTimers.Display:Setup(iInterval, false)
	end
	
	if not tTimers.Garbage:IsEnabled() then
		
		tTimers.Garbage:Setup(2, true)
	end
	
	-- create and start a timer object
	--
	m_MainFrame.hTickTimer = wx.wxTimer(m_MainFrame.hWindow, wx.wxID_ANY)
	m_MainFrame.hTickTimer:Start(500, false)
	
	return true
end

-- ----------------------------------------------------------------------------
-- check each timer and fire an action if interval has elapsed
--
local function OnTimer()
--	trace.line("OnTimer")
	
	-- this is to cleanup the statusbar message
	--
	if tTimers.Display:HasFired() then
		
		-- cleanup the status bar
		-- (timer fires once only)
		--
		SetStatusText(nil, 2)
		tTimers.Display:Enable(false)		
	end
	
	-- this is to release memory via the GC
	--
	if tTimers.Garbage:HasFired() then
		
		-- perform a cycle of garbage colleting
		-- (if necessary)
		--
		thisApp.GarbageTest()
		tTimers.Garbage:Reset()		
	end	
end

-- ----------------------------------------------------------------------------
--[
--
local function OnSize(event)
--	trace.line("OnSize")

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
	RefreshSlides()
	Refresh()
	
	SetStatusText("" .. m_MainFrame.iCursor, 5)
	SetStatusText("" .. m_MainFrame.iStopLine, 4)
end

-- ----------------------------------------------------------------------------
-- allocate the fonts
--
local function SetupDisplay()
--	trace.line("SetupDisplay")

	-- font properties read from the config file
	--
	local specBytes = thisApp.tConfig.ByteFont
	local specText  = thisApp.tConfig.TextFont
	local tScheme	= tSchemeLight
	local tFmtBytes = tFormat.Dec	
	
	-- allocate
	--
	local fBytes = wx.wxFont(specBytes[1], wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL,
									 wx.wxFONTWEIGHT_NORMAL, false, specBytes[2], wx.wxFONTENCODING_SYSTEM)
					
	local fText  = wx.wxFont(specText[1], wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL,
									 wx.wxFONTWEIGHT_NORMAL, false, specText[2], wx.wxFONTENCODING_SYSTEM)
		
	-- format string to use (oct/dec/hex)
	-- defaults to decimal
	--
	for tag, tFormat in pairs(tFormat) do
		if _find(thisApp.tConfig.Format, tag, 1, true) then tFmtBytes = tFormat break end
	end	
	
	-- colours setup
	--
	if "White" == thisApp.tConfig.Scheme 	 then tScheme = tSchemeWhite
	elseif "Dark" == thisApp.tConfig.Scheme  then tScheme = tSchemeDark
	elseif "Black" == thisApp.tConfig.Scheme then tScheme = tSchemeBlack end

	-- prealloc the pens and brushes
	--
	penLF = wx.wxPen(tScheme.Linefeed, 3, wx.wxSOLID)
	penXX = wx.wxPen(tScheme.Unprintable, 3, wx.wxSOLID)
	brMrk = wx.wxBrush(tScheme.MarkStart, wx.wxSOLID)
	brHBt = wx.wxBrush(tScheme.HighBits, wx.wxSOLID)
	brCur = wx.wxBrush(tScheme.LeftCursor, wx.wxSOLID)
	
	brStp = wx.wxBrush(tScheme.StopRow, wx.wxSOLID)
	brUnd = wx.wxPen(tScheme.RightCursor, 6, wx.wxSOLID)	

	-- time interval for displaying messages
	--
	local iShowTime = _floor(thisApp.tConfig.TimeDisplay * 1000)
	if 500 > iShowTime then iShowTime = 1500 end
	
	-- replace tabulation with spaces
	--
	local iTabSize	= thisApp.tConfig.TabSize
	local sTabRep = _strrep(" ", iTabSize)
	
	-- setup
	--
	m_MainFrame.hFontBytes	 = fBytes
	m_MainFrame.hFontText	 = fText
	m_MainFrame.tFormatBytes = tFmtBytes
	m_MainFrame.tColourScheme= tScheme
	m_MainFrame.iTmInterval	 = iShowTime
	m_MainFrame.sTabReplace	 = sTabRep
	m_MainFrame.iLeftSpacerX = 0				-- ask for a recalc of spacing
	
	-- redraw
	--
	m_MainFrame.hSlidesDC = NewSlidesDC()
	m_MainFrame.hMemoryDC = NewMemDC()

	return (fBytes and fText)
end

-- ----------------------------------------------------------------------------
-- issue to import again the settings file
--
local function OnRefreshSettings()
	
	if false == thisApp.ReadSetupInf() then
		SetStatusText("Cannot load settings", 2)
		return
	end
	
	if false == SetupDisplay() then
		SetStatusText("Cannot set fonts", 2)
		return
	end
	
	-- query a repaint
	--
	RefreshSlides()
	Refresh()
	
	SetStatusText("" .. m_MainFrame.iCursor, 5)
	SetStatusText("" .. m_MainFrame.iStopLine, 4)
	
	SetStatusText("Configuration has been reloaded", 2)
end

-- ----------------------------------------------------------------------------
-- handle the show window event, starts the timer
--
local function OnShow(event)
	if not m_MainFrame.hWindow then return end
	
	if event:GetShow() then
		
		m_MainFrame.bVisible = true
		Refresh()
		
		if not m_MainFrame.hTickTimer then
			
			-- allocate the tick timers
			--
			InstallTimers()
		end
	else
		m_MainFrame.bVisible = false
	end
	
end

-- ----------------------------------------------------------------------------
-- create the main window
--
local function CreateMainWindow()
--	trace.line("CreateMainWindow")

	wx.wxBeginBusyCursor()
	
	-- read deafult positions for the dialogs
	--
	ReadSettings()
  
	-- unique IDs for the menu
	--  
	local rcMnuReadFile = UniqueID()
	local rcMnuSaveFile = UniqueID()
	local rcMnuSamples  = UniqueID()
	local rcMnuByBlock  = UniqueID()
	local rcMnuCheckFmt = UniqueID()
	local rcMnuEncUTF8  = UniqueID()
	local rcMnuSettings = UniqueID()

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
	mnuFile:Append(rcMnuReadFile, "Import File\tCtrl-I",	  "Read the file in memory")
	mnuFile:Append(rcMnuSaveFile, "Export File\tCtrl-E",	  "Save memory to file")
	mnuFile:Append(rcMnuEncUTF8,  "Encode UTF_8\tCtrl-U",	  "Write the file encoded UTF_8")
	mnuFile:AppendSeparator()
	
	mnuFile:Append(rcMnuSettings, "Refresh settings\tCtrl-R", "Import settings again and refresh")	
	mnuFile:Append(wx.wxID_EXIT,  "E&xit\tAlt-X",		  	  "Quit the application")
	
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
	mnuCmds:Append(rcMnuSamples,  "Create Std samples\tCtrl-S",   "Create the STANDARD samples test file")
	mnuCmds:Append(rcMnuByBlock,  "Create Block samples\tCtrl-B", "Create the BY BLOCK samples test file")

	-- create the HELP menu
	--
	local mnuHelp = wx.wxMenu("", wx.wxMENU_TEAROFF)  
	mnuHelp:Append(wx.wxID_ABOUT, "&About\tAlt-A", "About the application")

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
	hStatusBar:SetMinHeight(200)
	
	-- standard event handlers
	--
	frame:Connect(wx.wxEVT_SHOW,			OnShow)
	frame:Connect(wx.wxEVT_PAINT,			OnPaint)
	frame:Connect(wx.wxEVT_TIMER,			OnTimer)
	frame:Connect(wx.wxEVT_SIZE,			OnSize)
	frame:Connect(wx.wxEVT_KEY_DOWN,		OnKeyDown)
	frame:Connect(wx.wxEVT_LEFT_DOWN,		OnLeftBtnDown)
	frame:Connect(wx.wxEVT_MOUSEWHEEL,		OnMouseWheel)	
	frame:Connect(wx.wxEVT_CLOSE_WINDOW,	OnClose)

	-- menu event 
	--
	frame:Connect(rcMnuReadFile, wx.wxEVT_COMMAND_MENU_SELECTED, OnReadFile)
	frame:Connect(rcMnuSaveFile, wx.wxEVT_COMMAND_MENU_SELECTED, OnSaveFile)
	frame:Connect(rcMnuSamples,  wx.wxEVT_COMMAND_MENU_SELECTED, OnCreateSamples)
	frame:Connect(rcMnuByBlock,  wx.wxEVT_COMMAND_MENU_SELECTED, OnCreateByBlock)
	frame:Connect(rcMnuCheckFmt, wx.wxEVT_COMMAND_MENU_SELECTED, OnCheckEncoding)
	frame:Connect(rcMnuEncUTF8,	 wx.wxEVT_COMMAND_MENU_SELECTED, OnEncode_UTF_8)
	frame:Connect(rcMnuSettings, wx.wxEVT_COMMAND_MENU_SELECTED, OnRefreshSettings)
	frame:Connect(wx.wxID_EXIT,	 wx.wxEVT_COMMAND_MENU_SELECTED, OnClose)
	frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED, OnAbout)
	
	frame:Connect(rcMnuEdCut,	 wx.wxEVT_COMMAND_MENU_SELECTED, OnEditCut)
	frame:Connect(rcMnuEdCopy,   wx.wxEVT_COMMAND_MENU_SELECTED, OnEditCopy)
	frame:Connect(rcMnuEdPaste,  wx.wxEVT_COMMAND_MENU_SELECTED, OnEditPaste)
	frame:Connect(rcMnuEdSelAll, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditSelectAll)
	
	-- assign an icon
	--
	local icon = wx.wxIcon(thisApp.sIconFile, wx.wxBITMAP_TYPE_ICO)
	frame:SetIcon(icon)
		
	-- set up the frame
	--
	frame:SetMinSize(wx.wxSize(500, 250))  
	frame:SetStatusBarPane(1)                   -- this is reserved for the menu
	frame:SetAutoLayout(true)
	frame:SetFocus()
	
	-- this is necessary to avoid flickering
	-- (comment the line if running with the debugger)
	--
	frame:SetBackgroundStyle(wx.wxBG_STYLE_CUSTOM)
	
	--  store for later
	--
	m_MainFrame.hWindow 	= frame	
	m_MainFrame.hStatusBar	= hStatusBar
	
	wx.wxEndBusyCursor()
	
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
	if not SetupDisplay() then return false end
	
	-- display
	--
	m_MainFrame.hWindow:Show(true)
		
	-- display the release
	--
	SetStatusText(thisApp.sAppName .. " [" .. thisApp.sAppVersion .. "]", 1)
	
	-- if a file was automatically loaded then display
	--
	if 0 < thisApp.iFileBytes then	
		SetWindowTitle(thisApp.tConfig.InFile) 
		m_MainFrame.iCursor = 1						-- this is a fix
	end
	
	-- run the main loop
	--
	wx.wxGetApp():MainLoop()	
end

-- ----------------------------------------------------------------------------
--
local function CloseMainWindow()
--	trace.line("CloseMainWindow")

	OnClose()
	SaveSettings(m_sSettingsIni, tWinProp) 
end

-- ----------------------------------------------------------------------------
--
return
{
	Show	= ShowMainWindow,
	Close	= CloseMainWindow,
	Title	= SetWindowTitle
}

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
