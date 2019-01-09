-- ----------------------------------------------------------------------------
--
--  test - read a file and breaks lines on punctuation
--
-- ----------------------------------------------------------------------------

package.path = package.path .. ";?.lua;"

local trace	= require "trace"		-- tracing
			  require "extrastr"	-- extra utf8 helpers

local _format	= string.format
local _concat	= table.concat

-- ----------------------------------------------------------------------------
--
local function ExtractPunctuation(inFilename)
	
	if not inFilename then return -1 end
	
	local fhSrc = io.open(inFilename, "r")
	if not fhSrc then return -1 end
	
	local tOutput = { }
	local sLine   = fhSrc:read("*l")
	
	while sLine do
		
		trace.line(sLine)
		
		for sUtf8, bError in sLine:i_Uchar() do
			
			if bError then 
				trace.line(_format("Invalid UTF8 char: [0x%02x]", sUtf8:byte(1, 1)))
			else
				-- valid character
				--
				if sUtf8:u_punct() then 
					
					tOutput[#tOutput + 1] = sUtf8
				end
			end				
		end
		
		-- flush result
		--
		if 0 < #tOutput then			
			trace.line("Pnct: " .. _concat(tOutput, " "))			
			tOutput = { }
		end

		sLine = fhSrc:read("*l")
	end
	
	fhSrc:close()
	
	return 1
end

-- ----------------------------------------------------------------------------
-- from a Smalltalk/V examples
--
local function OccurrenceOf(inFilename, inDictFile)
	
	if not inFilename or not inDictFile then return -1 end
	
	local fhSrc = io.open(inFilename, "r")
	if not fhSrc then return -1 end
	
	local tDict = { }
	
	-- ----------------------------
	-- add a word to the dictionary
	--
	local function AddToDictionary(inWord)
		
		for _, tWord in ipairs(tDict) do
			
			-- find the word and increment the counter
			--
			if tWord[1] == inWord then
				tWord[2] = tWord[2] + 1
				return
			end
		end
		
		-- word not found, insert new
		--
		tDict[#tDict + 1] = {inWord, 1}
	end
	
	-- ----------------------------
	-- scan the file
	--
	local tWord = { }				-- current word
	local sLine = fhSrc:read("*l")
	
	while sLine do
			
		for sUtf8, bError in sLine:i_Uchar() do
			
			if bError then 
				trace.line(_format("Invalid UTF8 char: [0x%02x]", sUtf8:byte(1, 1)))
			else
				-- valid character
				--
				if sUtf8:u_punct() then 
					
					if 0 < #tWord then						
						
						AddToDictionary(_concat(tWord))							
						tWord = { }
					end
				else
					
					-- add character to word
					--
					tWord[#tWord + 1] = sUtf8
				end
			end				
		end

		-- reached the end of line
		--
		if 0 < #tWord then						
			
			AddToDictionary(_concat(tWord))							
			tWord = { }
		end						

		sLine = fhSrc:read("*l")
	end
	
	fhSrc:close()
	
	-- ---------------------------
	-- dump the dictionary to file
	--
	local fhTgt = io.open(inDictFile, "w")
	if not fhTgt then return -1 end		
	
	local iTotal = 0
	
	fhTgt:write(_format("*** Analyzing File [%s] ***\n\n", inFilename))
	
	for _, tCurWord in ipairs(tDict) do
		
		fhTgt:write(_format("%s [%d]\n", tCurWord[1], tCurWord[2]))
		
		iTotal = iTotal + tCurWord[2]
	end
	
	fhTgt:write(_format("\nTotal Words [%d] Total Occurrences [%d]\n", #tDict, iTotal))

	fhTgt:close()
	
	return #tDict
end

-- ----------------------------------------------------------------------------
--
local function TestPunctuation(inFilename, inDictionary)
	
	trace.lnTimeStart(_format("\n\nTesting File [%s]\n\n", inFilename))
	
	ExtractPunctuation(inFilename)
	OccurrenceOf(inFilename, inDictionary)
	
	trace.lnTimeEnd("**** TEST END *****")
end

-- ----------------------------------------------------------------------------
-- run it
	-- redirect logging
	--
io.output(".\\Testing.log")
	
TestPunctuation("test\\ASCII.txt",   "test\\Dict_ASCII.txt")
TestPunctuation("test\\Unicode.txt", "test\\Dict_Unicode.txt")

io.output():close()

-- ----------------------------------------------------------------------------
-- ----------------------------------------------------------------------------
