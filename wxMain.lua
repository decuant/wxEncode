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
local random	= require "random"		-- random number generator
local wxLoupe 	= require "wxLoupe"		-- display magnification of current char
local wxCalc	= require "wxCalc"		-- dialog for conversion bytes <-> Unicode
local wxFind	= require "wxFind"		-- find text within the file
				  require "extrastr"	-- extra string processor

local _floor	= math.floor
local _max		= math.max
local _min		= math.min
local _concat	= table.concat
local _format	= string.format
local _find		= string.find
local _strrep	= string.rep
local _byte		= string.byte
local _utf8sub	= string.utf8sub		-- extract utf8 bytes (1-4)

-- ----------------------------------------------------------------------------
-- status bar panes width
--
local tStbarWidths =
{
	180, 			-- application
	750, 			-- message
	150,			-- codepage
	120,			-- errors
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
	["Linefeed"]	= palette.Red,
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

	["LoupeBack"]	= palette.Ivory,
	["LoupeFore"]	= palette.Black,
	["LoupeExtra"]	= palette.Goldenrod2,

	["DialogsBack"] = palette.GhostWhite,
	["DialogsFore"] = palette.Black,
	["DialogsExtra"]= palette.Turquoise3,
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
	["VerticalBar"]	= palette.CadetBlue,
	["StopRow"]		= palette.Burlywood1,

	["Gutter"] 		= palette.Snow3,
	["SlideActive"] = palette.Black,

	["LoupeBack"]	= palette.Seashell2,
	["LoupeFore"]	= palette.Gray30,
	["LoupeExtra"]	= palette.SteelBlue3,

	["DialogsBack"] = palette.Cornsilk,
	["DialogsFore"] = palette.Black,
	["DialogsExtra"]= palette.DarkOrchid,
}

local tSchemeDark =
{
	["LeftBack"]	= palette.SlateBlue4,
	["ColourColumn"]= palette.NavyBlue,
	["LeftText"]	= palette.Gray80,
	["LeftCursor"]	= palette.VioletRed1,
	["Linefeed"]	= palette.DeepPink2,
	["Unprintable"]	= palette.Green,
	["MarkStart"]	= palette.Sienna,
	["HighBits"]	= palette.Cyan4,

	["RightBack"]	= palette.DarkSlateGray,
	["RightText"]	= palette.Gray70,
	["RightCursor"]	= palette.Azure1,
	["VerticalBar"]	= palette.PeachPuff,
	["StopRow"]		= palette.Salmon4,

	["Gutter"] 		= palette.SteelBlue2,
	["SlideActive"] = palette.Yellow,

	["LoupeBack"]	= palette.MediumPurple4,
	["LoupeFore"]	= palette.White,
	["LoupeExtra"]	= palette.PaleGoldenrod,

	["DialogsBack"] = palette.NavyBlue,
	["DialogsFore"] = palette.White,
	["DialogsExtra"]= palette.DeepPink,
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
	["VerticalBar"]	= palette.Wheat3,
	["StopRow"]		= palette.IndianRed4,

	["Gutter"] 		= palette.MediumSlateBlue,
	["SlideActive"] = palette.MediumAquamarine,

	["LoupeBack"]	= palette.Gray6,
	["LoupeFore"]	= palette.LightYellow2,
	["LoupeExtra"]	= palette.OrangeRed,

	["DialogsBack"] = palette.Gray15,
	["DialogsFore"] = palette.White,
	["DialogsExtra"]= palette.Green,
}

-- ----------------------------------------------------------------------------
-- (pre)allocate pens and brushes
--
local m_PenNull   = wx.wxPen(palette.Black, 1, wx.wxTRANSPARENT)
local m_BrushNull = wx.wxBrush(palette.Black, wx.wxTRANSPARENT)

-- bytes pane
--
local m_penLF 	= wx.wxPen(tSchemeWhite.Linefeed, 3, wx.wxSOLID)
local m_penXX 	= wx.wxPen(tSchemeWhite.Unprintable, 3, wx.wxSOLID)
local m_brMrk 	= wx.wxBrush(tSchemeWhite.MarkStart, wx.wxSOLID)
local m_brHBt 	= wx.wxBrush(tSchemeWhite.HighBits, wx.wxSOLID)
local m_brCur 	= wx.wxBrush(tSchemeWhite.LeftCursor, wx.wxSOLID)

-- text pane
--
local m_penUnd	= wx.wxPen(tSchemeWhite.RightCursor, 6, wx.wxSOLID)
local m_brStp	= wx.wxBrush(tSchemeWhite.StopRow, wx.wxSOLID)
local m_penBar	= wx.wxPen(tSchemeWhite.VerticalBar, 1, wx.wxSOLID)
local m_brBar	= wx.wxBrush(tSchemeWhite.VerticalBar, wx.wxSOLID)

-- ----------------------------------------------------------------------------
-- format to use for the bytes pane
-- (the 2nd element is a precalc of the length)
--
local tFormat =
{
	["Oct"] = {"%04o ", 5},
	["Dec"] = {"%03d ", 4},
	["Hex"] = {"%02x ", 3},
}

-- ----------------------------------------------------------------------------
-- ticktimers
--
local tTimers =
{
	-- name        interval		last fired
	--
	["Display"] = ticktime.new("Display"),
	["Garbage"] = ticktime.new("Garbage"),
	["Encoded"] = ticktime.new("Encoded"),
}

-- ----------------------------------------------------------------------------
-- reference to the application
--
local m_App = nil

-- ----------------------------------------------------------------------------
-- window's private members
--
local m_Frame =
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
	iOffsetX		= 6,	-- offset for writing
	iOffsetY		= 14,	-- offset for writing
	iRightOffsetX	= 0,	-- offset for the right pane (precalc)
	iRightOffsetY	= 0,	-- offset for the right pane (precalc)

	iLeftMonoWidth	= 0,	-- pixels for 1 byte display
	iLeftSpacerX	= 0,	-- pixels for formatted string (oct/dec/hex)
	iLeftSpacerY	= 0,	-- pixels for the height
	iRightSpacerX	= 0,	-- not used
	iRightSpacerY	= 0,	-- height in pixels of character

	tFormatBytes	= nil,	-- format string for the bytes display
	sTabReplace		= "",	-- replacement for tab on text slide
	sSpaceSub		= "",	-- replacement for spaces if hide selected _strrep(" ", tFmtBytes[2])

	iByteRowCount	= 0,	-- number of visibles rows
	iByteFirstRow	= 0,	-- first row visible, left rect
	iTextRowCount	= 0,	-- number of visible rows
	iTextFirstRow	= 0,	-- first row visible, right rect
}

-- ----------------------------------------------------------------------------
--
local m_Cursor =
{
	iAbsOffset = -1,		-- cursor position absolute within the file
	iRelOffset = -1,		-- cursor position relative to current line

	iStopLine  = -1,		-- current line index within the file
	tCurrLine  = nil,		-- current line {prev bytes count, text}
	sCurrChar  = "",		-- current character (1 to 4 bytes)
}

-- ----------------------------------------------------------------------------
--
local m_Marker =
{
	bMouseDown	= false,	-- the left mouse button is down
	bShiftDown	= false,	-- shift key is down

	iPosStart	= 1,		-- start marker
	iPosStop	= 1,		-- stop marker
}

-- ----------------------------------------------------------------------------
--
local m_Errors =
{
	iTotals		= 0,		-- returned number of errors
	iCurrent	= 0,		-- current error index
	tCurrErr	= { },		-- copy of current error
	sFormat		= "Err: %d/%d",	-- format string for statustext
}

