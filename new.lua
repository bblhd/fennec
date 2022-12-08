function tokeniser(path)
	local line = 1
	local file = io.open(path, 'r')
	local program = file:read('a')
	file:close()
	
	local function cerr(msg)
		error("fennec compiler error at line "..line.." in file "..path..": "..msg)
	end
	
	local function assert(cond, msg)
		if not cond then
			cerr(msg)
		end
	end
	
	local function removeJunk()
		if program:match('^%s') then
			local whitespace
			whitespace, program = program:match('^(%s+)(.*)$')
			_, whitespace = whitespace:gsub("\n", "")
			line = line + whitespace
			removeJunk()
		elseif program:match('^//[^\n]*') then
			program = program:match('^//[^\n]*(.*)$')
			removeJunk()
		end
	end
	
	local function pullSymbol(...)
		removeJunk()
		for _,option in ipairs(table.pack(...)) do
			if #program >= #option and program:sub(1,#option) == option then
				program = program:sub(#option+1)
				return option
			end
		end
	end
	
	local function pullKeyword(...)
		removeJunk()
		if program:match('^[a-zA-Z_]') then
			local keyword
			keyword, program = program:match('^([a-zA-Z_][a-zA-Z0-9_]*)(.*)$')
			for _,option in ipairs(table.pack(...)) do
				if keyword == option then
					return option
				end
			end
		end
	end
	
	local escapes = {
		['b'] = 8,
		['t'] = 9,
		['n'] = 10,
		['r'] = 13,
		['e'] = 27
	}
	
	local function pullName()
		removeJunk()
		if program:match('^[a-zA-Z_]') then
			local name
			name, program = program:match('^([a-zA-Z_][a-zA-Z0-9%._]*)(.*)$')
			return name
		end
	end
	
	local function pullNumber()
		removeJunk()
		local token = nil
		if program:match("^'\\.'") then
			token = tostring(escapes[program:sub(3,3)] or string.byte(program,3))
			program = program:sub(5)
		elseif str:match("^'.'") then
			token = tostring(string.byte(program, 2))
			program = program:sub(4)
		elseif program:match('^0x[0-9a-f]') then
			token, program = program:match("^0x([0-9a-f]+)(.*)$")
			token = tostring(tonumber(token, 16))
		elseif program:match('^0b[01]') then
			token, program = program:match("^0b([01]+)(.*)$")
			token = tostring(tonumber(token, 2))
		elseif program:match('^[0-9]') then
			token, program = program:match("^([0-9]+)(.*)$")
		end
		return token
	end
	
	local function pullString()
		removeJunk()
		if str:match('^"') then
			local i = 2
			local string = ""
			while program:sub(i,i) ~= '"' and i <= #program do
				if program:sub(i,i) == '\\' then
					i = i + 1
					if i > #program then break end
					if escapes[program:sub(i,i)] then
						string = string .. string.char(escapes[program:sub(i,i)]))
					else 
						string = string .. program:sub(i,i)
					end
				else
					string = string .. program:sub(i,i)
				end
				i = i + 1
			end
			if i > #program then
				cerr("no end of string")
			end
			program = program:sub(i+1)
			return string
		end
	end
	
	return {
		['error'] = cerr,
		['assert'] = assert,
		['symbol'] = pullSymbol,
		['keyword'] = pullKeyword,
		['name'] = pullName,
		['number'] = pullNumber,
		['string'] = pullString,
		['eof'] = function() return #program == 0 end
	}
end
