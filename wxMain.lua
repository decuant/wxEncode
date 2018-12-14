-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
--
--  wxMain - main window for the application
--
-- ----------------------------------------------------------------------------

local wx 		= require "wx"			-- uses wxWidgets for Lua 5.2
local palette	= require "wxPalette"	-- common colours definition in wxWidgets
local trace 	= require "trace"		-- shortcut for tracing
local ticktime  = require "ticktimer"	-- timer object constructor
local wxLoupe 	= require "wxLoupe"		-- display magnification of current char
local wxCalc	= require "wxCalc"		-- dialog for conversion bytes <-> Unicode
local wxFind	= require "wxFind"		-- find text within the file

local _floor	= math.floor
local _format	= string.format
local _find		= string.find
local _strrep	= string.rep
local _byte		= string.byte
local _concat	= table.concat

-- ----------------------------------------------------------------------------
-- status bar panes width
--
local tStbarWidths =
{
	180, 			-- application
	750, 			-- message
	100,			-- file check format
	90,				-- current line
	160,			-- cursor position
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

	["Gutter"] 		= palette.Gray70,
	["SlideActive"] = palette.Black,
	
	["LoupeBack"]	= palette.White,
	["LoupeFore"]	= palette.Black,
	
	["DialogsBack"] = palette.Gray90,
	["DialogsFore"] = palette.Black,	
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
	
	["Gutter"] 		= palette.Snow3,
	["SlideActive"] = palette.Black,

	["LoupeBack"]	= palette.Seashell2,
	["LoupeFore"]	= palette.Gray30,
	
	["DialogsBack"] = palette.Cornsilk,
	["DialogsFore"] = palette.Black,		
}

local tSchemeDark =
{
	["LeftBack"]	= palette.SlateBlue4,
	["ColourColumn"]= palette.NavyBlue,
	["LeftText"]	= palette.Gray75,
	["LeftCursor"]	= palette.VioletRed1,
	["Linefeed"]	= palette.Gray80,
	["Unprintable"]	= palette.Magenta,
	["MarkStart"]	= palette.Sienna,
	["HighBits"]	= palette.SeaGreen4,
	
	["RightBack"]	= palette.DarkSlateGray,
	["RightText"]	= palette.Gray70,
	["RightCursor"]	= palette.Azure1,	
	["VerticalBar"]	= palette.Ivory3,
	["StopRow"]		= palette.Firebrick4,
	
	["Gutter"] 		= palette.SteelBlue2,
	["SlideActive"] = palette.SlateBlue1,

	["LoupeBack"]	= palette.DarkSlateGray,
	["LoupeFore"]	= palette.White,
	
	["DialogsBack"] = palette.NavyBlue,
	["DialogsFore"] = palette.White,	
}

local tSchemeBlack =
{
	["LeftBack"]	= palette.Gray15,
	["ColourColumn"]= palette.Gray35,
	["LeftText"]	= palette.Gray90,
	["LeftCursor"]	= palette.SeaGreen3,
	["Linefeed"]	= palette.Thistle1,
	["Unprintable"]	= palette.Magenta,
	["MarkStart"]	= palette.SlateBlue,
	["HighBits"]	= palette.DarkGoldenrod,
	
	["RightBack"]	= palette.Black,
	["RightText"]	= palette.Gray80,
	["RightCursor"]	= palette.LightGoldenrod,	
	["VerticalBar"]	= palette.Tan,
	["StopRow"]		= palette.IndianRed4,
	
	["Gutter"] 		= palette.MediumSlateBlue,
	["SlideActive"] = palette.MediumAquamarine,
	
	["LoupeBack"]	= palette.Black,
	["LoupeFore"]	= palette.Gray90,
	
	["DialogsBack"] = palette.Gray15,
	["DialogsFore"] = palette.White,	
}

-- ----------------------------------------------------------------------------
-- prealloc pens and brushes
--
local m_PenNull = wx.wxPen(palette.Black, 1, wx.wxTRANSPARENT)

-- bytes pane
--
local penLF = wx.wxPen(tSchemeWhite.Linefeed, 3, wx.wxSOLID)
local penXX = wx.wxPen(tSchemeWhite.Unprintable, 3, wx.wxSOLID)
local brMrk = wx.wxBrush(tSchemeWhite.MarkStart, wx.wxSOLID)
local brHBt = wx.wxBrush(tSchemeWhite.HighBits, wx.wxSOLID)
local brCur = wx.wxBrush(tSchemeWhite.LeftCursor, wx.wxSOLID)

-- text pane
--
local penUnd= wx.wxPen(tSchemeWhite.RightCursor, 6, wx.wxSOLID)
local brStp	= wx.wxBrush(tSchemeWhite.StopRow, wx.wxSOLID)
local penBar= wx.wxPen(tSchemeWhite.VerticalBar, 1, wx.wxSOLID)
local brBar	= wx.wxBrush(tSchemeWhite.VerticalBar, wx.wxSOLID)

-- ----------------------------------------------------------------------------
-- format to use for the bytes pane
-- (the 2nd element is a precalc of the lenght)
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
-- ticktimers
--
local tTimers =
{
	-- name        interval		last fired
	--
	["Display"] = ticktime.new("Display"),
	["Garbage"] = ticktime.new("Garbage"),
}