-- ----------------------------------------------------------------------------
--
local m_Codepage =
{
	tUserReq	= { },		-- name, id : where name = ISO/OEM/WIN
	iGuessCnt	= 0,		-- number of tests so far
	iGuessLmt	= 0,		-- upper limit for guess
	tGuess		= { },		-- guess codepage format
	bHardCnvtd	= false,	-- user did a UTF_8 conversion
	sDisplay	= "",		-- string for statustext
	
	randomizer	= random.new()
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
-- default dialogs' rectangles and visibility
--
local m_WinIni = "winini.lua"
local tWindows = nil

-- ----------------------------------------------------------------------------
-- return the wxWindow handle
--
local function GetHandle()
	return m_Frame.hWindow
end

-- ----------------------------------------------------------------------------
-- reset the errors' values
--
local function ErrorsReset()
--	trace.line("ErrorsReset")

	m_Errors.iCurrent 	= 0
	m_Errors.iTotals	= 0
	m_Errors.tCurrErr 	= { }
end

-- ----------------------------------------------------------------------------
-- reset the marker's values
--
local function MarkerReset()
--	trace.line("MarkerReset")

	m_Marker.bMouseDown = false
	m_Marker.bShiftDown = false
	m_Marker.iPosStart  = 1
	m_Marker.iPosStop   = 1
end

-- ----------------------------------------------------------------------------
-- reset the cursor's values
--
local function CursorReset()
--	trace.line("CursorReset")

	m_Frame.iByteFirstRow	= 0
	m_Frame.iByteRowCount	= 0
	m_Frame.iTextFirstRow	= 0
	m_Frame.iTextRowCount	= 0

	m_Cursor.iAbsOffset		= -1
	m_Cursor.iRelOffset		= -1
	m_Cursor.iStopLine		= -1
	m_Cursor.tCurrLine		= nil
	m_Cursor.sCurrChar		= ""
end

-- ----------------------------------------------------------------------------
-- reset the codepage's values
--
local function CodepageReset()
	trace.line("CodepageReset")

	m_Codepage.tUserReq		= { }
	m_Codepage.iGuessCnt	= 0
	m_Codepage.iGuessLmt	= 0
	m_Codepage.tGuess		= { }
	m_Codepage.bHardCnvtd	= false
	m_Codepage.sDisplay		= ""
end

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
-- format values for writing to a Lua's syntax file
--
local function DlgRect2Lua(inLabel, inHWindow, inConfig)

	if inHWindow then

		local iPosX		= inHWindow:GetPosition().x
		local iPosY  	= inHWindow:GetPosition().y
		local iWidth  	= inHWindow:GetSize():GetWidth()
		local iHeight 	= inHWindow:GetSize():GetHeight()
		local iVisible	= 0

		if inHWindow:IsShown() then iVisible = 1 end

		-- correct negative offsets
		--
		if 0 > iPosX then iPosX	= 0 end
		if 0 > iPosY then iPosY	= 0 end

		-- check minimum sizes
		--
		if 0 >= iWidth  then iWidth  = 50 end
		if 0 >= iHeight then iHeight = 50 end

		-- override default configuration
		--
		inConfig = {iPosX, iPosY, iWidth, iHeight, iVisible}
	end

	-- returned line of text
	--
	local sLine

	sLine = "{" .. _concat(inConfig, ", ") .. "},\n"
	sLine = "\t[\"" .. inLabel .. "\"]\t= " .. sLine

	return sLine, inConfig
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
	sLine = "-- last used dialogs\' rectangles\n--\n"
	fhTgt:write(sLine)

	-- start of table's defintion
	--
	sLine = "local tWindows =\n{\n"
	fhTgt:write(sLine)

	-- main window
	--
	sLine, tWindows.Main = DlgRect2Lua("Main", GetHandle(), tWindows.Main)
	fhTgt:write(sLine)

	-- all dialogs
	--
	local wCurrent
	
	if m_Frame.hLoupe then wCurrent = m_Frame.hLoupe.GetHandle() else wCurrent = nil end
	sLine, tWindows.Loupe = DlgRect2Lua("Loupe", wCurrent, tWindows.Loupe)
	fhTgt:write(sLine)

	if m_Frame.hCalcUni then wCurrent = m_Frame.hCalcUni.GetHandle() else wCurrent = nil end
	sLine, tWindows.Calc = DlgRect2Lua("Calc", wCurrent, tWindows.Calc)
	fhTgt:write(sLine)

	if m_Frame.hFindText then wCurrent = m_Frame.hFindText.GetHandle() else wCurrent = nil end
	sLine, tWindows.Find = DlgRect2Lua("Find", wCurrent, tWindows.Find)
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
	if not m_Frame.hFontBytes then return end
	if not m_Frame.hFontText then return end

	-- left pane, presume a mono-spaced font used
	--
	inDrawDC:SetFont(m_Frame.hFontBytes)

	local sTest	= _format(m_Frame.tFormatBytes[1], 0x00)

	m_Frame.iLeftMonoWidth	= inDrawDC:GetTextExtent("0")
	m_Frame.iLeftSpacerX	= inDrawDC:GetTextExtent(sTest)
	m_Frame.iLeftSpacerY	= inDrawDC:GetCharHeight()

	-- right pane
	--
	inDrawDC:SetFont(m_Frame.hFontText)

	m_Frame.iRightSpacerX	= 0
	m_Frame.iRightSpacerY	= inDrawDC:GetCharHeight()
end

-- ----------------------------------------------------------------------------
-- draw a vertical bar of size of 1 page
-- if no text then it will be not shown
--
local function DrawVerticalBar(inDrawDC)
--	trace.line("DrawVerticalBar")

	if not inDrawDC then return end
	if 0 == m_App.iFileBytes then return end

	-- get the correct spacing here
	--
	local iOffY 	= m_Frame.iOffsetY
	local iHeight	= m_Frame.rcClientH - iOffY * 2

	local iNumRows	= #m_App.tFileLines						-- total file's lines
	local iVIORows	= m_Frame.iTextRowCount					-- max visible rows
	local iCurPage	= (m_Frame.iTextFirstRow / iVIORows)	-- current page shown
	local iTotPages	= (iNumRows / iVIORows)					-- pages making the file
	local iPageLen	= (iHeight / iTotPages)					-- hieght of the bar
	local iPosY		= (iPageLen * iCurPage)					-- absolute position

	-- just fix it when too small
	-- (it affects only the appereance)
	--
	iPageLen = _max(iPageLen, 25)

	-- fix for not rounding divisions
	--
	if iHeight <= (iPosY + iPageLen) then iPosY = iHeight - iPageLen end

	-- draw a rect for the bar itself and a line all through the slide's height
	--
	inDrawDC:SetPen(m_penBar)
	inDrawDC:SetBrush(m_brBar)

	inDrawDC:DrawRectangle(m_Frame.rcClientW - 20, iOffY, 2, iHeight - iOffY)
	inDrawDC:DrawRoundedRectangle(m_Frame.rcClientW - 30, iPosY, 20, iPageLen, 5)
end

-- ----------------------------------------------------------------------------
-- draw highlight for each even column
--
local function DrawColumns(inDrawDC)
--	trace.line("DrawColumns")

	if not inDrawDC then return end
	if not m_Frame.hFontBytes then return end

	local iCurX		= m_Frame.iOffsetX
	local iColumns	= m_App.tConfig.Columns
	local iSpacerX	= m_Frame.iLeftSpacerX
	local tScheme	= m_Frame.tColourScheme

	inDrawDC:SetPen(m_PenNull)
	inDrawDC:SetBrush(wx.wxBrush(tScheme.ColourColumn, wx.wxSOLID))

	-- center the highlight on the number of chars written (hex/dec/oct)
	--
	iCurX = iCurX - (iSpacerX / (m_Frame.tFormatBytes[2] * 2)) + iSpacerX

	while iColumns > 0 do

		inDrawDC:DrawRectangle(iCurX, 0, iSpacerX, m_Frame.rcClientH)

		iCurX = iCurX + iSpacerX * 2

		iColumns = iColumns - 2
	end
end

-- ----------------------------------------------------------------------------
-- extract the current char at offset's position within the current line
-- works backward to find the starting index
-- (the character's composition will span from 1 to 4 bytes)
--
local function SetCurrentChar(inBUffer, inOffset)
--	trace.line("SetCurrentChar")

	local sUTF_8, iRetCode = _utf8sub(inBUffer, inOffset)
	local iSignal = iRetCode
	local iStart  = inOffset

	while (0 > iRetCode) and (0 < iStart) do

		iStart = iStart - 1
		sUTF_8, iRetCode = _utf8sub(inBUffer, iStart)
	end

	-- this is an error case, the character is not a valid
	-- UTF_8 code and the algorithm felt on a previous char
	-- which happened to be valid by chance
	--
	if ((0 > iSignal) and (1 == sUTF_8:len())) then

		m_Cursor.sCurrChar = sUTF_8
		return inOffset
	end

	if 0 < iRetCode then
		-- the character is valid
		--
		m_Cursor.sCurrChar = sUTF_8
		return iStart
	end

	-- try to handle an error case
	--
	m_Cursor.sCurrChar = inBUffer:sub(inOffset, inOffset)
	return inOffset
end

-- ----------------------------------------------------------------------------
-- drawing the left pane
-- will also set the current char selected
--
local function DrawBytes(inDrawDC)
--	trace.line("DrawBytes")

	-- quit if no data
	--
	if 0 >= m_App.iFileBytes then return end
	if 0 >= m_Cursor.iAbsOffset then return end

	-- here we go
	--
	local iCursor	= m_Cursor.iAbsOffset
	local iNumCols	= m_App.tConfig.Columns
	local tFile		= m_App.tFileLines
	local iOffX 	= m_Frame.iOffsetX
	local iOffY 	= m_Frame.iOffsetY
	local iCurX 	= iOffX
	local iCurY 	= iOffY
	local tFmtBytes	= m_Frame.tFormatBytes			-- format table to use (hex/dec/oct)
	local bUnderline = m_App.tConfig.Underline		-- underline bytes below 0x20
	local bUnicode	= m_App.tConfig.ColourCodes		-- highlight Unicode codes
	local tScheme	= m_Frame.tColourScheme			-- colour scheme in use

	-- this is the number of visible rows in the drawing area
	-- refresh it now
	--
	m_Frame.iByteRowCount = 0

	-- foreground
	--
	inDrawDC:SetFont(m_Frame.hFontBytes)
	inDrawDC:SetTextForeground(tScheme.LeftText)

	-- get the correct spacing here
	--
	local iSpacerX	= m_Frame.iLeftMonoWidth
	local iSpacerY	= m_Frame.iLeftSpacerY
	local iRectH	= m_Frame.rcClientH - iOffY * 2 - iSpacerY

	------------------------
	-- fill tables to flush
	--
	local tChars = { }						-- current set of tokens
	local tDraw1 = { }						-- underline \n \r
	local tDraw2 = { }						-- underline unprintable
	local tDraw3 = { }						-- rect under UTF_8 mark byte
	local tDraw4 = { }						-- rect under UTF_8 code
	local tDraw5 = { }						-- cursor

	-- start from first visible row
	--
	local iOffset 	 = iNumCols * m_Frame.iByteFirstRow
	local iFileIndex = m_App.FindLine(iOffset)
	local tCurrLine	 = tFile[iFileIndex]
	local iCurColumn = 1
	local iBufIndex  = iOffset - tCurrLine[1] + 1
	local bHideSpace = m_App.tConfig.HideSpaces
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

			-- add string to collection
			-- (check for replacing the space byte)
			--
			if 0x20 == ch and bHideSpace then
				tChars[#tChars + 1] = m_Frame.sSpaceSub
			else
				tChars[#tChars + 1] = _format(tFmtBytes[1], ch)
			end

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
				if (tCurrLine[1] + iBufIndex) == iCursor then
					tDraw5 = {xPos - 2, iCurY - 2, xLen + 4, iSpacerY + 4}
				end
			end

			-- get next
			--
			iBufIndex	= iBufIndex + 1
			iCurColumn	= iCurColumn + 1
		end

		-- draw all the cosmetics
		--
		if 0 < #tDraw1 then
			inDrawDC:SetPen(m_penLF)
			for _, coords in ipairs(tDraw1) do inDrawDC:DrawLine(coords[1], coords[2], coords[3], coords[4]) end
			tDraw1 = { }
		end

		if 0 < #tDraw2 then
			inDrawDC:SetPen(m_penXX)
			for _, coords in ipairs(tDraw2) do inDrawDC:DrawLine(coords[1], coords[2], coords[3], coords[4]) end
			tDraw2 = { }
		end

		inDrawDC:SetPen(m_PenNull)	-- remove rectangle's bounding box

		if 0 < #tDraw3 then
			inDrawDC:SetBrush(m_brMrk)
			for _, coords in ipairs(tDraw3) do inDrawDC:DrawRectangle(coords[1], coords[2], coords[3], coords[4]) end
			tDraw3 = { }
		end

		if 0 < #tDraw4 then
			inDrawDC:SetBrush(m_brHBt)
			for _, coords in ipairs(tDraw4) do inDrawDC:DrawRectangle(coords[1], coords[2], coords[3], coords[4]) end
			tDraw4 = { }
		end

		if 0 < #tDraw5 then
			inDrawDC:SetBrush(m_brCur)
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
		m_Frame.iByteRowCount = m_Frame.iByteRowCount + 1
	end
end

-- ----------------------------------------------------------------------------
-- drawing the right pane
--
local function DrawText(inDrawDC)
--	trace.line("DrawText")

	if 0 >= m_App.iFileBytes then return end
	if 0 >= m_Cursor.iAbsOffset then return end

--	local iCursor	= m_Cursor.iAbsOffset
	local tScheme	= m_Frame.tColourScheme						-- colour scheme in use
	local sTabRep	= m_Frame.sTabReplace						-- replace tab with chars
	local iOffX 	= m_Frame.iOffsetX
	local iOffY 	= m_Frame.iOffsetY
	local iSpacerY	= m_Frame.iRightSpacerY						-- height of each line
	local iCurX		= iOffX + m_Frame.iRightOffsetX				-- left offset
	local iCurY		= iOffY

	-- check which line will be the first
	--
	local tFile		= m_App.tFileLines
	local iStopLine	= m_Cursor.iStopLine
	if -1 == iStopLine then return end									-- failed to get text

	-- get the number of rows * font height and
	-- correct the y offset
	--
	local iLowLimit = m_Frame.rcClientH - (iOffY * 2) - iSpacerY		-- drawing height bound
	local iNumRows  = _floor(iLowLimit / iSpacerY)						-- allowed rows

	-- update
	--
	iOffY	  = math.ceil(((iLowLimit - (iSpacerY * iNumRows)) / 2))	-- vertical offset updated
	iLowLimit = m_Frame.rcClientH - iOffY - iSpacerY					-- vertical limit

	-- align indexes for the line currently highlighted
	-- (basically a list view)
	--
	local iFirstRow = m_Frame.iTextFirstRow
	if iFirstRow > iStopLine then iFirstRow = iStopLine end								-- passing the top
	if iStopLine > (iFirstRow + iNumRows) then iFirstRow = (iStopLine - iNumRows) end	-- passing the bottom
	if 0 >= iFirstRow then iFirstRow = 1 end

	-- store for later use outside the drawing function
	--
	m_Frame.iRightOffsetY = iOffY
	m_Frame.iTextFirstRow = iFirstRow
	m_Frame.iTextRowCount = iNumRows

	-- set the clipping region
	--
	inDrawDC:SetClippingRegion(iCurX, iOffY, m_Frame.rcClientW - iCurX - 20, m_Frame.rcClientH - 10)

	------------------
	-- print all chars
	--
	iCurX = iCurX + iOffX
	iCurY = iOffY

	-- highlight the background of the stopline
	--
	if 0 < iStopLine then

		local pStartX	= iCurX
		local pStartY	= iOffY + (iStopLine - iFirstRow) * iSpacerY
		local iWidth	= m_Frame.rcClientW - pStartX
		local iHeight	= iSpacerY

		inDrawDC:SetPen(m_PenNull)
		inDrawDC:SetBrush(m_brStp)
		inDrawDC:DrawRectangle(pStartX, pStartY, iWidth, iHeight)
	end

	-- assign font for drawing text
	--
	inDrawDC:SetFont(m_Frame.hFontText)
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

	-- underline the current character
	--
	if 0 < iStopLine then

		local iStop = m_Cursor.iRelOffset - 1

		-- extract the string before the current char
		--
		sToDraw = ""
		if 0 < iStop then
			sToDraw = m_Cursor.tCurrLine[2]:sub(1, iStop)
			sToDraw = sToDraw:gsub("\t", sTabRep)
		end

		-- get both the extents
		--
		local iStopOffset = inDrawDC:GetTextExtent(sToDraw)
		local iStopLength = inDrawDC:GetTextExtent(m_Cursor.sCurrChar)

		local pTopY	  = iOffY + (iStopLine - iFirstRow + 1) * iSpacerY
		local pStartX = iCurX + iStopOffset
		local pEndX	  = pStartX + iStopLength

		inDrawDC:SetPen(m_penUnd)
		inDrawDC:DrawLine(pStartX, pTopY, pEndX, pTopY)
	end

	-- remove clipping
	--
	inDrawDC:DestroyClippingRegion()
end

-- ----------------------------------------------------------------------------
--
local function DrawSelectionText(inDrawDC)
--	trace.line("DrawSelectionText")

	if 0 >= m_App.iFileBytes then return end
	if m_Marker.iPosStart == m_Marker.iPosStop then return end

	-- realign the marker's positions
	-- (must work on a copy)
	--
	local iPosStart = m_Marker.iPosStart
	local iPosStop  = m_Marker.iPosStop

	if iPosStart > iPosStop then
		iPosStart, iPosStop = iPosStop, iPosStart
	end

	local iFirstRow = m_Frame.iTextFirstRow
	local iLastRow  = m_Frame.iTextRowCount + iFirstRow

	-- positions
	--
	local tFile 	= m_App.tFileLines
	local iStartLn	= m_App.FindLine(iPosStart - 1)
	local iStopLn	= m_App.FindLine(iPosStop - 1)

	if -1 == iStartLn or -1 == iStopLn then return end
	if iStartLn > iLastRow then return end				-- selection is not visible
	if iStopLn < iFirstRow then return end				-- idem

	local iOffX 	= m_Frame.iOffsetX
	local iOffY 	= m_Frame.iRightOffsetY
	local iLeftW	= m_Frame.iRightOffsetX + iOffX * 2	-- left offset
	local iHeight	= m_Frame.rcClientH
	local sTabRep	= m_Frame.sTabReplace						-- replace tab with chars
	local iMarkStart= iPosStart - tFile[iStartLn][1]
	local sPrevText = tFile[iStartLn][2]:sub(1, iMarkStart - 1)

	local iMarkStop
	local sEndText

	-- assume the correct font is already selectec
	--
	if iStartLn == iStopLn then
		iMarkStop = iPosStop  - tFile[iStartLn][1]
		sEndText  = tFile[iStartLn][2]:sub(iMarkStart, iMarkStop)
	else
		sEndText  = tFile[iStartLn][2]:sub(iMarkStart)
	end

	sPrevText = sPrevText:gsub("\t", sTabRep)
	sEndText  = sEndText:gsub("\t", sTabRep)

	local iExtX  = inDrawDC:GetTextExtent(sPrevText)
	local iExtY  = inDrawDC:GetCharHeight()
	local iWidth = inDrawDC:GetTextExtent(sEndText)
	local iLeft  = iLeftW + iExtX
	local iTopY  = (iStartLn - iFirstRow) * iExtY + iOffY

	-- select graphic properties
	--
	local iOldFx = inDrawDC:GetLogicalFunction()
	inDrawDC:SetLogicalFunction(wx.wxROP_NOT)

	inDrawDC:SetPen(m_PenNull)
	inDrawDC:SetBrush(m_brBar)

	inDrawDC:DrawRectangle(iLeft, iTopY, iWidth, iExtY)

	iLeft = iLeftW								-- always from left

	while iStartLn < iStopLn do

		iStartLn = iStartLn + 1
		iTopY	 = iTopY + iExtY

		-- skip drawing rows that are not visible
		--
		if iTopY > iHeight then break end

		if iOffY <= iTopY then

			if iStartLn < iStopLn then
				-- continuation
				--
				sPrevText = tFile[iStartLn][2]
				sPrevText = sPrevText:gsub("\t", sTabRep)
				iWidth	  = inDrawDC:GetTextExtent(sPrevText)

			elseif iStartLn == iStopLn then
				-- last line
				--
				iMarkStop = iPosStop - tFile[iStartLn][1]
				sEndText  = tFile[iStartLn][2]:sub(1, iMarkStop)
				sEndText  = sEndText:gsub("\t", sTabRep)
				iWidth	  = inDrawDC:GetTextExtent(sEndText)
			end

			inDrawDC:DrawRectangle(iLeft, iTopY, iWidth, iExtY)
		end
	end

	inDrawDC:SetLogicalFunction(iOldFx)		-- restore old ROP
end

-- ----------------------------------------------------------------------------
--
local function DrawSelectionBytes(inDrawDC)
--	trace.line("DrawSelectionBytes")

	if 0 >= m_App.iFileBytes then return end
	if m_Marker.iPosStart == m_Marker.iPosStop then return end

	-- realign the marker's positions
	-- (must work on a copy)
	--
	local iPosStart = m_Marker.iPosStart
	local iPosStop  = m_Marker.iPosStop

	if iPosStart > iPosStop then
		iPosStart, iPosStop = iPosStop, iPosStart
	end

	local iNumCols	= m_App.tConfig.Columns
	local iFirstRow = m_Frame.iByteFirstRow
	local iLastRow  = m_Frame.iByteRowCount + iFirstRow

	-- positions
	--
	local iStartX = _floor(iPosStart % iNumCols)		-- relative start of selection
	local iStartY = _floor(iPosStart / iNumCols)
	local iStopX  = _floor(iPosStop % iNumCols)			-- relative end of selection
	local iStopY  = _floor(iPosStop / iNumCols)

	if iStartY > iLastRow then return end				-- selection is not visible
	if iStopY < iFirstRow then return end				-- idem

	-- get the correct spacing here
	--
	local iOffX 	= m_Frame.iOffsetX
	local iOffY 	= m_Frame.iOffsetY
	local tFmtBytes	= m_Frame.tFormatBytes
	local iSpacerX	= m_Frame.iLeftMonoWidth * tFmtBytes[2]
	local iSpacerY	= m_Frame.iLeftSpacerY
	local iHeight	= m_Frame.rcClientH

	-- select graphic properties
	--
	local iOldFx = inDrawDC:GetLogicalFunction()
	inDrawDC:SetLogicalFunction(wx.wxROP_NOT)

	inDrawDC:SetPen(m_PenNull)
	inDrawDC:SetBrush(m_brBar)

	-- draw line by line
	--
	local iTopY = (iStartY - iFirstRow) * iSpacerY + iOffY
	local iLeft, iWidth

	repeat
		-- skip drawing rows that are not visible
		--
		if iTopY > iHeight then break end

		if iOffY <= iTopY then

			iLeft = ((iStartX - 1) * iSpacerX) + iOffX

			if iStartY == iStopY then
				iWidth = (iStopX - iStartX + 1) * iSpacerX
			else
				iWidth = (iNumCols - iStartX + 1) * iSpacerX
			end

			inDrawDC:DrawRectangle(iLeft, iTopY, iWidth, iSpacerY)
		end

		iTopY	= iTopY + iSpacerY
		iStartX = 1
		iStartY = iStartY + 1

	until iStopY < iStartY

	inDrawDC:SetLogicalFunction(iOldFx)		-- restore old ROP
end

-- ----------------------------------------------------------------------------
--
local function DrawFile(inDrawDC)
--	trace.line("DrawFile")

	-- draw the background
	--
	if not m_Frame.hSlidesDC then return end
	inDrawDC:Blit(0, 0, m_Frame.rcClientW, m_Frame.rcClientH, m_Frame.hSlidesDC, 0, 0, wx.wxBLIT_SRCCOPY)

	if not m_Frame.bVisible then return end

	-- left pane (bytes)
	--
	if not m_Frame.hFontBytes then return end
	DrawBytes(inDrawDC)
	DrawSelectionBytes(inDrawDC)

	-- right pane (text)
	--
	if not m_Frame.hFontText then return end
	DrawText(inDrawDC)
	DrawSelectionText(inDrawDC)
	DrawVerticalBar(inDrawDC)
end

-- ----------------------------------------------------------------------------
-- cell number starts at 1, using the Lua convention
-- using the second cell as default position
--
local function SetStatusText(inText, inCellNo)
--	trace.line("SetStatusText")

	local hCtrl = m_Frame.hStatusBar
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
--
local function SetStatusIndices()
--	trace.line("SetStatusIndices")

	SetStatusText(_format("%d", m_Cursor.iAbsOffset), 6)
	SetStatusText(_format("%d", m_Cursor.iStopLine), 5)
	SetStatusText(_format(m_Errors.sFormat, m_Errors.iCurrent, m_Errors.iTotals), 4)
end

-- ----------------------------------------------------------------------------
--
local function SetupCodepage(inFileLines, tCodepage)
	trace.line("SetupCodepage")
	
	m_Codepage.tUserReq  = tCodepage
	m_Codepage.sDisplay  = _format("%s %d", tCodepage[1], tCodepage[2])
	
	if 0 < inFileLines then
		m_Codepage.iGuessLmt = _floor(inFileLines / 20) + 1
	end
	
	trace.line(_format("Codepage [%s] guess [%d/%d]", m_Codepage.sDisplay, m_Codepage.iGuessCnt, m_Codepage.iGuessLmt))

	SetStatusText(m_Codepage.sDisplay, 3)
end

-- ----------------------------------------------------------------------------
-- align view of file based on the current cursor position
--
local function AlignBytesToCursor(inValue)
--	trace.line("AlignBytesToCursor")

	local iNumCols	= m_App.tConfig.Columns
	local iNumRows	= m_Frame.iByteRowCount
	local iFirstRow	= m_Frame.iByteFirstRow
	local iTopLine  = _floor((inValue - 1) / iNumCols)

	if iFirstRow < (iTopLine - iNumRows) then iFirstRow = (iTopLine - iNumRows) end
	if iFirstRow > iTopLine then iFirstRow = iTopLine end

	m_Frame.iByteFirstRow = iFirstRow			-- update the first visible row

	if m_Marker.bShiftDown then					-- update stop marker
		m_Marker.iPosStop = inValue
	end
end

-- ----------------------------------------------------------------------------
-- Simple interface to pop up a message
--
local function DlgMessage(message)

	wx.wxMessageBox(message, m_App.sAppName,
					wx.wxOK + wx.wxICON_INFORMATION, m_Frame.hWindow)
end

-- ----------------------------------------------------------------------------
--
local function OnAbout()

	DlgMessage(m_App.sAppName .. " [" .. m_App.sAppVersion .. "]\n" ..
				wxlua.wxLUA_VERSION_STRING.." built with "..wx.wxVERSION_STRING)
end

-- ----------------------------------------------------------------------------
--
local function OnClose()
--	trace.line("OnClose")

	local m_Window = m_Frame.hWindow
	if not m_Window then return end

	wx.wxGetApp():Disconnect(wx.wxEVT_TIMER)

	SaveDlgRects()

	if m_Frame.hLoupe then
		wxLoupe.Close()
		m_Frame.hLoupe = nil
	end

	if m_Frame.hCalcUni then
		wxCalc.Close()
		m_Frame.hCalcUni = nil
	end

	if m_Frame.hFindText then
		m_Frame.hFindText.Close()
		m_Frame.hFindText = nil
	end

	-- finally destroy the window
	--
	m_Window.Destroy(m_Window)
	m_Frame.hWindow = nil
end

-- ----------------------------------------------------------------------------
--
local function DrawSlides(inDrawDC)
--	trace.line("DrawSlides")

	if not m_Frame.hWindow then return end

	if not inDrawDC then return end
	if not m_Frame.hFontBytes then return end

	local iNumCols	= m_App.tConfig.Columns
	local iOffX 	= m_Frame.iOffsetX
	local iOffY 	= m_Frame.iOffsetY
	local iCurX 	= iOffX
	local tFmtBytes	= m_Frame.tFormatBytes			-- format table to use (hex/dec/oct)
	local tScheme	= m_Frame.tColourScheme			-- Colour scheme in use

	-- get the correct spacing here
	--
	local iSpacerX = m_Frame.iLeftMonoWidth
	local iSpacerY = m_Frame.iLeftSpacerY

	-- decide here the background Colour
	--
	local iRectW = iOffX + iNumCols * tFmtBytes[2] * iSpacerX
	local iRectH = m_Frame.rcClientH - iOffY * 2 - iSpacerY
	local iLeftW = iRectW

	-- background
	--
	inDrawDC:SetPen(m_PenNull)
	inDrawDC:SetBrush(wx.wxBrush(tScheme.LeftBack, wx.wxSOLID))
	inDrawDC:DrawRectangle(0, 0, iRectW, m_Frame.rcClientH)

	-- draw the colums' on/off colour
	--
	if m_App.tConfig.Interleave then DrawColumns(inDrawDC) end

	-- -----------------------------------------------
	-- this is the right part with the text formatting
	--

	-- still use the left pane font for correct start offset
	--
	iCurX = iLeftW

	-- get the correct spacing here
	--
	iSpacerX = m_Frame.iRightSpacerX
	iSpacerY = m_Frame.iRightSpacerY

	-- bounds
	--
	iRectW = m_Frame.rcClientW - iLeftW - 8
	iRectH = m_Frame.rcClientH - 28

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
	local penActive = wx.wxPen(tScheme.SlideActive, 20, wx.wxSOLID)
	penActive:SetCap(wx.wxCAP_BUTT)

	inDrawDC:SetPen(penActive)

	if 1 == m_Frame.iCurrentSlide then
		inDrawDC:DrawLine(0, 0, iLeftW, 0)
	else
		inDrawDC:DrawLine(iCurX, 0, iCurX + iRectW, 0)
	end

	-- store left offset for the right pane
	--
	m_Frame.iRightOffsetX = iLeftW - iOffX
end

-- ----------------------------------------------------------------------------
--
local function NewSlidesDC()
--	trace.line("NewSlidesDC")

	-- create a bitmap wide as the client area
	--
	local memDC  = wx.wxMemoryDC()
 	local bitmap = wx.wxBitmap(m_Frame.rcClientW, m_Frame.rcClientH)
	memDC:SelectObject(bitmap)

	-- refresh the font spacing
	--
	if 0 == m_Frame.iLeftSpacerX then CalcFontSpacing(memDC) end

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
	local memDC = m_Frame.hMemoryDC

	if not memDC then

		local bitmap = wx.wxBitmap(m_Frame.rcClientW, m_Frame.rcClientH)
		memDC  = wx.wxMemoryDC()
		memDC:SelectObject(bitmap)
	end

	-- refresh the font spacing
	--
	if 0 == m_Frame.iLeftSpacerX then CalcFontSpacing(memDC) end

	-- if file is open then handle the draw
	--
	DrawFile(memDC)

	return memDC
end

-- ----------------------------------------------------------------------------
--
local function RefreshSlides()
--	trace.line("RefreshSlides")

	if m_Frame.hSlidesDC then
		m_Frame.hSlidesDC:delete()
		m_Frame.hSlidesDC = nil
	end

	m_Frame.hSlidesDC = NewSlidesDC()
end

-- ----------------------------------------------------------------------------
--
local function Invalidate()
--	trace.line("Invalidate")

	if m_Frame.hWindow then
		-- pass a false to avoid an ERASEBACKGROUND event
		--
		m_Frame.hWindow:Refresh(false)
	end
end

-- ----------------------------------------------------------------------------
--
local function Refresh()
--	trace.line("Refresh")

	m_Frame.hMemoryDC = NewMemDC()

	Invalidate()
end

-- ----------------------------------------------------------------------------
-- wxPaintDC			-- drawing to the screen, during EVT_PAINT
-- wxClientDC			-- drawing to the screen, outside EVT_PAINT
-- wxBufferedPaintDC	-- drawing to a buffer, then the screen, during EVT_PAINT
-- wxBufferedDC			-- drawing to a buffer, then the screen, outside EVT_PAINT
-- wxMemoryDC			-- drawing to a bitmap
--
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
-- update loupe's display
--
local function UpdateLoupe()
--	trace.line("UpdateLoupe")

	if m_Frame.hLoupe then
		wxLoupe.SetData(m_Cursor.sCurrChar)
	end
end

-- ----------------------------------------------------------------------------
-- retrieve the current position
--
local function OnGetCursorPos()

	return m_Cursor.iAbsOffset
end

-- ----------------------------------------------------------------------------
-- realign view to the new cursor position
--
local function OnCursorChanged(inValue, inSkipRefresh)
--	trace.line("OnCursorChanged")

	-- check changed
	--
	if inValue == m_Cursor.iAbsOffset then return end

	-- sanity check
	--
	if 0 >= inValue then inValue = 1 end
	if m_App.iFileBytes < inValue then inValue = m_App.iFileBytes end

	-- get where the UTF_8 character really starts
	--
	local iLnIndex, tCurrLine  = m_App.FindLine(inValue)
	local iNewIndex	= 1

	assert(tCurrLine, "Invalid line looking for absolute: " .. inValue)

	if 1 < tCurrLine[2]:len() then

		iNewIndex = SetCurrentChar(tCurrLine[2], inValue - tCurrLine[1])
		inValue   = iNewIndex + tCurrLine[1]
	else

		m_Cursor.sCurrChar = tCurrLine[2]
	end

	-- these values will be used globally
	--
	m_Cursor.iAbsOffset = inValue
	m_Cursor.iStopLine  = iLnIndex
	m_Cursor.tCurrLine  = tCurrLine
	m_Cursor.iRelOffset = iNewIndex

	AlignBytesToCursor(inValue)

	UpdateLoupe()
	SetStatusIndices()
	
	if not inSkipRefresh then Refresh() end
end

-- ----------------------------------------------------------------------------
-- setup GDI objects following the user's preferences
-- as per stupinf.lua
--
local function SetupDisplay()
--	trace.line("SetupDisplay")

	-- font properties read from the config file
	--
	local specBytes = m_App.tConfig.ByteFont		-- left pane font
	local specText  = m_App.tConfig.TextFont		-- right ----
	local tScheme	= tSchemeLight					-- colour scheme
	local tFmtBytes = tFormat.Dec					-- left pane text format
	local sDefault	= "DejaVu Sans Mono"			-- default font

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
		if _find(m_App.tConfig.Format, tag, 1, true) then tFmtBytes = tFormat break end
	end

	-- colours setup
	--
	if     "White" == m_App.tConfig.Scheme then tScheme = tSchemeWhite
	elseif "Dark"  == m_App.tConfig.Scheme then tScheme = tSchemeDark
	elseif "Black" == m_App.tConfig.Scheme then tScheme = tSchemeBlack end

	-- prealloc the pens and brushes
	--
	m_penLF = wx.wxPen(tScheme.Linefeed, 3, wx.wxSOLID)			-- line feed or carriage return
	m_penXX = wx.wxPen(tScheme.Unprintable, 3, wx.wxSOLID)		-- unprintable characters
	m_brMrk = wx.wxBrush(tScheme.MarkStart, wx.wxSOLID)			-- UTF_8 first byte
	m_brHBt = wx.wxBrush(tScheme.HighBits, wx.wxSOLID)			-- UTF_8 remaining bytes
	m_brCur = wx.wxBrush(tScheme.LeftCursor, wx.wxSOLID)		-- left pane cursor

	m_penUnd= wx.wxPen(tScheme.RightCursor, 6, wx.wxSOLID)		-- right pane cursor
	m_brStp = wx.wxBrush(tScheme.StopRow, wx.wxSOLID)			-- highlight current line

	m_penBar= wx.wxPen(tScheme.VerticalBar, 1, wx.wxSOLID)		-- vertical bar
	m_brBar = wx.wxBrush(tScheme.VerticalBar, wx.wxSOLID)		-- vertical bar indicator

	-- default CAP for pens is rounded
	--
	m_penLF:SetCap(wx.wxCAP_BUTT)
	m_penXX:SetCap(wx.wxCAP_BUTT)
	m_penUnd:SetCap(wx.wxCAP_BUTT)
	m_penBar:SetCap(wx.wxCAP_BUTT)

	-- time interval for displaying messages
	--
	local iShowTime = _floor(m_App.tConfig.TimeDisplay * 1000)
	if 500 > iShowTime then iShowTime = 1500 end

	-- replace tabulation with spaces
	-- and spaces in case must hide 0x20
	--
	local sTabRep   = _strrep(" ", m_App.tConfig.TabSize)
	local sSpaceSub = _strrep(" ", tFmtBytes[2])

	-- setup
	--
	m_Frame.hFontBytes	 = fBytes			-- left pane font
	m_Frame.hFontText	 = fText			-- right pane font
	m_Frame.tFormatBytes = tFmtBytes		-- format string for left pane
	m_Frame.tColourScheme= tScheme			-- colour scheme
	m_Frame.iTmInterval	 = iShowTime		-- statusbar timed display
	m_Frame.sTabReplace	 = sTabRep			-- pre-format tab substitution
	m_Frame.sSpaceSub	 = sSpaceSub		-- pre-format space substitution
	m_Frame.iLeftSpacerX = 0				-- query recalc of text extent

	-- redraw
	--
	m_Frame.hSlidesDC = NewSlidesDC()
	m_Frame.hMemoryDC = NewMemDC()

	-- update dialogs
	-- (does not care if visible or not, but valid handles)
	--
	if m_Frame.hLoupe then

		local font = m_App.tConfig.Loupe

		m_Frame.hLoupe.SetupColour(tScheme.LoupeBack, tScheme.LoupeFore, tScheme.LoupeExtra)
		m_Frame.hLoupe.SetupFont(font[1], font[2])
	end

	if m_Frame.hCalcUni then
		m_Frame.hCalcUni.SetupColour(tScheme.DialogsBack, tScheme.DialogsFore, tScheme.DialogsExtra)
	end

	if m_Frame.hFindText then
		m_Frame.hFindText.SetupColour(tScheme.DialogsBack, tScheme.DialogsFore, tScheme.DialogsExtra)
	end

	return (fBytes and fText)
end

-- ----------------------------------------------------------------------------
--
local function SetWindowTitle(inString)
--	trace.line("SetWindowTitle")

	if not m_Frame.hWindow then return end

	inString = inString or m_App.sAppName
	m_Frame.hWindow:SetTitle(inString)
end

-- ----------------------------------------------------------------------------
--
local function OnEditCut()
--	trace.line("OnEditCut")

end

-- ----------------------------------------------------------------------------
-- copy text from relative offset into the clipboard
-- follows option set in configuration
--
local function OnEditCopy()
--	trace.line("OnEditCopy")

	local iRetCode, sBuffer

	if "Select" == m_App.tConfig.CopyOption then
		
		-- 'new' selection mode
		--
		iRetCode, sBuffer = m_App.CopySelected(m_Marker.iPosStart, m_Marker.iPosStop)
	else

		-- 'old' selection mode
		--
		iRetCode, sBuffer = m_App.GetTextAtPos(m_Cursor.iStopLine, m_Cursor.iRelOffset)
	end

	-- check return code
	--
	if 0 < iRetCode then

		local clipBoard = wx.wxClipboard.Get()
		if clipBoard and clipBoard:Open() then

			clipBoard:SetData(wx.wxTextDataObject(sBuffer))
			clipBoard:Close()
			
			SetStatusText(_format("%d bytes are in the Clipboard", sBuffer:len()))
			return
		end

		sBuffer = "Can\'t open Clipboard"
	end

	SetStatusText("Clipboard error: " .. sBuffer)
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

	if 0 == m_App.iFileBytes then return end

	MarkerReset()
	m_Marker.iPosStart = 1
	m_Marker.iPosStop  = m_App.iFileBytes
	Refresh()
end

-- ----------------------------------------------------------------------------
--
local function OnGotoPosAtLine(inLine, inOffset)
--	trace.line("OnNextError")

	if 0 == m_App.iFileBytes then return end

	local tFile	  = m_App.tFileLines
	local tLine	  = tFile[inLine]

	if tLine then
		local iCursor = tLine[1] + inOffset
		OnCursorChanged(iCursor)				-- will handle bound errors
		return
	end

	SetStatusText("Unable to goto to line")
end

-- ----------------------------------------------------------------------------
-- cycle errors - next
--
local function OnNextError()
--	trace.line("OnNextError")

	if 0 == m_App.iFileBytes then return end

	m_Errors.iCurrent = m_Errors.iCurrent + 1

	m_Errors.iCurrent, m_Errors.tCurrErr = m_App.GetUTF8Error(m_Errors.iCurrent)

	if m_Errors.tCurrErr then
		OnGotoPosAtLine(m_Errors.tCurrErr[1], m_Errors.tCurrErr[2])
	end
end

-- ----------------------------------------------------------------------------
-- cycle errors - previous
--
local function OnPrevError()
--	trace.line("OnPrevError")

	if 0 == m_App.iFileBytes then return end

	m_Errors.iCurrent = m_Errors.iCurrent - 1

	m_Errors.iCurrent, m_Errors.tCurrErr = m_App.GetUTF8Error(m_Errors.iCurrent)

	if m_Errors.tCurrErr then
		OnGotoPosAtLine(m_Errors.tCurrErr[1], m_Errors.tCurrErr[2])
	end
end

-- ----------------------------------------------------------------------------
-- read file into memory
--
local function OnReadFile(event, inOptFilename)
--	trace.line("OnReadFile")

	wx.wxBeginBusyCursor()

	-- reset positioning
	--
	CursorReset()
	MarkerReset()
	ErrorsReset()
	CodepageReset()
	SetWindowTitle()

	local iBytes, sText = m_App.LoadFile(inOptFilename)

	if 0 < iBytes then
		SetWindowTitle(m_App.sLastOpenFile)
		OnCursorChanged(1)
		SetupCodepage(#m_App.tFileLines, m_App.tConfig.Codepage)	-- first assignment
		tTimers.Encoded:Setup(1, true)
	end

	Refresh()
	UpdateLoupe()					-- refresh if open

	SetStatusIndices()
	SetStatusText(sText)

	wx.wxEndBusyCursor()
end

-- ----------------------------------------------------------------------------
--
local function OnOpenDlgFile(event)
--	trace.line("OnOpenDlgFile")

	local sFilename = wx.wxFileSelector("Select File", "",  "", "", "*.*", 0, m_Frame.hWindow)

	if 0 < sFilename:len() then OnReadFile(event, sFilename) end
end

-- ----------------------------------------------------------------------------
-- save memory to file
--
local function CallSaveFile(inOpt, inOptFilename)
--	trace.line("CallSaveFile")

	wx.wxBeginBusyCursor()

	local _, sText = m_App.SaveFile(inOpt, inOptFilename)

	SetStatusText(sText)

	if inOptFilename then SetWindowTitle(inOptFilename) end

	wx.wxEndBusyCursor()
end

-- ----------------------------------------------------------------------------
-- save memory to file
--
local function OnExportFile()
--	trace.line("OnExportFile")

	CallSaveFile(1, nil)
end

-- ----------------------------------------------------------------------------
-- save memory to file
--
local function OnOverwriteFile()
--	trace.line("OnOverwriteFile")

	CallSaveFile(2, nil)
end

-- ----------------------------------------------------------------------------
-- save memory to file
--
local function OnSaveDlgFile()
--	trace.line("OnSaveDlgFile")

	local sFilename = wx.wxFileSelector("Save File As", "",  "", "", "*.*", 0, m_Frame.hWindow)

	if 0 < sFilename:len() then
		CallSaveFile(3, sFilename)
		SetWindowTitle(sFilename)
	end
end

-- ----------------------------------------------------------------------------
--
local function OnEnumCodepages()
--	trace.line("OnEnumCodepages")

	wx.wxBeginBusyCursor()

	local _, sText = m_App.EnumCodepages()

	SetStatusText(sText)

	wx.wxEndBusyCursor()
end

-- ----------------------------------------------------------------------------
--
local function OnCheckEncoding()
--	trace.line("OnCheckEncoding")

	wx.wxBeginBusyCursor()

	ErrorsReset()
	local iNumErrors, sText = m_App.CheckEncoding()

	m_Errors.iTotals = iNumErrors

	SetStatusText(sText)		-- display returned string
	SetStatusIndices()

	wx.wxEndBusyCursor()
end

-- ----------------------------------------------------------------------------
--
local function OnCreateByBlock()
--	trace.line("OnCreateByBlock")

	wx.wxBeginBusyCursor()

	local bRet = m_App.CreateByBlock()

	if bRet then
		SetStatusText("Samples file created")
	else
		SetStatusText("Samples fle creation failed")
	end

	wx.wxEndBusyCursor()
end

-- ----------------------------------------------------------------------------
--
local function OnEncode_UTF_8()
--	trace.line("OnEncode_UTF_8")

	wx.wxBeginBusyCursor()

	local iRetCode, sText = m_App.Encode_UTF_8()

	if 0 < iRetCode then
		-- do a complete redraw
		--
		m_Cursor.iAbsOffset = m_Cursor.iAbsOffset + 1
		OnCursorChanged(m_Cursor.iAbsOffset - 1)
	end

	-- display encode function result
	--
	SetStatusText(sText)
--	SetStatusCodepage()

	wx.wxEndBusyCursor()
end

-- ----------------------------------------------------------------------------
-- check if the current slide has changed
--
local function IsSlideChange(event)
--	trace.line("IsSlideChange")

	-- get the position where the users made a choice
	--
	local iOffX		 = m_Frame.iOffsetX
	local iSpacerX	 = m_Frame.iLeftSpacerX
--	local iSpacerY	 = m_Frame.iLeftSpacerY
	local iPtX		 = event:GetLogicalPosition(m_Frame.hMemoryDC):GetXY()

	-- check for the left pane's boundaries
	--
	local iNumCols	= m_App.tConfig.Columns
	local rcWidth	= iSpacerX * iNumCols + iOffX
	local iSlide	= 2

	if rcWidth > iPtX then iSlide = 1 end

	if m_Frame.iCurrentSlide ~= iSlide then

		-- signal slide selection changed
		--
		m_Frame.iCurrentSlide = iSlide
		return true
	end

	return false
end

-- ----------------------------------------------------------------------------
--
local function PointToCell(inPtX, inPtY)
--	trace.line("PointToCell")

	local iOffX		= m_Frame.iOffsetX
	local iOffY		= m_Frame.iOffsetY
	local iSpacerX	= m_Frame.iLeftSpacerX
	local iSpacerY	= m_Frame.iLeftSpacerY
	local tFmtBytes	= m_Frame.tFormatBytes			-- format table to use (hex/dec/oct)

	-- align to offsets
	--
	inPtX = inPtX + (iOffX * tFmtBytes[2])
	inPtY = inPtY - iOffY

	-- get the cell (row,col)
	-- align to rectangle boundary
	--
	local iRow = _floor((inPtY - inPtY % iSpacerY) / iSpacerY)
	local iCol = _floor((inPtX + inPtX % iSpacerX) / iSpacerX)

	-- get the logical selection
	--
	local iNumCols	 = m_App.tConfig.Columns
	local iFirstByte = m_Frame.iByteFirstRow * iNumCols
	local iNewCursor = iFirstByte + iCol + (iRow * iNumCols)

	return iNewCursor
end

-- ----------------------------------------------------------------------------
-- correct the stop marker's position
-- return true if a correction was performed
--
local function ReAlignStopMarker()
	
	if 1 < m_Cursor.sCurrChar:len() then
		
		if m_Marker.iPosStop > m_Marker.iPosStart then
	
			m_Marker.iPosStop = m_Cursor.iAbsOffset + m_Cursor.sCurrChar:len() - 1			
			return true
		end
	end
	
	m_Marker.iPosStop = m_Cursor.iAbsOffset
	return false
end

-- ----------------------------------------------------------------------------
--
local function OnMouseMove(event)
--	trace.line("OnMouseMove")

	if not m_Marker.bMouseDown then return end

	-- don't accept cursor's position change clicking
	-- on the right pane (text)
	--
	if 1 ~= m_Frame.iCurrentSlide then return end

	-- update the markers
	--
	local drawDC = m_Frame.hMemoryDC
	local iPtX, iPtY = event:GetLogicalPosition(drawDC):GetXY()

	DrawSelectionBytes(drawDC)					-- remove old drawing
	DrawSelectionText(drawDC)
	m_Marker.iPosStop = PointToCell(iPtX, iPtY)	-- stop marker
	DrawSelectionBytes(drawDC)					-- do new drawing
	DrawSelectionText(drawDC)
	Invalidate()
end

-- ----------------------------------------------------------------------------
-- get the cell selected by the user
-- this function works only if a monospaced font is used for the bytes pane
--
local function OnLeftBtnDown(event)
--	trace.line("OnLeftBtnDown")

	if 0 >= m_App.iFileBytes then return end

	-- avoid a selection if just changing active slide
	--
	if IsSlideChange(event) then
		RefreshSlides()
		Refresh()
		return
	end

	-- don't accept cursor's position change clicking
	-- on the right pane (text)
	--
	if 1 ~= m_Frame.iCurrentSlide then return end

	local drawDC = m_Frame.hMemoryDC
	local iPtX, iPtY = event:GetLogicalPosition(drawDC):GetXY()

	DrawSelectionBytes(drawDC)					-- remove old drawing
	DrawSelectionText(drawDC)
	local iCursor = PointToCell(iPtX, iPtY)	
	
	OnCursorChanged(iCursor, true)				-- must delay the refresh
	
	-- re-align the markers
	-- but after changing the cursor's position
	-- because it might have been re-aligned
	--
	m_Marker.bMouseDown = true
	m_Marker.iPosStart  = m_Cursor.iAbsOffset
	m_Marker.iPosStop   = m_Cursor.iAbsOffset
	
	Refresh()
end

-- ----------------------------------------------------------------------------
-- register the end of marking a selection
--
local function OnLeftBtnUp(event)
--	trace.line("OnLeftBtnUp")

	-- don't accept cursor's position change clicking
	-- on the right pane (text)
	--
	if 1 ~= m_Frame.iCurrentSlide then return end

	local drawDC = m_Frame.hMemoryDC
	local iPtX, iPtY = event:GetLogicalPosition(drawDC):GetXY()

	OnCursorChanged(PointToCell(iPtX, iPtY), true)
	
	-- correct the cursor's position alignment
	--
	if m_Marker.bMouseDown then
		
		m_Marker.bMouseDown = false
		ReAlignStopMarker()
	end

	Refresh()
end

-- ----------------------------------------------------------------------------
-- handler to change the font
--
local function HandleKeybFont(key)
--	trace.line("HandleKeybFont")

	local iStep = m_App.tConfig.FontStep
	iStep = iStep or 5
	if 0 > iStep then iStep = 5 end

	-- check for which pane updating font
	--
	local wSlide = m_App.tConfig.TextFont
	if 1 == m_Frame.iCurrentSlide then wSlide = m_App.tConfig.ByteFont end

	-- configuration item for the font has:
	-- [1] font size, [2] font name
	--
	if _byte("+") == key then
		wSlide[1] = wSlide[1] + iStep
	else
		wSlide[1] = wSlide[1] - iStep
	end

	if false == SetupDisplay() then
		SetStatusText("Cannot set fonts")
		return
	end

	-- query a repaint
	--
	Refresh()
	SetStatusText(_format("Text Font: %.1f  %s", wSlide[1], wSlide[2]))
end

-- ----------------------------------------------------------------------------
-- handle the mouse wheel
-- if key press CTRL together with the wheel then cahnge font and quit
--
local function OnMouseWheel(event)
--	trace.line("OnMouseWheel")

	if 0 == m_App.iFileBytes then return end

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
	local iLines	= m_App.tConfig.WheelMult
	local iNewCursor

	if 1 == m_Frame.iCurrentSlide then

		-- left pane
		--
		local iScroll = iLines * m_App.tConfig.Columns
		if 0 < event:GetWheelRotation() then iScroll = -1 * iScroll end

		iNewCursor = m_Cursor.iAbsOffset + iScroll
	else

		-- right pane
		--
		local iStopLine = m_Cursor.iStopLine
		local tLines	= m_App.tFileLines
		local iTgtline

		if 0 < event:GetWheelRotation() then
			iTgtline = iStopLine - iLines
			iTgtline = _max(1, iTgtline)
		else
			iTgtline = iStopLine + iLines
			iTgtline = _min(#tLines, iTgtline)
		end

		-- normally it will drift toward column 1
		-- (offset counts bytes but should count characters instead
		-- because a Unicode character might be 4 bytes long)
		--
		iNewCursor = tLines[iTgtline][1] + m_Cursor.iRelOffset
	end

	OnCursorChanged(iNewCursor)			-- do the update
end

-- ----------------------------------------------------------------------------
-- handler for key press on the left pane (bytes)
--
local function KeyPressedBytes(event)
--	trace.line("KeyPressedBytes")

	local iCursor	= m_Cursor.iAbsOffset
	local iNumCols	= m_App.tConfig.Columns
	local iPgJump	= _floor((iNumCols * m_Frame.iByteRowCount) / 2)

	local key	= event:GetKeyCode()
	local ctrl	= event:ControlDown()

	-- cursor navigation
	--
	if wx.WXK_LEFT == key then
		iCursor = iCursor - 1

	elseif wx.WXK_RIGHT == key then
		iCursor = iCursor + _max(1, m_Cursor.sCurrChar:len())

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
			iCursor = m_App.iFileBytes 						-- end of file
		else
			if 0 ~= (iCursor % iNumCols) then				-- end of line
				iCursor = iCursor + (iNumCols - (iCursor % iNumCols))
			end
		end

	else
		return 0, false										-- key not processed
	end

	return iCursor, true
end

-- ----------------------------------------------------------------------------
-- handler for key press on the right pane (text)
--
local function KeyPressedText(event)
--	trace.line("KeyPressedText")

	local iStopLine = m_Cursor.iStopLine
	local iCursor	= m_Cursor.iAbsOffset
	local iNumRows	= m_Frame.iTextRowCount
	local iPgJump	= _floor(iNumRows / 2)
	local tLines	= m_App.tFileLines
	local tCurrent	= m_Cursor.tCurrLine
	local iOffset	= m_Cursor.iRelOffset

	local key	= event:GetKeyCode()
	local ctrl	= event:ControlDown()

	if wx.WXK_UP == key then

		if 1 == iStopLine then return iCursor, false end

		tCurrent = tLines[iStopLine - 1]
		iCursor  = tCurrent[1] + _min(iOffset, tCurrent[2]:len())

	elseif wx.WXK_DOWN == key then

		if #tLines <= iStopLine then return iCursor, false end

		tCurrent = tLines[iStopLine + 1]
		iCursor  = tCurrent[1] + _min(iOffset, tCurrent[2]:len())

	elseif wx.WXK_LEFT == key then

		if 1 == iOffset and 1 == iStopLine then return iCursor, false end

		if 1 == iOffset then
			iCursor = tCurrent[1]
		else
			iCursor = iCursor - 1
		end

	elseif wx.WXK_RIGHT == key then

		if #tCurrent[2] == iOffset and #tLines == iStopLine then return iCursor, false end

		if #tCurrent[2] == iOffset then
			iCursor = tLines[iStopLine + 1][1] + 1
		else
			iCursor = iCursor + _max(1, m_Cursor.sCurrChar:len())
		end

	elseif wx.WXK_PAGEDOWN == key then

		if ctrl then
			iStopLine = iStopLine + iPgJump * 2
		else
			iStopLine = iStopLine + iPgJump
		end

		if #tLines < iStopLine then
			iCursor = m_App.iFileBytes
		else
			iCursor = tLines[iStopLine][1] + iOffset
		end

	elseif wx.WXK_PAGEUP == key then

		if ctrl then
			iStopLine = iStopLine - iPgJump * 2
		else
			iStopLine = iStopLine - iPgJump
		end

		if 1 > iStopLine then
			iCursor = 1
		else
			iCursor = tLines[iStopLine][1] + iOffset
		end

	elseif wx.WXK_HOME == key then

		if ctrl then
			iCursor = 1 									-- start of file
		else
			iCursor = tCurrent[1] + 1 						-- start of line
		end

	elseif wx.WXK_END == key then

		if ctrl then
			iCursor = m_App.iFileBytes 						-- end of file
		else
			iCursor = tCurrent[1] + #tCurrent[2]			-- end of line
		end

	else

		return iCursor, false								-- key not processed
	end

	return iCursor, true
end

-- ----------------------------------------------------------------------------
-- handles keystrokes
--
local function OnKeyUp(event)
--	trace.line("OnKeyUp")

	if m_Marker.bShiftDown then
		
		m_Marker.bShiftDown = event:ShiftDown()
		if ReAlignStopMarker() then	Refresh() end
	end
end

-- ----------------------------------------------------------------------------
-- handles keystrokes
-- if +/- are pressed then changes the font
--
local function OnKeyDown(event)
--	trace.line("OnKeyDown")

	if 0 >= m_App.iFileBytes then return end

	local iOldCursor= m_Cursor.iAbsOffset
	local iCursor 	= 0
	local bValid  	= false

	local key = event:GetKeyCode()

	-- --------------------------------
	-- user wants to change active pane
	--
	if wx.WXK_TAB == key then

		local iSlide = m_Frame.iCurrentSlide
		if 1 == iSlide then iSlide = 2 else iSlide = 1 end

		-- signal slide selection changed
		--
		m_Frame.iCurrentSlide = iSlide

		RefreshSlides()
		Refresh()
		return
	end

	-- -----------------------------------
	-- handle the case of font size change
	--
	if _byte("+") == key or _byte("-") == key then

		HandleKeybFont(key)
		return 0, false
	end

	-- -----------------------------------
	-- process the key in the correct pane
	--
	if 1 == m_Frame.iCurrentSlide then
		iCursor, bValid = KeyPressedBytes(event)
	else
		iCursor, bValid = KeyPressedText(event)
	end

	-- key pressed was not recognized
	--
	if not bValid then return end

	-- check changed
	--
	OnCursorChanged(iCursor, true)
	
	-- update the markers
	--
	if event:ShiftDown() and not m_Marker.bShiftDown then

		m_Marker.bShiftDown = true
		m_Marker.iPosStart  = iOldCursor
		ReAlignStopMarker()
	end

	Refresh()
end

-- ----------------------------------------------------------------------------
--
local function GuessEncode()
--	trace.line("GuessEncode")

	local iLowerLimit = 1 + (m_Codepage.iGuessCnt * 20)
	local iLineIndex  = _floor(m_Codepage.randomizer:getBoxed(iLowerLimit, iLowerLimit + 20))

	local iBytes, iNumHigh, tSequence = m_App.CountSequences(iLineIndex)
	
	if -1 == iBytes then 
		trace.line("GuessEncode terminated")
		return false 
	end
	
	if 5 < iBytes then
		
		m_Codepage.iGuessCnt = m_Codepage.iGuessCnt + 1
		if m_Codepage.iGuessCnt == m_Codepage.iGuessLmt then
			return false
		end
		
		-- here shall guess encoding
		--
	end
	
	return true
end

-- ----------------------------------------------------------------------------
-- one time initialization of tick timers and the frame's timer
-- the lower the frame's timer interval the more accurate the tick timers are
--
local function InstallTimers()
--	trace.line("InstallTimers")

	if not m_Frame.hWindow then return false end
	if m_Frame.hTickTimer then return true end

	if not tTimers.Display:IsEnabled() then

		local iInterval = m_App.tConfig.TimeDisplay
		if 1 >= iInterval then iInterval = 2 end

		tTimers.Display:Setup(iInterval, false)
	end

	if not tTimers.Garbage:IsEnabled() then

		tTimers.Garbage:Setup(5, true)
	end
	
	if not tTimers.Encoded:IsEnabled() then

		tTimers.Encoded:Setup(1, true)
	end

	-- create and start a timer object
	--
	m_Frame.hTickTimer = wx.wxTimer(m_Frame.hWindow, wx.wxID_ANY)
	m_Frame.hTickTimer:Start(500, false)

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
		SetStatusText(nil)
		tTimers.Display:Enable(false)
	end

	-- this is to release memory via the GC
	--
	if tTimers.Garbage:HasFired() then
		
		m_App.GarbageTest()
		tTimers.Garbage:Reset()
	end
	
	-- this is to check the file's encoding
	--
	if tTimers.Encoded:HasFired() then
		
		local bRetCode = GuessEncode() or GuessEncode()
		
		if false == bRetCode then
			tTimers.Encoded:Enable(false)
		else
			tTimers.Encoded:Reset()
		end
	end	
	
end

-- ----------------------------------------------------------------------------
-- update internals when the user changes the windows' size
--
local function OnSize(event)
--	trace.line("OnSize

	local size = event:GetSize()

	m_Frame.rcClientW = size:GetWidth()
	m_Frame.rcClientH = size:GetHeight() - 80	-- subtract the status bar height

	-- -------------------
	-- statusbar panes
	-- get the sum of all panes except the second
	--
	local iWidth = tStbarWidths[1]
	for i=3, #tStbarWidths do
		iWidth = iWidth + tStbarWidths[i]
	end
	tStbarWidths[2] = m_Frame.rcClientW - iWidth

	m_Frame.hStatusBar:SetStatusWidths(tStbarWidths)

	-- regenerate the offscreen buffer
	--
	if m_Frame.hMemoryDC then
		m_Frame.hMemoryDC:delete()
		m_Frame.hMemoryDC = nil
	end

	RefreshSlides()
	Refresh()
	SetStatusIndices()
end

-- ----------------------------------------------------------------------------
-- issue to import again the settings file
--
local function OnRefreshSettings()
--	trace.line("OnRefreshSettings")

	if false == m_App.ReadSetupInf() then
		SetStatusText("Cannot load settings")
		return
	end

	if false == SetupDisplay() then
		SetStatusText("Cannot set fonts")
		return
	end
	
	-- check if the codepage requested is different
	-- skip if a conversion was performed
	--
	if m_Codepage.tUserReq[1] ~= m_App.tConfig.Codepage[1] or
	   m_Codepage.tUserReq[2] ~= m_App.tConfig.Codepage[2] then
	
		if not m_Codepage.bHardCnvtd then
			CodepageReset()
			SetupCodepage(#m_App.tFileLines, m_App.tConfig.Codepage)
			tTimers.Encoded:Setup(1, true)
		end
	end

	-- query a full repaint
	--
	RefreshSlides()
	Refresh()
	SetStatusIndices()
	
	SetStatusText("Configuration has been reloaded")
end

-- ----------------------------------------------------------------------------
-- show/hide the loupe window
--
local function OnToggleLoupe()
--	trace.line("OnToggleLoupe")

	local hLoupe = m_Frame.hLoupe

	-- create the loupe window (but don't show yet)
	--
	if not hLoupe then
		-- during creation assign a parent to float over
		--
		hLoupe = wxLoupe
		hLoupe.Create(m_App, m_Frame.hWindow, tWindows.Loupe)

		local font		= m_App.tConfig.Loupe
		local tScheme	= m_Frame.tColourScheme
		local sFilename	= m_App.tConfig.UseNames

		hLoupe.SetupColour(tScheme.LoupeBack, tScheme.LoupeFore, tScheme.LoupeExtra)
		hLoupe.SetupFont(font[1], font[2])
		hLoupe.SetNames(sFilename)
		
		hLoupe.Display(true)
		
		m_Frame.hLoupe = hLoupe
	
		UpdateLoupe()
		return
	end

	-- save dialog's size and position, then destroy it
	--
	hLoupe.Display(false)
	SaveDlgRects()
	hLoupe.Close()
	m_Frame.hLoupe = nil
end

-- ----------------------------------------------------------------------------
-- show/hide the calculatore
--
local function OnToggleCalcUnicode()
--	trace.line("OnToggleCalcUnicode")

	local hCalcUni = m_Frame.hCalcUni

	-- create the calculator window (but don't show yet)
	--
	if not hCalcUni then

		-- during creation assign a parent to float over
		--
		hCalcUni = wxCalc
		hCalcUni.Create(m_App, m_Frame.hWindow, tWindows.Calc)

		local tScheme = m_Frame.tColourScheme

		hCalcUni.SetupColour(tScheme.DialogsBack, tScheme.DialogsFore, tScheme.DialogsExtra)
		hCalcUni.Display(true)
		
		m_Frame.hCalcUni = hCalcUni
		return
	end

	-- save dialog's size and position, then destroy it
	--
	hCalcUni.Display(false)
	SaveDlgRects()
	hCalcUni.Close()
	m_Frame.hCalcUni = nil
end

-- ----------------------------------------------------------------------------
-- show/hide the find text dialog
--
local function OnToggleFindText()
--	trace.line("OnToggleFindText")

	local hFindText = m_Frame.hFindText

	-- create the calculator window (but don't show yet)
	--
	if not hFindText then
		-- during creation assign a parent to float over
		--
		hFindText = wxFind
		
		hFindText.Create(m_App, m_Frame.hWindow, tWindows.Find)

		local tScheme = m_Frame.tColourScheme

		hFindText.SetupColour(tScheme.DialogsBack, tScheme.DialogsFore, tScheme.DialogsExtra)
		hFindText.Display(true)
		
		m_Frame.hFindText = hFindText
		return
	end

	-- save dialog's size and position, then destroy it
	--
	hFindText.Display(false)
	SaveDlgRects()
	hFindText.Close()
	m_Frame.hFindText = nil
end

-- ----------------------------------------------------------------------------
-- handle the show window event
-- grab the event to perform 'run once' operations
--
local function OnShow(event)
--	trace.line("OnShow")

	if not m_Frame.hWindow then return end

	if event:GetShow() then

		m_Frame.bVisible = true
		Refresh()

		if not m_Frame.hTickTimer then

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
		m_Frame.bVisible = false
	end
end

-- ----------------------------------------------------------------------------
-- handle the minimize window event
-- (it's a matter of fact that this event will arrive too late to save the
-- main frame size and position and that a close command issued when the
-- frame is minimized will result in a 'invalid' winini.lua, can't do much)
--
local function OnIconize(event)
--	trace.line("OnIconize")

	local bShow = not event:Iconized()

	if m_Frame.hLoupe    then m_Frame.hLoupe.Display(bShow)	   end
	if m_Frame.hCalcUni  then m_Frame.hCalcUni.Display(bShow)  end
	if m_Frame.hFindText then m_Frame.hFindText.Display(bShow) end
end

-- ----------------------------------------------------------------------------
-- create the main window
--
local function CreateMainWindow()
--	trace.line("CreateMainWindow")

	-- unique IDs for the menu
	--
	local rcMnuReadFile = UniqueID()
	local rcMnuExport   = UniqueID()
	local rcMnuOverwrite= UniqueID()
	local rcMnuOpenNew	= UniqueID()
	local rcMnuSaveAs	= UniqueID()
	local rcMnuByBlock  = UniqueID()
	local rcMnuCheckFmt = UniqueID()
	local rcMnuEncUTF8  = UniqueID()
	local rcMnuEnumerate= UniqueID()
	local rcMnuSettings = UniqueID()
	local rcMnuLoupe	= UniqueID()
	local rcMnuCalcUni  = UniqueID()
	local rcMnuFindText = UniqueID()

	local rcMnuEdCut	= wx.wxID_CUT
	local rcMnuEdCopy	= wx.wxID_COPY
	local rcMnuEdPaste	= wx.wxID_PASTE
	local rcMnuEdSelAll	= wx.wxID_SELECTALL

	local rcMnuNextErr	= UniqueID()
	local rcMnuPrevErr	= UniqueID()

	-- flags in use for the main frame
	--
	local dwFrameFlags = bit32.bor(wx.wxDEFAULT_FRAME_STYLE, wx.wxCAPTION)
		  dwFrameFlags = bit32.bor(dwFrameFlags, wx.wxSYSTEM_MENU)
		  dwFrameFlags = bit32.bor(dwFrameFlags, wx.wxCLOSE_BOX)

	-- create a window
	--
	local ptLeft	= tWindows.Main[1]					-- position/ size
	local ptTop		= tWindows.Main[2]
	local siWidth	= tWindows.Main[3]
	local siHeight	= tWindows.Main[4]

	local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, m_App.sAppName,
							 wx.wxPoint(ptLeft, ptTop),
							 wx.wxSize(siWidth, siHeight),
							 dwFrameFlags)

	-- create the FILE menu
	--
	local mnuFile = wx.wxMenu("", wx.wxMENU_TEAROFF)
	mnuFile:Append(rcMnuReadFile, "Import File\tCtrl-I",    "Read the file in memory")
	mnuFile:Append(rcMnuExport,   "Export File\tCtrl-S",    "Save memory to file set in config")
	mnuFile:Append(rcMnuOverwrite,"Overwrite File\tCtrl-O", "Save memory to same file as input")
	mnuFile:AppendSeparator()
	mnuFile:Append(rcMnuOpenNew, "Open File", "Use file open dialog")
	mnuFile:Append(rcMnuSaveAs,  "Save As",   "Use file save dialog")
	mnuFile:AppendSeparator()
	mnuFile:Append(wx.wxID_EXIT,  "E&xit\tAlt-X", "Quit the application")

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
	mnuCmds:Append(rcMnuCheckFmt, "Check Format\tCtrl-U", 		"Check bytes in current file")
	mnuCmds:Append(rcMnuEncUTF8,  "Encode UTF_8\tCtrl-E", 		"Encode memory in UTF_8")
	mnuCmds:Append(rcMnuEnumerate,"Enumerate Codepages\tCtrl-P","Enumerate available codepages in the tracing file")

	mnuCmds:AppendSeparator()
	mnuCmds:Append(rcMnuByBlock,  "Create Block Samples\tCtrl-B", "Create Unicode samples")

	local mnuView = wx.wxMenu("", wx.wxMENU_TEAROFF)
	mnuView:AppendCheckItem(rcMnuLoupe,    "Loupe\tCtrl-L",     "Show or hide the magnifier window")
	mnuView:AppendCheckItem(rcMnuCalcUni,  "Calculator\tCtrl-T","Show or hide the Unicode calculator window")
	mnuView:AppendCheckItem(rcMnuFindText, "Find Text\tCtrl-F", "Show or hide the find text window")
	mnuView:AppendSeparator()
	mnuView:Append(rcMnuNextErr, "Goto Next Error\tCtrl-.",		"Show next error in list")
	mnuView:Append(rcMnuPrevErr, "Goto Previous Error\tCtrl-,",	"Show previous error in list")
	mnuView:AppendSeparator()
	mnuView:Append(rcMnuSettings, "Refresh Settings\tCtrl-R",   "Import settings again and refresh")

	-- sinc check marks with saved configuration
	--
	mnuView:Check(rcMnuLoupe,    tWindows.Loupe[5] == 1)
	mnuView:Check(rcMnuCalcUni,  tWindows.Calc[5]  == 1)
	mnuView:Check(rcMnuFindText, tWindows.Find[5]  == 1)

	-- create the HELP menu
	--
	local mnuHelp = wx.wxMenu("", wx.wxMENU_TEAROFF)
	mnuHelp:Append(wx.wxID_ABOUT, "&About", "Version Information")

	-- create the menu bar and associate sub-menus
	--
	local mnuBar = wx.wxMenuBar()
	mnuBar:Append(mnuFile, "&File")
	mnuBar:Append(mnuEdit, "&Edit")
	mnuBar:Append(mnuCmds, "&Commands")
	mnuBar:Append(mnuView, "&View")
	mnuBar:Append(mnuHelp, "&Help")

	frame:SetMenuBar(mnuBar)

	-- create the bottom status bar
	--
	local hStatusBar = frame:CreateStatusBar(#tStbarWidths, wx.wxST_SIZEGRIP)
	hStatusBar:SetFont(wx.wxFont(-1 * 12, wx.wxFONTFAMILY_SWISS, wx.wxFONTFLAG_ANTIALIASED,
								 wx.wxFONTWEIGHT_LIGHT, false, "Lucida Sans Unicode"))
	hStatusBar:SetStatusWidths(tStbarWidths)

	-- standard event handlers
	--
	frame:Connect(wx.wxEVT_SHOW,		 OnShow)
	frame:Connect(wx.wxEVT_ICONIZE,		 OnIconize)
	frame:Connect(wx.wxEVT_PAINT,		 OnPaint)
	frame:Connect(wx.wxEVT_TIMER,		 OnTimer)
	frame:Connect(wx.wxEVT_SIZE,		 OnSize)
	frame:Connect(wx.wxEVT_KEY_UP,		 OnKeyUp)
	frame:Connect(wx.wxEVT_KEY_DOWN,	 OnKeyDown)
	frame:Connect(wx.wxEVT_LEFT_DOWN,	 OnLeftBtnDown)
	frame:Connect(wx.wxEVT_LEFT_UP,		 OnLeftBtnUp)
	frame:Connect(wx.wxEVT_MOTION,		 OnMouseMove)
	frame:Connect(wx.wxEVT_MOUSEWHEEL,	 OnMouseWheel)
	frame:Connect(wx.wxEVT_CLOSE_WINDOW, OnClose)

	-- menu events
	--
	frame:Connect(rcMnuReadFile, wx.wxEVT_COMMAND_MENU_SELECTED, OnReadFile)
	frame:Connect(rcMnuExport,   wx.wxEVT_COMMAND_MENU_SELECTED, OnExportFile)
	frame:Connect(rcMnuOverwrite,wx.wxEVT_COMMAND_MENU_SELECTED, OnOverwriteFile)
	frame:Connect(rcMnuOpenNew,  wx.wxEVT_COMMAND_MENU_SELECTED, OnOpenDlgFile)
	frame:Connect(rcMnuSaveAs,   wx.wxEVT_COMMAND_MENU_SELECTED, OnSaveDlgFile)

	frame:Connect(rcMnuByBlock,  wx.wxEVT_COMMAND_MENU_SELECTED, OnCreateByBlock)
	frame:Connect(rcMnuCheckFmt, wx.wxEVT_COMMAND_MENU_SELECTED, OnCheckEncoding)
	frame:Connect(rcMnuEncUTF8,	 wx.wxEVT_COMMAND_MENU_SELECTED, OnEncode_UTF_8)
	frame:Connect(rcMnuEnumerate,wx.wxEVT_COMMAND_MENU_SELECTED, OnEnumCodepages)
	frame:Connect(rcMnuSettings, wx.wxEVT_COMMAND_MENU_SELECTED, OnRefreshSettings)

	frame:Connect(rcMnuLoupe,    wx.wxEVT_COMMAND_MENU_SELECTED, OnToggleLoupe)
	frame:Connect(rcMnuCalcUni,  wx.wxEVT_COMMAND_MENU_SELECTED, OnToggleCalcUnicode)
	frame:Connect(rcMnuFindText, wx.wxEVT_COMMAND_MENU_SELECTED, OnToggleFindText)

	frame:Connect(rcMnuEdCut,	 wx.wxEVT_COMMAND_MENU_SELECTED, OnEditCut)
	frame:Connect(rcMnuEdCopy,   wx.wxEVT_COMMAND_MENU_SELECTED, OnEditCopy)
	frame:Connect(rcMnuEdPaste,  wx.wxEVT_COMMAND_MENU_SELECTED, OnEditPaste)
	frame:Connect(rcMnuEdSelAll, wx.wxEVT_COMMAND_MENU_SELECTED, OnEditSelectAll)

	frame:Connect(rcMnuNextErr,	 wx.wxEVT_COMMAND_MENU_SELECTED, OnNextError)
	frame:Connect(rcMnuPrevErr,	 wx.wxEVT_COMMAND_MENU_SELECTED, OnPrevError)

	frame:Connect(wx.wxID_EXIT,	 wx.wxEVT_COMMAND_MENU_SELECTED, OnClose)
	frame:Connect(wx.wxID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED, OnAbout)

	-- assign an icon
	--
	local icon = wx.wxIcon(m_App.sIconFile, wx.wxBITMAP_TYPE_ICO)
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
	m_Frame.hWindow		= frame
	m_Frame.hStatusBar	= hStatusBar
	
	return frame
end

-- ----------------------------------------------------------------------------
-- show the main window and runs the main loop
--
local function ShowMainWindow(inApplication)
--	trace.line("ShowMainWindow")

	-- save the application's reference
	--
	m_App = inApplication
	if not m_App then return nil end

	if m_Frame.hWindow then return m_Frame.hWindow end

	-- random number generator
	--
	m_Codepage.randomizer:initialize()
	
	-- create a new window
	--
	LoadDlgRects()

	if not CreateMainWindow() then return nil end

	-- pre-allocate the necessary fonts
	--
	if not SetupDisplay() then return nil end

	-- display
	--
	m_Frame.hWindow:Show(true)

	-- display the release
	--
	SetStatusText(m_App.sAppName .. " [" .. m_App.sAppVersion .. "]", 1)

	-- if a file was automatically loaded then display
	--
	if 0 < m_App.iFileBytes then
		SetWindowTitle(m_App.tConfig.InFile)
		OnCursorChanged(1)						-- fix to call a refresh
		SetupCodepage(#m_App.tFileLines, m_App.tConfig.Codepage)
	end

	return m_Frame.hWindow
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
	SetCursorPos = OnCursorChanged,
	GetCursorPos = OnGetCursorPos,
}

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
