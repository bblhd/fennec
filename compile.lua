directIncludes = {}
indirectIncludes = {}
alreadyIncluded = {}

constants = {}
arrays = {}
functions = {}
variables = {}

callingDepth = 0

target = nil

function fileExists(name)
   local f=io.open(name,"r")
   if f~=nil then io.close(f) return true else return false end
end

function findIndirectInclude(include)
	for _,dir in ipairs(indirectIncludes) do
		if fileExists(dir..include..'.fen') then
			return dir..include..'.fen'
		end
		if fileExists(dir..'/'..include..'.fen') then
			return dir..'/'..include..'.fen'
		end
	end
end

function basicAssert(cond, msg)
	return not cond and error(msg) or true
end

function main()
	local platform = nil
	local infile = nil
	local outfile = nil

	local argi = 1
	while argi <= #arg do
		if arg[argi] == '-i' then
			basicAssert(argi+1 <= #arg or arg[argi+1]:match('^%-'), "-i <infile>: empty field infile")
			basicAssert(not infile, "-i <infile>: infile already given")
			infile = arg[argi+1]
		elseif arg[argi] == '-o' then
			basicAssert(argi+1 <= #arg or arg[argi+1]:match('^%-'), "-o <outfile>: empty field outfile")
			basicAssert(not outfile, "-o <outfile>: outfile already given")
			outfile = arg[argi+1]
		elseif arg[argi] == '-l' then
			basicAssert(argi+1 <= #arg or arg[argi+1]:match('^%-'), "-l <directory>: empty field directory")
			table.insert(indirectIncludes, arg[argi+1])
		elseif arg[argi] == '-L' then
			basicAssert(argi+1 <= #arg or arg[argi+1]:match('^%-'), "-L <conversion>: empty field conversion")
			local key,value = arg[argi+1]:match('^([^=]+)=([^=]+)$')
			basicAssert(key and value, "-L <conversion>: conversion invalid")
			directIncludes[key] = value
		elseif arg[argi] == '-p' then
			basicAssert(argi+1 <= #arg or arg[argi+1]:match('^%-'), "-p <platform>: empty field platform")
			basicAssert(not platform, "-p <platform>: platform already given")
			platform = arg[argi+1]
		end
		if arg[argi]:match('^%-[ioplL]$') then
			argi = argi + 2
		else
			error(arg[argi]..": invalid tag")
		end
	end

	basicAssert(platform, "no platform provided")
	basicAssert(infile, "no infile provided")
	basicAssert(outfile, "no outfile provided")

	target = require(platform..'/target')

	constants["WORD_SIZE"] = {type="number", value=target["WORD_SIZE"]}

	compile(tokeniser(infile))
	target.finish(outfile)
end

function compile(tokens)
	while not tokens.eof() do
		tokens.assert(declaration(tokens), 'invalid declaration')
	end
end

function declaration(tokens)
	return objectDeclaration(tokens)
		or constantDeclaration(tokens)
		or compilerDeclaration(tokens)
end

function statement(tokens)
	return blockStatement(tokens)
		or returnStatement(tokens)
		or letStatement(tokens)
		or callingDepth == 0 and allocateStatement(tokens)
		or ifStatement(tokens)
		or whileStatement(tokens)
		or functionCall(tokens)
		or implicitLet(tokens)
		or numericalLiteral(tokens)
		or stringLiteral(tokens)
end

function expression(tokens)
	return blockStatement(tokens)
		or functionCall(tokens)
		or variableGet(tokens)
		or numericalLiteral(tokens)
		or stringLiteral(tokens)
end

function objectDeclaration(tokens)
	local keyword = tokens.keyword('extern', 'intern', 'public', 'private')
	if keyword then
		return functionHeader(keyword, tokens) or arrayHeader(keyword, tokens)
	end
end

function functionHeader(keyword, tokens)
	if tokens.symbol("(") then
		local name = tokens.name()
		tokens.assert(name, "function name invalid")
		tokens.assert(not target.builtin(name), "attempt to redefine builtin '"..name.."' as a function")
		tokens.assert(not constants[name], "attempt to redefine constant '"..name.."' as a function")
		tokens.assert(not functions[name] or not functions[name].defined, "attempt to redefine function '"..name.."' as a new function")
		tokens.assert(not arrays[name], "attempt to redefine array '"..name.."' as a function")
		
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
		
		functions[name] = {required = namedArgumentCount, moreAllowed = vararg, defined=(keyword=='private' or keyword=='public')}
		
		if keyword == "public" then
			target.public(name)
		elseif keyword == "extern" then
			target.extern(name)
		end
		
		if keyword == "public" or keyword == "private" then
			target.functionDefinition(name, allocatedCount, vararg and namedArgumentCount)
			tokens.assert(statement(tokens), "definition of function '"..name.."' is invalid")
			target.numlit(0)
			target.ret()
		end
		return true
	end
end

function arrayHeader(keyword, tokens)
	local name = tokens.name()
	if name then
		tokens.assert(not target.builtin(name), "attempt to reuse builtin '"..name.."' as an array")
		tokens.assert(not constants[name], "attempt to redefine constant '"..name.."' as an array")
		tokens.assert(not functions[name], "attempt to redefine function '"..name.."' as an array")
		tokens.assert(not arrays[name], "attempt to redefine array '"..name.."' as a new array")

		if keyword == "public" then
			target.public(name)
		elseif keyword == "extern" then
			target.extern(name)
		end

		local isSized = tokens.symbol("[") and true
		tokens.assert(isSized or keyword == 'extern' or keyword == 'intern', "array is '"..keyword.."' and does not have a defined size")
		if not isSized then
			return true
		end
		local size = nil

		while not tokens.symbol("]") do
			local value
			value = tokens.number()
			if value then
				size = (size or 1) * tonumber(value)
			else
				value = tokens.name()
				tokens.assert(value and constants[value] and constants[value].type=='number', "provided array cardinal for array '"..name.."' isn't a numerical constant")
				size = (size or 1) * tonumber(constants[value].value)
				tokens.assert(not tokens.eof(), "encountered EOF in array definition for '"..name.."'")
			end
		end

		tokens.assert(size, "size is empty for array definition '"..name.."'")

		arrays[name] = size
		
		if keyword == "public" or keyword == "private" then
			target.arrayDefinition(name, size)
		end
		return true
	end
end

function constantDeclaration(tokens)
	if tokens.keyword('constant') then
		local name = tokens.name()
		tokens.assert(name, "constant name is invalid")
		tokens.assert(not target.builtin(name), "attempt to redefine builtin '"..name.."' as a constant")
		tokens.assert(not constants[name], "attempt to redefine constant '"..name.."' as a new constant")
		tokens.assert(not functions[name], "attempt to redefine function '"..name.."' as a constant")
		tokens.assert(not arrays[name], "attempt to redefine array '"..name.."' as a constant")
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

function compilerDeclaration(tokens)
	if tokens.keyword('include') then
		local include = tokens.string()
		if not include then
			local name = tokens.name()
			tokens.assert(name and constants[name] and constants[name].type == 'string', "'include' is missing library name")
			include = constants[name].value
		end
		
		if not alreadyIncluded[include] then
			local library = directIncludes[include] or findIndirectInclude(include)
			tokens.assert(library, "'"..include.."' is not a valid library ")

			alreadyIncluded[include] = library
			compile(tokeniser(library))
		end

		return true
	elseif tokens.keyword('link') then
		local link = tokens.string()
		if not link then
			local name = tokens.name()
			tokens.assert(name and constants[name] and constants[name].type == 'string', "'link' is missing library name")
		end
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
		if tokens.symbol(':=') then
			tokens.assert(variables[name], "implicit 'let' destination variable '"..name.."' undefined")
			tokens.assert(expression(tokens), "invalid expression in implicicit 'let' assignment")
			target.store(variables[name])
			return true
		else
			if constants[name] then
				if constants[name].type == 'number' then
					target.numlit(constants[name].value)
				elseif constants[name].type == 'string' then
					target.stringlit(constants[name].value)
				end
			elseif arrays[name] then
				target.arrayPointer(name)
			else
				tokens.assert(variables[name], "variable '"..name.."' does not exist")
				target.load(variables[name])
			end
			return true
		end
	end
end

function ifStatement(tokens)
	if tokens.keyword('if') then
		tokens.assert(expression(tokens), "invalid expression in 'if' condition")
		target.ifthen()
		tokens.assert(statement(tokens), "invalid statement in 'if' body")
		if tokens.keyword('else') then
			target.ifelse()
			tokens.assert(statement(tokens), "invalid statement in 'if' else clause")
		end
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

function expressionStatement(tokens)
	if tokens.keyword('then') then
		tokens.assert(expression(tokens), "invalid expression in 'then' statement")
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
		local func = target.builtin(name) or functions[name]
		tokens.assert(func, "attempt to call undeclared function '"..name.."'")
		
		callingDepth = callingDepth + 1
		target.call_init()
		while not tokens.symbol(')') do
			tokens.assert(expression(tokens), "invalid expression in call of "..name)
			tokens.assert(not tokens.eof(), "encountered EOF in function call for "..name)
			target.pass()
		end
		local passed = target.call_fini(name)
		tokens.assert(
			passed == func.required or func.moreAllowed and passed > func.required,
			"function '"..name.."' called with wrong number of arguments, should be "..(func.moreAllowed and "at least " or "")..func.required.." arguments"
		)
		callingDepth = callingDepth - 1

		return true
	end
end


function variableGet(tokens)
	local name = tokens.name()
	if name then
		if constants[name] then
			if constants[name].type == 'number' then
				target.numlit(constants[name].value)
			elseif constants[name].type == 'string' then
				target.stringlit(constants[name].value)
			end
		elseif arrays[name] then
			target.arrayPointer(name)
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
			token = escapes[program:sub(3,3)] or string.byte(program,3)
			program = program:sub(5)
		elseif program:match("^'.'") then
			token = string.byte(program, 2)
			program = program:sub(4)
		elseif program:match('^0x[0-9a-fA-F]') then
			token, program = program:match("^0x([0-9a-fA-F]+)(.*)$")
			token = tonumber(token, 16)
		elseif program:match('^0b[01]') then
			token, program = program:match("^0b([01]+)(.*)$")
			token = tonumber(token, 2)
		elseif program:match('^[0-9]') then
			token, program = program:match("^([0-9]+)(.*)$")
			token = tonumber(token)
		elseif program:match('^%-0x[0-9a-fA-F]') then
			token, program = program:match("^%-0x([0-9a-fA-F]+)(.*)$")
			token = -tonumber(token, 16)
		elseif program:match('^%-0b[01]') then
			token, program = program:match("^%-0b([01]+)(.*)$")
			token = -tonumber(token, 2)
		elseif program:match('^%-[0-9]') then
			token, program = program:match("^%-([0-9]+)(.*)$")
			token = -tonumber(token)
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
