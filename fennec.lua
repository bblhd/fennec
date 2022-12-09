currentLine = 1
variables = {}
arrays = {}
functions = {}
constants = {}

local target = require "x86"

function main()
	if not arg[1] then
		error("no file to compile")
	end
	compile(tokeniser(arg[1]))
	if arg[2] then
		local file = io.open(arg[2], 'w')
		local program = file:write(target.finish())
		file:close()
	else
		print(target.finish())
	end
end

function compile(tokens)
	target.globalStart()
	while not tokens.eof() do
		tokens.assert(declaration(tokens), 'invalid declaration')
	end
	target.globalEnd()
end

function declaration(tokens)
	return objectDeclaration(tokens)
		or constantDeclaration(tokens)
end

function statement(tokens)
	return returnStatement(tokens)
		or letStatement(tokens)
		or ifStatement(tokens)
		or ifElseStatement(tokens)
		or whileStatement(tokens)
		or allocateStatement(tokens)
		or blockStatement(tokens)
		or functionCall(tokens)
		or implicitLet(tokens)
end

function expression(tokens)
	return functionCall(tokens)
		or variableGet(tokens)
		or numericalLiteral(tokens)
		or stringLiteral(tokens)
end

function objectDeclaration(tokens)
	local keyword = tokens.keyword('extern', 'intern', 'public', 'private')
	if keyword then
		return functionHeader(keyword, tokens)
	end
end

function functionHeader(keyword, tokens)
	if tokens.symbol("(") then
		local name = tokens.name()
		tokens.assert(name, "function name invalid")
		
		variables = {}
		local namedArgumentCount, allocatedCount = 0,0
		local vararg = false
		
		local allocating = false
		while not tokens.symbol(")") do
			if tokens.symbol(";") then
				tokens.assert(not allocating, "more than one semicolon in function header for '"..name.."'")
				allocating = true
			else
				local variable = tokens.name()
				tokens.assert(variable, "function argument name '"..variable.."' invalid")
				
				if tokens.symbol("...") then
					vararg = true
					allocating = true
					tokens.symbol(";")
				end
				if allocating then
					allocatedCount = allocatedCount + 1
				else
					namedArgumentCount = namedArgumentCount + 1
				end
				
				variables[variable] = {id = allocating and allocatedCount or namedArgumentCount, allocated=allocating}
			end
		end
		
		functions[name] = {required = namedArgumentCount}
		
		if keyword == "public" then
			target.public(name)
		elseif keyword == "extern" then
			target.extern(name)
		end
		
		if keyword == "public" or keyword == "private" then
			target.functionDefinition(name, allocatedCount)
			if vararg then
				target.varargs(namedArgumentCount)
			end
			tokens.assert(statement(tokens), "definition of function '"..name.."' is invalid")
			target.numlit('0')
			target.ret()
		end
		return true
	end
end

function constantDeclaration(tokens)
	if tokens.keyword('constant') then
		local name = tokens.name()
		tokens.assert(name, "constant name '"..name.."' is invalid")
		tokens.assert(not constants[name], "constant "..name.." already defined")
		tokens.assert(tokens.symbol('='), "'constant' is missing equals sign")
		
		local value
		value = tokens.number()
		if value then constants[name] = {type = 'number', value = value} return true end
		value = tokens.string()
		if value then constants[name] = {type = 'string', value = value} return true end
		value = tokens.name()
		tokens.assert(value and constants[value], "provided value starting with '"..value.."' for constant '"..name.."' is invalid")
		constants[name] = constants[value]
		
		return true
	end
end

function returnStatement(tokens)
	if tokens.keyword('return') then
		tokens.assert(expression(tokens), "invalid expression in 'return'")
		target.ret()
		return true
	end
end

function letStatement(tokens)
	if tokens.keyword('let') then
		local name = tokens.name()
		tokens.assert(name, "'let' destination invalid")
		tokens.assert(variables[name], "'let' destination variable '"..name.."' undefined")
		tokens.assert(tokens.symbol('='), "'let' missing '=' after variable")
		tokens.assert(expression(tokens), "invalid expression in 'let' expression")
		target.store(variables[name])
		return true
	end
