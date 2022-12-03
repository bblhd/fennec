currentLine = 1
currentNamespace = ""
currentFunction = nil
functionArgCounts = {}

local isa = require "x86"

function main()
	if not arg[1] then
		error("no file to compile")
	end
	
	local file = io.open(arg[1], 'r')
	local program = file:read('a')
	file:close()
	compile(tokenise(program))
end

function cerr(msg)
	error("compiler error at line "..currentLine.." in file "..arg[1]..": "..msg)
end

function dump(o, t)
	if not t then t = '' else t = t .. '  ' end
	if type(o) == 'table' then
		local s = '{\n'
		for k,v in pairs(o) do
			s = s .. t .. '  [' .. dump(k, t) .. '] = ' .. dump(v, t) .. ',\n'
		end
		return s .. t .. '}'
	elseif type(o) == 'string' then
		return '"'..o..'"'
	else
		return tostring(o)
	end
end

function ival(list)
	local i = 0
	return function()
		i = i + 1
		return list[i]
	end
end

function listof(iterator)
	local l = {}
	local i = 0
	for v in iterator do
		i = i + 1
		l[i] = v
	end
	return l
end

function tokenise(str)
	return function()
		if str:match('^%s') then
		local whitespace
			whitespace, str = str:match('^(%s+)(.*)$')
			local _, count = (whitespace or ""):gsub("\n", "")
			currentLine = currentLine + count
		end
		if str:match('^//') then
		local comment
			comment, str = str:match('^(//[^\n]%s+)(.*)$')
		local _, count = (comment or ""):gsub("\n", "")
		currentLine = currentLine + count
		end
		--whitespace, str = str:match('^(%s+//[^\n]\s*)(.*)$', '')
		if #str <= 0 then
			return nil
		end
		
		local token = nil
		if str:match('^"') then
			local i = 2
			token = "\""
			while str:sub(i,i) ~= '"' and i <= #str do
				if str:sub(i,i) == '\\' then
					i = i + 1
					if str:sub(i,i) == 'n' then
						token = token .. "\n"
					elseif str:sub(i,i) == 't' then
						token = token .. "\t"
					else
						token = token .. str:sub(i,i)
					end
				else
					token = token .. str:sub(i,i)
				end
				i = i + 1
			end
			token = token .. "\""
			if i > #str then
				cerr("no end of string")
			end
			str = str:sub(i+1)
		elseif str:match('^%d') then
			if str:match('^0%D') then
				token, str = str:match("^(0)(.*)$")
			else
				token, str = str:match("^([1-9]%d*)(.*)$")
			end
		elseif str:match('^[%a_]') then
			token, str = str:match('^([%a_][%w%._]*)(.*)$')
		elseif str:match('^%p') then
			if str:match('^[%(%)%[%]{},]') then
				token, str = str:match("^(.)(.*)$")
			else
				token, str = str:match('^(%p+)(.*)$')
			end
		end
		
		if not token then
			cerr("unknown token")
		end
		return token
	end
end

function makeNamespacedName(namespaced)
	local namespace, name = namespaced:match('^([^%._]+)%.(.*)$')
	if not name or not namespace then
		name = namespaced
		namespace = currentNamespace
		if currentNamespace == "" then
			return namespaced
		else
			return currentNamespace .. "_" .. namespaced
		end
	end
	return namespace .. "_" .. name
end

function getCanonicalName(name)
	local namespaced = makeNamespacedName(name)
	for k,v in pairs(functionArgCounts) do
		if k == namespaced then
			return namespaced
		end
	end
	return name
end

function getFunctionHeader(nextToken)
	if nextToken() == "(" then
		currentFunction = {
			name = "",
			args = {},
			vars = {},
		}
		currentFunction.name = makeNamespacedName(nextToken())
		
		local section = 1
		local token = nextToken()
		while token ~= ")" do
			if section == 1 and token == ";" then 
				section = 2
			elseif not token:match("^[%a_][%w%._]*$") then
				cerr("function arguments malformed")
			elseif section == 1 then
				table.insert(currentFunction.args, token)
			elseif section == 2 then
				table.insert(currentFunction.vars, token)
			end
			token = nextToken()
		end
		functionArgCounts[currentFunction.name] = #currentFunction.args
	else
		cerr("function declaration malformed")
	end