-- ----------------------------------------------------------------------------
-- window's private members
--
local m_MainFrame = 
{
	hWindow			= nil,	-- main frame
	hLoupe			= nil,	-- loupe window
	hCalcUni		= nil,	-- calculator window
	hFindText		= nil,	-- find text window
	bVisible		= false,-- last visibile status
	hStatusBar		= nil,	-- the status bar
	hSlidesDC		= nil,	-- background for the 2 slides
	hMemoryDC		= nil,	-- device context for the window	
	hTickTimer		= nil,	-- timer for messages in the statusbar
	iTmInterval		= 3000,	-- diplay msg on status bar for much time

	hFontBytes		= nil,	-- the font for the bytes (left) pane
	hFontText		= nil,	-- the font for the text (right) pane
	tColourScheme	= tSchemeLight, -- assign colours' table
	iCurrentSlide	= 1,	-- the slide being selected

	rcClientW		= 0,	-- client rect width
	rcClientH		= 0,	-- client rect height
	iOffsetX		= 6,	-- offset for writing text
	iOffsetY		= 14,	-- offset for writing text
	
	iLeftMonoWidth	= 0,	-- pixels for 1 byte display
	iLeftSpacerX	= 0,	-- pixels for formatted string (oct/dec/hex)
	iLeftSpacerY	= 0,	-- pixels for the height
	
	iRightSpacerX	= 0,	-- not used
	iRightSpacerY	= 0,	-- height in pixels of character
	
	iCursor			= 0,	-- where the cursor is
	tFormatBytes	= nil,	-- format string for the bytes display
	sTabReplace		= "",	-- replacement for tab on text slide
	iByteRowCount	= 0,	-- number of visibles rows
	iByteFirstRow	= 0,	-- first row visible, left rect
	
	iTextRowCount	= 0,	-- number of visible rows
	iTextFirstRow	= 0,	-- first row visible, right rect
	iStopLine		= -1,	-- line where the cursor is in
	iStopStart		= 0,	-- byte offset of stopline in buffer
	
	sCurrCharacter	= "",	-- current character (1 to 4 bytes)
}

-- ----------------------------------------------------------------------------
-- default dialogs' rectangles andvisibility
--
local m_WinIni = "winini.lua"
local tWindows = nil

-- ----------------------------------------------------------------------------
-- flags in use for the main frame
--
local dwFrameFlags = bit32.bor(wx.wxDEFAULT_FRAME_STYLE, wx.wxCAPTION)
	  dwFrameFlags = bit32.bor(dwFrameFlags, wx.wxSYSTEM_MENU)
	  dwFrameFlags = bit32.bor(dwFrameFlags, wx.wxCLOSE_BOX)

-- ----------------------------------------------------------------------------
-- load configuration for the windows' rectangle and visibility
-- (set visibility with 1 = true)
--
local function LoadDlgRects()
--	trace.line("LoadDlgRects")

	local fhSrc = io.open(m_WinIni, "r")
	if fhSrc then
		fhSrc:close()
		tWindows = dofile(m_WinIni)
	end
	
	if not tWindows then
		
		tWindows = 
		{
			["Main"]	= {   0,   0, 1000, 1500, 1},
			["Loupe"]	= {1000, 650,  500,  560, 0},
			["Calc"]	= {1000, 150,  500,  280, 0},
			["Find"]	= {1000, 430,  500,  250, 0},
		}		
	end
end

-- ----------------------------------------------------------------------------
-- format 
local function DlgRect2Lua(inLabel, inFrame, inConfig)

	local t = inConfig
	
	if inFrame then
			
		local iPosX		= inFrame:GetPosition().x
		local iPosY  	= inFrame:GetPosition().y
		local iWidth  	= inFrame:GetSize():GetWidth()
		local iHeight 	= inFrame:GetSize():GetHeight()
		local iVisible	= 0
		
		if inFrame:IsShown() then iVisible = 1 end
		
		-- correct negative offsets
		--
		if 0 > iPosX then iPosX	= 0 end
		if 0 > iPosY then iPosY	= 0 end
		
		-- check minimum sizes
		--
		if 0 >= iWidth  then iWidth  = 50 end
		if 0 >= iHeight then iHeight = 50 end
		
		t = {iPosX, iPosY, iWidth, iHeight, iVisible}
	end
	
	-- returned line of text
	--	
	sLine = "{" .. _concat(t, ", ") .. "},\n"
--	sLine = "{" .. t[1] .. ", " .. t[2] .. ", " .. t[3] .. ", " .. t[4] .. ", " .. t[5] .. "},\n"
	sLine = "\t[\"" .. inLabel .. "\"]\t= " .. sLine
	
	return sLine
end

-- ----------------------------------------------------------------------------
-- save configuration for the windows' position and size
--
local function SaveDlgRects()
--	trace.line("SaveDlgRects")

	local  fhTgt = io.open(m_WinIni, "w")
	if not fhTgt then  return false end
	
	local sSep	= "-- " .. _strrep("-", 77) .. "\n"
	local sLine
	
	fhTgt:write(sSep)
	sLine = "-- last used dialogs\' rectangles\n--\n\n"
	fhTgt:write(sLine)
	
	-- start of table's defintion
	--
	sLine = "local tWindows = \n{\n"
	fhTgt:write(sLine)
	
	sLine = DlgRect2Lua("Main", m_MainFrame.hWindow, tWindows.Main)
	fhTgt:write(sLine)
	
	sLine = DlgRect2Lua("Loupe", m_MainFrame.hLoupe, tWindows.Loupe)
	fhTgt:write(sLine)
	
	sLine = DlgRect2Lua("Calc", m_MainFrame.hCalcUni, tWindows.Calc)
	fhTgt:write(sLine)
	
	sLine = DlgRect2Lua("Find", m_MainFrame.hFindText, tWindows.Find)
	fhTgt:write(sLine)
	
	-- end of table's defintion
	--
	sLine = "}\n\nreturn tWindows\n\n"
	fhTgt:write(sLine)
	
	fhTgt:write(sSep)
	fhTgt:write(sSep)
	fhTgt:close()
	return true
