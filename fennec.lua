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
		str = str:gsub('^%s+//[^\n]*', '')
		str = str:gsub('^%s+', '')
		if #str <= 0 then
			return nil
		end
		
		local token = nil
		if str:match('^"') then
			local i = 2
			while str:sub(i,i) ~= '"' and i <= #str do
				if str:sub(i,i) == '\\' then
					i = i + 1
				end
				i = i + 1
			end
			if i > #str then
				error("compiler error: no end of string")
			end
			token = str:sub(1,i)
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
			error("compiler error: unknown token")
		end
		return token
	end
end

currentNamespace = ""
currentFunction = nil
functionArgCounts = {}
constraints = {}
jumpnum = 0

local isa = require "x86"

function makeNamespacedName(namespaced)
	local namespace, name = namespaced:match('^([^%._]+)%.(.*)$')
	if not name or not namespace then
		name = namespaced
		namespace = currentNamespace
		if currentNamespace == "" then
			return namespaced
		else
			return currentNamespace .. "." .. namespaced
		end
	end
	return namespace .. "." .. name
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
		jumpnum = 0
		currentFunction.name = makeNamespacedName(nextToken())
		
		local section = 1
		local token = nextToken()
		while token ~= ")" do
			if section == 1 and token == ";" then 
				section = 2
			elseif not token:match("^[%a_][%w%._]*$") then
				error("compiler error: function arguments malformed")
			elseif section == 1 then
				table.insert(currentFunction.args, token)
			elseif section == 2 then
				table.insert(currentFunction.vars, token)
			end
			token = nextToken()
		end
		functionArgCounts[currentFunction.name] = #currentFunction.args
	else
		error("compiler error: function declaration malformed")
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
	error("compiler error: undeclared variable '"..name.."'")
end

function getJumpID()
	jumpnum = jumpnum + 1
	return jumpnum
end

function requireToken(what, nextToken, errorMessage)
	if nextToken() ~= what then
		error("compiler error: "..errorMessage)
	end
end

function compileExpression(token, nextToken, fixStack)
	if not nextToken then
		nextToken = token
		token = nextToken()
	end
	
	if token == "(" then
		local functionName = getCanonicalName(nextToken())
		
		isa.functionCall_init(functionName)
		for i = 1,functionArgCounts[functionName] do
			compileExpression(nextToken(), nextToken, true)
			isa.functionCall_pass(functionName, i)
		end
		isa.functionCall_fini(functionName)
		
		requireToken(")", nextToken, "function call for "..functionName.." is missing closing bracket.")
	elseif token == "{" then
		local statement = nextToken()
		while statement ~= "}" do
			compileStatement(statement, nextToken)
			statement = nextToken()
		end
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
	else
		error("compiler error: expression malformed")
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
		local jumpId = getJumpID()
		
		compileExpression(nextToken)
		isa.ifthen(jumpId)
		compileStatement(nextToken)
		isa.fi(jumpId)
	elseif keyword == "while" then
		local jumpIdS = getJumpID()
		local jumpIdE = getJumpID()
		
		compileExpression(nextToken)
		isa.label(jumpIdS)
		isa.ifthen(jumpIdE)
		compileStatement(nextToken)
		isa.branch(jumpIdS)
		isa.fi(jumpIdE)
	elseif keyword == "ASM" then
		body = nextToken()
		if body:match('^"') then
			body = body:sub(2,#body-1)
		end
		body = body:gsub('\n%s*', '\n'):gsub('^%s*', ''):gsub('%s*$', '')
		print(body)
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
	while compileDeclaration(nextToken) do end
end

local file = io.open(arg[1], 'r')
local program = file:read('a')
file:close()

local tokeniser = tokenise(program)  
compile(tokeniser)