end

function getTargetOfVariable(name)
	for k,v in ipairs(currentFunction.args) do
		if v == name then
			return "[ebp+"..tostring(4 * (k+1)).."]"
		end
	end
	for k,v in ipairs(currentFunction.vars) do
		if v == name then
			return "[ebp-"..tostring(4*k).."]"
		end
	end
	cerr("undeclared variable '"..name.."'")
end

function requireToken(what, nextToken, errorMessage)
	if nextToken() ~= what then
		cerr(errorMessage)
	end
end

function compileExpression(token, nextToken, fixStack)
	if not nextToken then
		nextToken = token
		token = nextToken()
	end
	
	if token == "(" then
		local functionName = getCanonicalName(nextToken())
		if not functionArgCounts[functionName] then
			cerr("undeclared function")
		end
		
		isa.functionCall_init(functionName)
		for i = 1,functionArgCounts[functionName] do
			compileExpression(nextToken(), nextToken, true)
			isa.functionCall_pass(functionName, i)
		end
		isa.functionCall_fini(functionName)
		
		requireToken(")", nextToken, "function call for "..functionName.." is missing closing bracket.")
	elseif token == "^" then
		local name = nextToken()
		local canon = getCanonicalName(name)
		if functionArgCounts[canon] then
			isa.functionPointer(canon)
		else
			isa.variablePointer(name)
		end
	elseif token:match('^[%a_]') then
		isa.load(token)
	elseif token:match('^%d') then
		isa.numlit(tonumber(token))
	elseif token:match('^"') then
		token = token:sub(2,#token-1)
		isa.stringlit(token)
	else
		cerr(token .. " is not a valid expression")
		return nil
	end
	return true
end

function compileStatement(keyword, nextToken)
	if not nextToken then
		nextToken = keyword
		keyword = nextToken()
	end
	
	if keyword == "return" then
		compileExpression(nextToken)
		isa.ret()
	elseif keyword == "let" then
		local var = nextToken()
		requireToken("=", nextToken, "let is missing equals sign")
		compileExpression(nextToken)
		isa.store(var)
	elseif keyword == "if" then
		compileExpression(nextToken)
		isa.ifthen()
		compileStatement(nextToken)
		isa.ifend()
	elseif keyword == "ifelse" then
		compileExpression(nextToken)
		isa.ifthen()
		compileStatement(nextToken)
		requireToken("else", nextToken, "ifelse missing else")
		isa.ifelse()
		compileStatement(nextToken)
		isa.ifend()
	elseif keyword == "while" then
		isa.whileif()
		compileExpression(nextToken)
		isa.whiledo()
		compileStatement(nextToken)
		isa.whileend()
	elseif keyword == "ASM" then
		local body = nextToken()
		if body:match('^"') then
			body = body:sub(2,#body-1)
		end
		body = body:gsub('\n%s*', '\n'):gsub('^%s*', ''):gsub('%s*$', '')
		print(body)
	elseif keyword == "allocate" then
		compileExpression(nextToken)
		local units = nextToken()
		if units == "words" or units == "word" then
		elseif units == "bytes" or units == "byte" then
		else
			cerr("allocate invalid units")
		end
		requireToken("->", nextToken, "allocate missing arrow")
		local var = nextToken()
		isa.allocate(var)
	elseif keyword == "{" then
		local statement = nextToken()
		while statement ~= "}" do
			compileStatement(statement, nextToken)
			statement = nextToken()
		end
	elseif keyword then
		return compileExpression(keyword, nextToken)
	end
	if keyword then
		return true
	end
end

function compileDeclaration(keyword, nextToken)
	if not nextToken then
		nextToken = keyword
		keyword = nextToken()
	end
	
	if keyword == "extern" or keyword == "intern" or keyword == "public" or keyword == "private" then
		getFunctionHeader(nextToken)
		if isa.functionHeader(keyword) then
			compileStatement(nextToken)
		end
		isa.ret()
		return true
	elseif keyword == "namespace" then
		currentNamespace = nextToken()
		if currentNamespace == "none" then
			currentNamespace = ""
		end
		return true
	end
end

function compile(nextToken)
	isa.globalStart()
	while compileDeclaration(nextToken) do end
	isa.globalEnd()
end

main()