end	

-- ----------------------------------------------------------------------------
-- get the correct spacing
--
local function CalcFontSpacing(inDrawDC)
--	trace.line("CalcFontSpacing")

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
-- if no text then it will be not shown
--
local function DrawVerticalBar(inDrawDC)
--	trace.line("DrawVerticalBar")

	if not inDrawDC then return end
	if 0 == thisApp.iFileBytes then return end

	-- get the correct spacing here
	-- 	
	local iSpacerY	= m_MainFrame.iRightSpacerY
	local iOffY 	= m_MainFrame.iOffsetY
	local iHeight	= m_MainFrame.rcClientH - iOffY * 2
	
	local iNumRows	= #thisApp.tFileLines
	local iVIORows	= m_MainFrame.iTextRowCount
	local iCurPage	= (m_MainFrame.iTextFirstRow / iVIORows)
	local iTotPages	= (iNumRows / iVIORows)
	local iPageLen	= (iHeight / iTotPages)
	local iPosY		= (iPageLen * iCurPage)
			
	-- just fix it when too small
	-- (it affects only the appereance)
	--
	iPageLen = math.max(iPageLen, 25)
	
	-- draw a rect for the bar itself and a line all through the slide's height
	--
	inDrawDC:SetPen(penBar)
	inDrawDC:SetBrush(brBar)
	
	inDrawDC:DrawRectangle(m_MainFrame.rcClientW - 20, iOffY, 2, iHeight)
	inDrawDC:DrawRectangle(m_MainFrame.rcClientW - 30, iPosY, 20, iPageLen)
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
-- drawing the left pane
--
local function DrawBytes(inDrawDC)
--	trace.line("DrawBytes")
	
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
		
	-- this is the number of visible rows in the drawing area
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
	-- fill tables to flush
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
	local tCurrLine	 = tFile[iFileIndex]
	local iCurColumn = 1
	local iBufIndex  = iOffset - tCurrLine[1] + 1
	local sSpaceSub  = _strrep(" ", tFmtBytes[2])
	local bHideSpace = thisApp.tConfig.HideSpaces
	local sToDraw
	local ch
	
	while tCurrLine do
		
		while iNumCols >= iCurColumn do
			
			if #tCurrLine[2] < iBufIndex then
				
				-- query next row in table
				--
				iFileIndex	= iFileIndex + 1
				tCurrLine	= tFile[iFileIndex]
				iBufIndex	= 1
				
				-- safety check
				--
				if not tCurrLine then break end				
			end
			
			ch = tCurrLine[2]:byte(iBufIndex)
			
			-- check for replacing the space byte
			--
			if bHideSpace and 0x20 == ch then 
				sToDraw = sSpaceSub
			else
				sToDraw = _format(tFmtBytes[1], ch)
			end
			
			tChars[#tChars + 1] = sToDraw		-- add string to coll.
			
			-- highlight chars
			--				
			if (0x20 > ch) or (0x7f < ch) or (tCurrLine[1] + iBufIndex) == iCursor then
				
				local xPos = iCurX + ((iCurColumn - 1) * iSpacerX * tFmtBytes[2])
				local yPos = iCurY + iSpacerY - 3
				local xLen = iSpacerX * (tFmtBytes[2] - 1)
				
				if bUnderline then
					if 0x0a == ch 	 then tDraw1[#tDraw1 + 1] = {xPos, yPos, xPos + xLen, yPos}
					elseif 0x20 > ch then tDraw2[#tDraw2 + 1] = {xPos, yPos, xPos + xLen, yPos} end
				end
				
				if bUnicode then
					if 0xbf < ch 	 then tDraw3[#tDraw3 + 1] = {xPos, iCurY, xLen, iSpacerY}
					elseif 0x7f < ch then tDraw4[#tDraw4 + 1] = {xPos, iCurY, xLen, iSpacerY} end
				end
				
				-- draw the cursor
				-- (make it slightly bigger)
				--
				if (tCurrLine[1] + iBufIndex) == iCursor then tDraw5 = {xPos - 2, iCurY - 2, xLen + 4, iSpacerY + 4} end				
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
			inDrawDC:DrawRectangle(tDraw5[1], tDraw5[2], tDraw5[3], tDraw5[4])
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
-- drawing the right pane
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
--	local iStopOffset	= -1
--	local iStopLength	= 0

	
--	iExtEnd = iExtEnd + iNumSubs * #sTabRep - iNumSubs	
	
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
	local iLowLimit= m_MainFrame.rcClientH - (iOffY * 2) - iSpacerY			-- drawing height bound
	local iNumRows = _floor(iLowLimit / iSpacerY)							-- allowed rows
	
	-- update
	--
	iOffY	  = math.ceil(((iLowLimit - (iSpacerY * iNumRows)) / 2))		-- vertical offset updated
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
	
	-- set the clipping region
	--
	inDrawDC:SetClippingRegion(iCurX, iOffY, m_MainFrame.rcClientW - iCurX - 20, m_MainFrame.rcClientH - 10)
	
	------------------
	-- print all chars
	--
	iCurX = iCurX + iOffX
	iCurY = iOffY -- + iSpacerY
	
	-- highlight the background of the stopline
	--
	if 0 < iStopLine then
		
		local pStartX	= iCurX
		local pStartY	= iOffY + (iStopLine - iFirstRow) * iSpacerY
		local iWidth	= m_MainFrame.rcClientW - pStartX
		local iHeight	= iSpacerY
		
		inDrawDC:SetPen(m_PenNull)
		inDrawDC:SetBrush(brStp)
		inDrawDC:DrawRectangle(pStartX, pStartY, iWidth, iHeight)		
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
	
	-- here the trick to handle tab(s) conversion to spaces
	--
	local iOffset	= m_MainFrame.iCursor - tCurrent[1]
	local sExtract  -- = tCurrent[2]:sub(1, iOffset - 1)	
--	local iExtEnd
	local iNumSubs	
			
	local iStopOffset = -1
	local iRoller1 = iOffset -- + 1
	
	while 0 >= iStopOffset and 0 < iRoller1 do
		
		iRoller1  = iRoller1 - 1
		sExtract  = tCurrent[2]:sub(1, iRoller1)	
		sExtract, iNumSubs = sExtract:gsub("\t", sTabRep)
		
		iStopOffset = inDrawDC:GetTextExtent(sExtract)
	end
	
	local iStopLength = -1
	local iRoller2 = iOffset + 1
	
	while 0 >= iStopLength and 0 < iRoller2 do
		
		iRoller2	= iRoller2 - 1
		sExtract 	= tCurrent[2]:sub(iRoller2, iOffset)
		
		iStopLength = inDrawDC:GetTextExtent(sExtract)	
	end
	
	-- underline the corresponding letter for the cursor
	--
	if 0 < iStopLength then
		
		local pStartX	= iCurX + iStopOffset
		local pStartY	= iOffY + (iStopLine - iFirstRow + 1) * iSpacerY
		local pEndX		= pStartX + iStopLength
		local pEndY		= pStartY
		
		inDrawDC:SetPen(penUnd)
		inDrawDC:DrawLine(pStartX, pStartY, pEndX, pEndY)		
	end

	-- remove clipping
	--
	inDrawDC:DestroyClippingRegion()
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
	if 0 > inCellNo or #tStbarWidths < inCellNo then inCellNo = 1 end
	
	hCtrl:SetStatusText(inText, inCellNo)

	-- start a one-shot timer
	--
	if 1 == inCellNo and 0 < #inText then 
		tTimers.Display:Reset()
		tTimers.Display:Enable(true) 
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
	
	local m_Frame = m_MainFrame.hWindow
	if not m_Frame then return end

	wx.wxGetApp():Disconnect(wx.wxEVT_TIMER)
	
	SaveDlgRects()
	
	if m_MainFrame.hLoupe then
		wxLoupe.Close()
		m_MainFrame.hLoupe = nil
	end
	
	if m_MainFrame.hCalcUni then
		wxCalc.Close()
		m_MainFrame.hCalcUni = nil
	end
	
	if m_MainFrame.hFindText then
		wxFind.Close()
		m_MainFrame.hFindText = nil
	end

	-- finally destroy the window
	--
	m_Frame.Destroy(m_Frame)
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
	local iLeftW = iRectW

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
	iCurX	= iLeftW

	-- get the correct spacing here
	--
	iSpacerX = m_MainFrame.iRightSpacerX
	iSpacerY = m_MainFrame.iRightSpacerY

	-- bounds
	--
	iRectW	= m_MainFrame.rcClientW - iLeftW - 8
	iRectH	= m_MainFrame.rcClientH - 28

	-- background colour
	--
	inDrawDC:SetPen(m_PenNull)	
	inDrawDC:SetBrush(wx.wxBrush(tScheme.RightBack, wx.wxSOLID))
	inDrawDC:DrawRectangle(iCurX, 0, iRectW, iRectH)
	
	-- gutter
	--
	inDrawDC:SetBrush(wx.wxBrush(tScheme.Gutter, wx.wxSOLID))
	inDrawDC:DrawRectangle(iCurX - iOffX / 2, 0, iOffX, iRectH)

	-- check if the current slide
	--
	inDrawDC:SetPen(wx.wxPen(tScheme.SlideActive, 4, wx.wxSOLID))
	
	if 1 == m_MainFrame.iCurrentSlide then
		
		inDrawDC:DrawLine(0, 2, iLeftW, 2)
		
	elseif 2 == m_MainFrame.iCurrentSlide then
		
		inDrawDC:DrawLine(iCurX, 2, iCurX + iRectW, 2)
		
	end
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
-- setup GDI objects following the user's preferences
-- as per stupinf.lua
--
local function SetupDisplay()
--	trace.line("SetupDisplay")

	-- font properties read from the config file
	--
	local specBytes = thisApp.tConfig.ByteFont		-- left pane font
	local specText  = thisApp.tConfig.TextFont		-- right ----
	local tScheme	= tSchemeLight					-- colour scheme
	local tFmtBytes = tFormat.Dec					-- left pane text format
	local sDefault	= "Source Code Pro"				-- default font
	
	-- fonts sanity check
	-- (note that the minimum size differs for each panel)
	--
	specBytes[1] = specBytes[1] or 5
	if 5 > specBytes[1] then specBytes[1] = 5 end
	
	specText[1] = specText[1] or 12
	if 3 > specText[1] then specText[1] = 3 end
	
	specBytes[2] = specBytes[2] or sDefault
	if 0 == #specBytes[2] then specBytes[2] = sDefault end
		
	specText[2]  = specText[2]  or sDefault
	if 0 == #specText[2] then specText[2] = sDefault end
		
	-- allocate
	--	
	local fBytes = wx.wxFont(-1 * specBytes[1], wx.wxFONTFAMILY_MODERN, wx.wxFONTFLAG_ANTIALIASED,
							 wx.wxFONTWEIGHT_NORMAL, false, specBytes[2], wx.wxFONTENCODING_SYSTEM)
					
	local fText  = wx.wxFont(-1 * specText[1], wx.wxFONTFAMILY_DEFAULT, wx.wxFONTFLAG_ANTIALIASED,
							 wx.wxFONTWEIGHT_NORMAL, false, specText[2], wx.wxFONTENCODING_SYSTEM)
		
	-- format string to use (oct/dec/hex)
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
	
	penUnd= wx.wxPen(tScheme.RightCursor, 6, wx.wxSOLID)
	brStp = wx.wxBrush(tScheme.StopRow, wx.wxSOLID)
	
	penBar= wx.wxPen(tScheme.VerticalBar, 1, wx.wxSOLID)
	brBar = wx.wxBrush(tScheme.VerticalBar, wx.wxSOLID)

	-- time interval for displaying messages
	--
	local iShowTime = _floor(thisApp.tConfig.TimeDisplay * 1000)
	if 500 > iShowTime then iShowTime = 1500 end
	
	-- replace tabulation with spaces
	--
	local iTabSize = thisApp.tConfig.TabSize
	local sTabRep  = _strrep(" ", iTabSize)
	
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
	
	-- update dialogs
	--
	if m_MainFrame.hLoupe then
		
		local font = thisApp.tConfig.Loupe
		
		wxLoupe.SetupColour(tScheme.LoupeBack, tScheme.LoupeFore)
		wxLoupe.SetupFont(font[1], font[2])	
	end
	
	if m_MainFrame.hCalcUni then
		wxCalc.SetupColour(tScheme.DialogsBack, tScheme.DialogsFore)
	end
	
	if m_MainFrame.hFindText then
		wxFind.SetupColour(tScheme.DialogsBack, tScheme.DialogsFore)
	end	

	return (fBytes and fText)
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
local function UpdateLoupe()
--	trace.line("UpdateLoupe")

	if not m_MainFrame.hLoupe then return end
	
	local iCursor		= m_MainFrame.iCursor
	local tFile			= thisApp.tFileLines
	local iStopLine		= thisApp.LookupInterval(tFile, iCursor - 1)
	if 0 == iStopLine then return end								-- failed to get text
	
	local tCurrent  = tFile[iStopLine]
	local iOffset	= iCursor - tCurrent[1]
	local chCurrent = tCurrent[2]:sub(iOffset, iOffset)
	
	-- update display
	--
	wxLoupe.SetData(chCurrent)
end

-- ----------------------------------------------------------------------------
-- retrieve the current position
--
local function OnGetCursorPos()
	
	return m_MainFrame.iCursor
end

-- ----------------------------------------------------------------------------
-- realign view to the new cursor position
--
local function OnCursorPosChanged(inNewValue)
--	trace.line("OnCursorPosChanged")

	-- check changed
	--
	if inNewValue == m_MainFrame.iCursor then return end
		
	AlignBytesToCursor(inNewValue)

	Refresh()
	UpdateLoupe()

	SetStatusText("" .. m_MainFrame.iCursor, 5)
	SetStatusText("" .. m_MainFrame.iStopLine, 4)
end

-- ----------------------------------------------------------------------------
--
local function OnEncode_UTF_8()
--	trace.line("OnEncode_UTF_8")

	wx.wxBeginBusyCursor()
	
	local _, sText = thisApp.Encode_UTF_8()
	
	-- do a complete redraw
	--	
	m_MainFrame.iCursor = m_MainFrame.iCursor + 1
	OnCursorPosChanged(m_MainFrame.iCursor - 1)
	
	-- display encode function result
	--
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

	-- check for the left pane's boundaries
	--
	local iNumCols	= thisApp.tConfig.Columns
	local rcWidth	= iSpacerX * iNumCols + iOffX
	local rcHeight	= iSpacerY * (m_MainFrame.iByteRowCount + 1) -- - iOffY
	
	local iSlide = 2
	if rcWidth > iPtX then iSlide = 1 end
	if m_MainFrame.iCurrentSlide ~= iSlide then
		
		-- signal slide selection changed
		--
		m_MainFrame.iCurrentSlide = iSlide
		RefreshSlides()
		Refresh()
		return				-- avoid a selection if just changing active slide
	end

	-- check limits
	--
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
	OnCursorPosChanged(iNewCursor)
end

-- ----------------------------------------------------------------------------
--
local function HandleKeybFont(key)
--	trace.line("HandleKeybFont")

	local iStep = thisApp.tConfig.FontStep
	iStep = iStep or 5
	if 0 > iStep then iStep = 5 end
	
	-- check for which pane updating font
	--
	local wSlide = thisApp.tConfig.TextFont
	if 1 == m_MainFrame.iCurrentSlide then wSlide = thisApp.tConfig.ByteFont end
	
	-- configuration item for the font has:
	-- [1] font size, [2] font name
	--
	if _byte("+") == key then
		wSlide[1] = wSlide[1] + iStep
	else
		wSlide[1] = wSlide[1] - iStep
	end
	
	if false == SetupDisplay() then
		SetStatusText("Cannot set fonts", 2)
		return
	end
	
	-- query a repaint
	--
	Refresh()
	SetStatusText("Text Font: " .. wSlide[1] .. "  " .. wSlide[2], 2)
end

-- ----------------------------------------------------------------------------
-- handle the mouse wheel
--
local function OnMouseWheel(event)
--	trace.line("OnMouseWheel")

	if 0 == thisApp.iFileBytes then return end
	
	-- --------------------
	-- change the font size
	--
	if event:ControlDown() then
		
		if 0 > event:GetWheelRotation() then 
			HandleKeybFont(_byte("-"))
		else
			HandleKeybFont(_byte("+"))
		end
		
		return
	end
	
	-- -----------------
	-- perform scrolling
	--
	local iCurrent	= m_MainFrame.iCursor
	local iLines	= thisApp.tConfig.WheelMult
	local iScroll	= iLines * thisApp.tConfig.Columns
	
	-- works reversed
	--
	if 0 < event:GetWheelRotation() then iScroll = -1 * iScroll end
	
	OnCursorPosChanged(iCurrent + iScroll)
end

-- ----------------------------------------------------------------------------
--
local function KeyPressedBytes(event)
--	trace.line("KeyPressedBytes")
	
	local iCursor	= m_MainFrame.iCursor
	local iNumCols	= thisApp.tConfig.Columns
	local iPgJump	= _floor((iNumCols * m_MainFrame.iByteRowCount) / 2)
	
	local key	= event:GetKeyCode()
	local ctrl	= event:ControlDown()
--	local shift	= event:ShiftDown()
	
	-- cursor navigation
	--
	if wx.WXK_LEFT == key then
		iCursor = iCursor - 1

	elseif wx.WXK_RIGHT == key then
		iCursor = iCursor + 1

	elseif wx.WXK_UP == key then
		iCursor = iCursor - iNumCols

	elseif wx.WXK_DOWN == key then
		iCursor = iCursor + iNumCols

	elseif wx.WXK_PAGEDOWN == key then
	
		if ctrl then
			iCursor = iCursor + iPgJump * 2
		else
			iCursor = iCursor + iPgJump
		end		

	elseif wx.WXK_PAGEUP == key then
	
		if ctrl then
			iCursor = iCursor - iPgJump * 2
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
		return 0, false
	end	
	
	return iCursor, true
end

-- ----------------------------------------------------------------------------
--
local function KeyPressedText(event)
--	trace.line("KeyPressedText")

	local iStopLine = m_MainFrame.iStopLine
	local iCursor	= m_MainFrame.iCursor
	local iOffset	= iCursor - thisApp.tFileLines[iStopLine][1]
	local iNumRows	= m_MainFrame.iTextRowCount
	local iPgJump	= _floor(iNumRows / 2)
	
	local key	= event:GetKeyCode()
	local ctrl	= event:ControlDown()
--	local shift	= event:ShiftDown()
		
	if wx.WXK_UP == key then
		
		if 1 == iStopLine then return iCursor, false end
			
		iStopLine = iStopLine - 1
		iCursor = thisApp.tFileLines[iStopLine][1] + math.min(iOffset, #thisApp.tFileLines[iStopLine][2])
		
	elseif wx.WXK_DOWN == key then
		
		if #thisApp.tFileLines <= iStopLine then return iCursor, false end
		
		iStopLine = iStopLine + 1
		iCursor = thisApp.tFileLines[iStopLine][1] + math.min(iOffset, #thisApp.tFileLines[iStopLine][2])
		
	elseif wx.WXK_LEFT == key then
		
		if 1 == iOffset and 1 == iStopLine then return iCursor, false end
			
		if 1 == iOffset then 
			iCursor = thisApp.tFileLines[iStopLine][1]
--			iStopLine = iStopLine - 1
		else
			iCursor = iCursor - 1
		end

	elseif wx.WXK_RIGHT == key then
		
		if #thisApp.tFileLines[iStopLine][2] == iOffset and #thisApp.tFileLines == iStopLine then return iCursor, false end
			
		if #thisApp.tFileLines[iStopLine][2] == iOffset then 
			iStopLine = iStopLine + 1
			iCursor = thisApp.tFileLines[iStopLine][1] + 1
		else
			iCursor = iCursor + 1
		end
		
	elseif wx.WXK_PAGEDOWN == key then
		
		if ctrl then
			iStopLine = iStopLine + iPgJump * 2
		else
			iStopLine = iStopLine + iPgJump
		end
		
		if #thisApp.tFileLines < iStopLine then iStopLine = #thisApp.tFileLines end
		
		iCursor = thisApp.tFileLines[iStopLine][1] + iOffset

	elseif wx.WXK_PAGEUP == key then
	
		if ctrl then
			iStopLine = iStopLine - iPgJump * 2
		else
			iStopLine = iStopLine - iPgJump
		end
		
		if 1 > iStopLine then iStopLine = 1 end
		
		iCursor = thisApp.tFileLines[iStopLine][1] + iOffset
		
	elseif wx.WXK_HOME == key then
		
		if ctrl then 
			iCursor = 1 									-- start of file
		else 
			iCursor = thisApp.tFileLines[iStopLine][1] + 1 	-- start of line
		end

	elseif wx.WXK_END == key then
	
		if ctrl then 
			iCursor = thisApp.iFileBytes 					-- end of file
		else 							
			iCursor = thisApp.tFileLines[iStopLine][1] + #thisApp.tFileLines[iStopLine][2]		-- end of line
		end
		
	else
		
		return iCursor, false
	end
	
	return iCursor, true
end

-- ----------------------------------------------------------------------------
-- handles keystrokes
-- currently is driving only the left pane
-- if +/- are pressed then changes the font of the right pane
--
local function OnKeyDown(event)
--	trace.line("OnKeyDown")

	if 0 >= thisApp.iFileBytes then return end
	
	local iCursor = 0
	local bValid  = false
	
	local key	= event:GetKeyCode()
		
	-- user wants to change active pane
	--
	if wx.WXK_TAB == key then 
		
		local iSlide = m_MainFrame.iCurrentSlide
		if 1 == iSlide then iSlide = 2 else iSlide = 1 end
		
		-- signal slide selection changed
		--
		m_MainFrame.iCurrentSlide = iSlide
		
		RefreshSlides()
		Refresh()	
		return
	end
	
	-- handle the case of font size change
	--
	if _byte("+") == key or _byte("-") == key then 
	
		HandleKeybFont(key) 
		return 0, false
	end

	-- process the key in the correct pane
	--
	if 1 == m_MainFrame.iCurrentSlide then
		iCursor, bValid = KeyPressedBytes(event)
	else
		iCursor, bValid = KeyPressedText(event)
	end
	
	-- key pressed was not recognized
	--
	if not bValid then return end

	-- check changed
	--
	OnCursorPosChanged(iCursor)
end

-- ----------------------------------------------------------------------------
-- one time initialization of tick timers and the frame's timer
-- the lower the frame's timer interval the more accurate are the tick timers
--
local function InstallTimers()
--	trace.line("InstallTimers")

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
--
local function OnSize(event)
--	trace.line("OnSize")

	if not m_MainFrame.hStatusBar then return end

	local size = event:GetSize()

	m_MainFrame.rcClientW = size:GetWidth() -- - 4  -- shall remove something  here
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
-- issue to import again the settings file
--
local function OnRefreshSettings()
--	trace.line("OnRefreshSettings")

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
	Refresh()
	
	SetStatusText("" .. m_MainFrame.iCursor, 5)
	SetStatusText("" .. m_MainFrame.iStopLine, 4)
	
	SetStatusText("Configuration has been reloaded", 2)
end

-- ----------------------------------------------------------------------------
--
local function OnToggleLoupe()
		
	local hLoupe = m_MainFrame.hLoupe
	
	-- create the loupe window (but don't show yet)
	--
	if not hLoupe then
		-- during creation assign a parent to float over
		--
		hLoupe = wxLoupe.Create(m_MainFrame.hWindow, tWindows.Loupe)
		
		local font	  = thisApp.tConfig.Loupe
		local tScheme = m_MainFrame.tColourScheme
		
		wxLoupe.SetupColour(tScheme.LoupeBack, tScheme.LoupeFore)
		wxLoupe.SetupFont(font[1], font[2])
		
		m_MainFrame.hLoupe = hLoupe
	end
	
	if not wxLoupe.IsVisible() then
		
		wxLoupe.Display(true)
		UpdateLoupe()
	else
		
		wxLoupe.Display(false)
	end
end

-- ----------------------------------------------------------------------------
--
local function OnToggleCalcUnicode()
		
	local hCalcUni = m_MainFrame.hCalcUni
	
	-- create the calculator window (but don't show yet)
	--
	if not hCalcUni then
		
		-- during creation assign a parent to float over
		--
		hCalcUni = wxCalc.Create(m_MainFrame.hWindow, tWindows.Calc)
		
		local tScheme = m_MainFrame.tColourScheme
		
		wxCalc.SetupColour(tScheme.DialogsBack, tScheme.DialogsFore)		
		
		m_MainFrame.hCalcUni = hCalcUni
	end

	-- show/hide
	--
	wxCalc.Display(not wxCalc.IsVisible())
end

-- ----------------------------------------------------------------------------
--
local function OnToggleFindText()
		
	local hFindText = m_MainFrame.hFindText
	
	-- create the calculator window (but don't show yet)
	--
	if not hFindText then
		-- during creation assign a parent to float over
		--
		hFindText = wxFind.Create(m_MainFrame.hWindow, tWindows.Find)
		
		local tScheme = m_MainFrame.tColourScheme
		
		wxFind.SetupColour(tScheme.DialogsBack, tScheme.DialogsFore)		
		
		m_MainFrame.hFindText = hFindText
	end

	-- show/hide
	--
	wxFind.Display(not wxFind.IsVisible())
end

-- ----------------------------------------------------------------------------
-- handle the show window event, starts the timer
--
local function OnShow(event)
--	trace.line("OnShow")

	if not m_MainFrame.hWindow then return end
	
	if event:GetShow() then
		
		m_MainFrame.bVisible = true
		Refresh()
		
		if not m_MainFrame.hTickTimer then
			
			-- allocate the tick timers
			--
			InstallTimers()
			
			-- check for automatic open
			-- (do this here because it must be run once)			
			--
			if 1 == tWindows.Loupe[5] then OnToggleLoupe() end
			if 1 == tWindows.Calc[5]  then OnToggleCalcUnicode() end
			if 1 == tWindows.Find[5]  then OnToggleFindText() end			
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

	-- unique IDs for the menu
	--  
	local rcMnuReadFile = UniqueID()
	local rcMnuSaveFile = UniqueID()
	local rcMnuByBlock  = UniqueID()
	local rcMnuCheckFmt = UniqueID()
	local rcMnuEncUTF8  = UniqueID()
	local rcMnuSettings = UniqueID()
	local rcMnuLoupe	= UniqueID()
	local rcMnuCalcUni  = UniqueID()
	local rcMnuFindText = UniqueID()

	local rcMnuEdCut	= wx.wxID_CUT
	local rcMnuEdCopy	= wx.wxID_COPY
	local rcMnuEdPaste	= wx.wxID_PASTE
	local rcMnuEdSelAll	= wx.wxID_SELECTALL
	
	-- create a window
	--
	local ptLeft	= tWindows.Main[1]
	local ptTop		= tWindows.Main[2]
	local siWidth	= tWindows.Main[3]
	local siHeight	= tWindows.Main[4]
		
	local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, thisApp.sAppName,
							 wx.wxPoint(ptLeft, ptTop), 
							 wx.wxSize(siWidth, siHeight),
							 dwFrameFlags)

	-- create the FILE menu
	--
	local mnuFile = wx.wxMenu("", wx.wxMENU_TEAROFF)
	mnuFile:Append(rcMnuReadFile, "Import File\tCtrl-I", "Read the file in memory")
	mnuFile:Append(rcMnuSaveFile, "Export File\tCtrl-S", "Save memory to file")
	mnuFile:AppendSeparator()
	mnuFile:Append(wx.wxID_EXIT,  "E&xit\tAlt-X",		  "Quit the application")
	
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
	mnuCmds:Append(rcMnuCheckFmt, "Check Format\tCtrl-U", "Check bytes in current file")
	mnuCmds:Append(rcMnuEncUTF8,  "Encode UTF_8\tCtrl-E", "Encode memory in UTF_8")
	mnuCmds:AppendSeparator()
	mnuCmds:Append(rcMnuByBlock,  "Create Block Samples\tCtrl-B", "Create Unicode samples")
	
	local mnuView = wx.wxMenu("", wx.wxMENU_TEAROFF)
	mnuView:AppendCheckItem(rcMnuLoupe,    "Loupe\tCtrl-L",     "Show or hide the magnifier window")
	mnuView:AppendCheckItem(rcMnuCalcUni,  "Calculator\tCtrl-T","Show or hide the Unicode calculator window")
	mnuView:AppendCheckItem(rcMnuFindText, "Find Text\tCtrl-F", "Show or hide the find text window")
	mnuView:AppendSeparator()
	mnuView:Append(rcMnuSettings, "Refresh Settings\tCtrl-R", "Import settings again and refresh")
	
	-- sinc check marks with saved configuration
	--
	mnuView:Check(rcMnuLoupe,    tWindows.Loupe[5] == 1)
	mnuView:Check(rcMnuCalcUni,  tWindows.Calc[5] == 1)
	mnuView:Check(rcMnuFindText, tWindows.Find[5] == 1)
	
	-- create the HELP menu
	--
	local mnuHelp = wx.wxMenu("", wx.wxMENU_TEAROFF)  
	mnuHelp:Append(wx.wxID_ABOUT, "&About", "Version Information")

	-- create the menu bar and associate sub-menus
	--
	local mnuBar
	mnuBar = wx.wxMenuBar()  
	mnuBar:Append(mnuFile,	"&File")
	mnuBar:Append(mnuEdit,	"&Edit")
	mnuBar:Append(mnuCmds,	"&Commands")
	mnuBar:Append(mnuView,	"&View")
	mnuBar:Append(mnuHelp,	"&Help")

	frame:SetMenuBar(mnuBar)

	-- create the bottom status bar
	--
	local hStatusBar	
	hStatusBar = frame:CreateStatusBar(#tStbarWidths, wx.wxST_SIZEGRIP)
	hStatusBar:SetFont(wx.wxFont(-1 * 12, wx.wxFONTFAMILY_SWISS, wx.wxFONTFLAG_ANTIALIASED, 
								 wx.wxFONTWEIGHT_LIGHT, false, "Lucida Sans Unicode"))
	hStatusBar:SetStatusWidths(tStbarWidths)
	
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

	-- menu events
	--
	frame:Connect(rcMnuReadFile, wx.wxEVT_COMMAND_MENU_SELECTED, OnReadFile)
	frame:Connect(rcMnuSaveFile, wx.wxEVT_COMMAND_MENU_SELECTED, OnSaveFile)
	frame:Connect(rcMnuByBlock,  wx.wxEVT_COMMAND_MENU_SELECTED, OnCreateByBlock)
	frame:Connect(rcMnuCheckFmt, wx.wxEVT_COMMAND_MENU_SELECTED, OnCheckEncoding)
	frame:Connect(rcMnuEncUTF8,	 wx.wxEVT_COMMAND_MENU_SELECTED, OnEncode_UTF_8)
	frame:Connect(rcMnuSettings, wx.wxEVT_COMMAND_MENU_SELECTED, OnRefreshSettings)
	frame:Connect(rcMnuLoupe,    wx.wxEVT_COMMAND_MENU_SELECTED, OnToggleLoupe)
	frame:Connect(rcMnuCalcUni,  wx.wxEVT_COMMAND_MENU_SELECTED, OnToggleCalcUnicode)
	frame:Connect(rcMnuFindText, wx.wxEVT_COMMAND_MENU_SELECTED, OnToggleFindText)
	
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
	
	-- this is necessary to avoid flickering
	-- (comment the line if running with the debugger
	-- and the Lua's version is below 5.2)
	--
	frame:SetBackgroundStyle(wx.wxBG_STYLE_CUSTOM)
	
	--  store for later
	--
	m_MainFrame.hWindow 	= frame	
	m_MainFrame.hStatusBar	= hStatusBar
	
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
	LoadDlgRects()
	
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
end

-- ----------------------------------------------------------------------------
--
return
{
	ShowWindow	 = ShowMainWindow,
	CloseWindow	 = CloseMainWindow,
	SetTitle	 = SetWindowTitle,
	SetCursorPos = OnCursorPosChanged,
	GetCursorPos = OnGetCursorPos,
}

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