end
function implicitLet(tokens)
	if tokens.keyword('extern', 'intern', 'public', 'private', 'constant') then
		return
	end
	local name = tokens.name()
	if name then
		tokens.assert(name, "implicit 'let' destination name invalid")
		tokens.assert(variables[name], "implicit 'let' destination variable '"..name.."' undefined")
		tokens.assert(tokens.symbol(':='), "implicit 'let' missing ':=' after variable")
		tokens.assert(expression(tokens), "invalid expression in implicicit 'let' assignment")
		target.store(variables[name])
		return true
	end
end

function ifStatement(tokens)
	if tokens.keyword('if') then
		tokens.assert(expression(tokens), "invalid expression in 'if' condition")
		target.ifthen()
		tokens.assert(statement(tokens), "invalid statement in 'if' body")
		target.ifend()
		return true
	end
end

function ifElseStatement(tokens)
	if tokens.keyword('ifelse') then
		tokens.assert(expression(tokens), "invalid expression in 'ifelse' condition")
		target.ifthen()
		tokens.assert(statement(tokens), "invalid statement in 'ifelse' body")
		tokens.assert(tokens.keyword('else'), "'ifelse' missing else")
		target.ifelse()
		tokens.assert(statement(tokens), "invalid statement in 'ifelse' else clause")
		target.ifend()
		return true
	end
end

function whileStatement(tokens)
	if tokens.keyword('while') then
		target.whileif()
		tokens.assert(expression(tokens), "invalid expression in 'while' condition")
		target.whiledo()
		tokens.assert(statement(tokens), "invalid statement in 'while' body")
		target.whileend()
		return true
	end
end

function allocateStatement(tokens)
	if tokens.keyword('allocate') then
		local name = tokens.name()
		tokens.assert(name, "'allocate' invalid name")
		tokens.assert(variables[name], "'allocate' destination variable '"..name.."' undefined")
		
		tokens.assert(tokens.symbol("["), "'allocate' missing open square bracket")
		tokens.assert(expression(tokens), "invalid expression in 'allocate' size")
		tokens.assert(tokens.symbol("]"), "'allocate' missing closing bracket")
		
		target.allocate(variables[name])
		return true
	end
end

function blockStatement(tokens)
	if tokens.symbol('{') then
		while not tokens.symbol('}') do
			tokens.assert(statement(tokens), "invalid statement in block")
			tokens.assert(not tokens.eof(), "encountered EOF in block")
		end
		return true
	end
end

function functionCall(tokens)
	if tokens.symbol('(') then
		local name = tokens.name()
		tokens.assert(functions[name], "attempt to call undeclared function '"..name.."'")
		
		target.call_init()
		while not tokens.symbol(')') do
			target.pass_init()
			tokens.assert(expression(tokens), "invalid expression in call of "..name)
			tokens.assert(not tokens.eof(), "encountered EOF in function call for "..name)
			target.pass_fini()
		end
		local passed = target.call_fini(name)
		tokens.assert(passed >= functions[name].required, "function '"..name.."' called with fewer than the minimum "..functions[name].required.." arguments")
		
		return true
	end
end


function variableGet(tokens)
	local name = tokens.name()
	if name then
		local constant = constants[name]
		if constant then
			if constant.type == 'number' then
				target.numlit(constant.value)
			elseif constant.type == 'string' then
				target.stringlit(constant.value)
			end
		else
			tokens.assert(variables[name], "variable '"..name.."' does not exist")
			target.load(variables[name])
		end
		return true
	end
end

function numericalLiteral(tokens)
	local number = tokens.number()
	if number then
		target.numlit(number)
		return true
	end
end

function stringLiteral(tokens)
	local string = tokens.string()
	if string then
		target.stringlit(string)
		return true
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
			name, program = program:match('^([a-zA-Z_][a-zA-Z0-9_]*)(.*)$')
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
