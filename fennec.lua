currentLine = 1
currentFunction = {name="", args={}, vars={}}
functionArgCounts = {}
constants = {}

local isa = require "x86"

function islocal(name)
	for k, v in ipairs(currentFunction.args) do
		if v == name then
			return true
		end
	end
	for k, v in ipairs(currentFunction.vars) do
		if v == name then
			return true
		end
	end
end

function main()
	if not arg[1] then
		error("no file to compile")
	end
	compile(tokeniser(arg[1]))
end

function compile(tokens)
	isa.globalStart()
	while not tokens.eof() do
		tokens.assert(declaration(tokens), 'invalid declaration')
	end
	isa.globalEnd()
end

function declaration(tokens)
	return objectDeclaration(tokens) or constantDeclaration(tokens)
end

function objectDeclaration(tokens)
	local keyword = tokens.keyword('extern', 'intern', 'public', 'private')
	if keyword then
		currentFunction = getFunctionHeader(tokens)
		functionArgCounts[currentFunction.name] = #currentFunction.args
		isa.functionHeader(keyword)
		if keyword == "public" or keyword == "private" then
			tokens.assert(statement(tokens), 'invalid statement')
			isa.ret()
		end
		return true
	end
end

function constantDeclaration(tokens)
	if tokens.keyword('constant') then
		local name = tokens.name()
		tokens.assert(name, 'constant name must actually be a name')
		tokens.assert(not constants[name], "constant "..name.." already defined")
		tokens.assert(tokens.symbol('='), "constant is missing equals sign")
		local value
		
		value = tokens.name()
		if value then
			tokens.assert(constants[value], "constant values must be literals")
			constants[name] = constants[value]
		end
		value = tokens.number()
		if value then constants[name] = {type = 'number', value = value} end
		value = tokens.string()
		if value then constants[name] = {type = 'string', value = value} end
		return true
	end
end

function statement(tokens)
	return returnStatement(tokens)
		or letStatement(tokens)
		or ifStatement(tokens)
		or ifElseStatement(tokens)
		or whileStatement(tokens)
		or allocateStatement(tokens)
		or blockStatement(tokens)
		or expression(tokens)
end

function returnStatement(tokens)
	if tokens.keyword('return') then
		tokens.assert(expression(tokens), 'invalid expression')
		isa.ret()
		return true
	end
end

function letStatement(tokens)
	if tokens.keyword('let') then
		local name = tokens.name()
		tokens.assert(name, "let destination name invalid")
		tokens.assert(islocal(name), "let destination undefined")
		tokens.assert(tokens.symbol('='), "let missing equals sign")
		tokens.assert(expression(tokens), 'invalid expression')
		isa.store(name)
		return true
	end
end

function ifStatement(tokens)
	if tokens.keyword('if') then
		tokens.assert(expression(tokens), 'invalid expression')
		isa.ifthen()
		tokens.assert(statement(tokens), 'invalid statement')
		isa.ifend()
		return true
	end
end

function ifElseStatement(tokens)
	if tokens.keyword('ifelse') then
		tokens.assert(expression(tokens), 'invalid expression')
		isa.ifthen()
		tokens.assert(expression(tokens), 'invalid expression')
		tokens.assert(tokens.keyword('else'), "ifelse missing else")
		isa.ifelse()
		tokens.assert(statement(tokens), 'invalid statement')
		isa.ifend()
		return true
	end
end

function whileStatement(tokens)
	if tokens.keyword('while') then
		isa.whileif()
		tokens.assert(expression(tokens), 'invalid expression')
		isa.whiledo()
		tokens.assert(statement(tokens), 'invalid statement')
		isa.whileend()
		return true
	end
end

function allocateStatement(tokens)
	if tokens.keyword('allocate') then
		tokens.assert(tokens.symbol("["), "allocate missing open square bracket")
	
		local name = tokens.name()
		tokens.assert(name, "allocate invalid name")
		tokens.assert(islocal(name), "allocate destination undefined")
		
		tokens.assert(expression(tokens), 'invalid expression')
		
		tokens.assert(tokens.symbol("]"), "allocate missing closing bracket")
		
		isa.allocate(name)
		return true
	end
end

function blockStatement(tokens)
	if tokens.symbol('{') then
		while not tokens.symbol('}') do
			tokens.assert(statement(tokens), 'invalid statement')
			tokens.assert(not tokens.eof(), 'no end of block')
		end
		return true
	end
end

function expression(tokens)
	return functionCall(tokens)
		or variableGet(tokens)
		or numericalLiteral(tokens)
		or stringLiteral(tokens)
end

function functionCall(tokens)
	if tokens.symbol('(') then
		local name = tokens.name()
		tokens.assert(functionArgCounts[name], "undeclared function")
		
		isa.functionCall_init(name)
		for i = 1,functionArgCounts[name] do
			expression(tokens, true)
			isa.functionCall_pass(name, i)
		end
		isa.functionCall_fini(name)
		
		tokens.assert(tokens.symbol(')'), "function call for "..name.." is missing closing bracket")
		return true
	end
end


function variableGet(tokens)
	local name = tokens.name()
	if name then
		local constant = constants[name]
		if constant then
			if constant.type == 'number' then
				isa.numlit(tonumber(constant.value))
			elseif constant.type == 'string' then
				isa.stringlit(constant.value)
			end
		else
			isa.load(name)
		end
		return true
	end
end

function numericalLiteral(tokens)
	local number = tokens.number()
	if number then
		isa.numlit(tonumber(number))
		return true
	end
end

function stringLiteral(tokens)
	local string = tokens.string()
	if string then
		isa.stringlit(string)
		return true
	end
end


function getFunctionHeader(tokens)
	if tokens.symbol("(") then
		local name, args, vars = tokens.name(), {}, {}
		tokens.assert(name, "function name invalid")
		
		local allocating = false
		while not tokens.symbol(")") do
			if not allocating and tokens.symbol(";") then 
				allocating = true
			else
				local variable = tokens.name()
				tokens.assert(variable, "function argument name invalid")
				table.insert(allocating and vars or args, variable)
			end
		end
		
		return {name = name, args = args, vars = vars}
	end
end

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
			local keyword = program:match('^([a-zA-Z_][a-zA-Z0-9_]*)')
			for _,option in ipairs(table.pack(...)) do
				if keyword == option then
					program = program:sub(#option+1)
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
		elseif program:match("^'.'") then
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
		if program:match('^"') then
			local i = 2
			local string = ""
			while program:sub(i,i) ~= '"' and i <= #program do
				if program:sub(i,i) == '\\' then
					i = i + 1
					if i > #program then break end
					if escapes[program:sub(i,i)] then
						string = string .. string.char(escapes[program:sub(i,i)])
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
		['eof'] = function() removeJunk() return #program == 0 end
	}
end

main()
