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
		elseif str:match('^%a') then
			token, str = str:match('^(%a[%w%._]*)(.*)$')
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

function as_functionHeader(keyword)
	if keyword == "extern" then
		print("")
		print("extern " .. currentFunction.name)
		currentFunction = nil
	elseif keyword == "public" or keyword == "private" then
		print("")
		if keyword == "public" then
			print("global " .. currentFunction.name)
		end
		print(currentFunction.name..":")
		print("push ebp")
		print("mov ebp, esp")
		if #currentFunction.vars > 0 then
			print("sub esp, "..4*#currentFunction.vars)
		end
	end
end

function as_return()
	if currentFunction then
		print("mov esp, ebp")
		print("pop ebp")
		print("ret")
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

function compileExpression(token, nextToken, fixStack)
	if not nextToken then
		nextToken = token
		token = nextToken()
	end
	if token == "(" then
		local functionName = getCanonicalName(nextToken())
		print("sub esp, "..functionArgCounts[functionName]*4)
		for i=functionArgCounts[functionName]-1,0,-1 do
			if not compileExpression(nextToken(), nextToken, true) then
				error("compiler error: not enough many arguments for "..functionName)
			end
			if i > 0 then
				print("mov [esp+"..tostring(4*i).."], eax")
			else
				print("mov [esp], eax")
			end
		end
		if nextToken() ~= ")" then
			error("compiler error: function call for "..functionName.." is missing closing bracket.")
		end
		print("call "..functionName)
	elseif token == "{" then
		if fixStack then
			print("push ebp")
			print("mov ebp, esp")
		end
		repeat
			local action = readStatement(nextToken)
		until not action
		if fixStack then
			print("mov esp, ebp")
			print("pop ebp")
		end
	elseif token == ")" then
		return nil
	elseif token == "}" then
		return nil
	elseif token:match('^%a') then
		print("mov eax, "..getTargetOfVariable(token))
	elseif token:match('^%d') then
		print("mov eax, "..token)
	else
		error("compiler error: expression malformed")
		return nil
	end
	return true
end

function declareFunction(nextToken)
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
			elseif not token:match("^%a[%w%._]*$") then
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

function readStatement(keyword, nextToken)
	if not nextToken then
		nextToken = keyword
		keyword = nextToken()
	end
	if keyword == "return" then
		compileExpression(nextToken)
		as_return()
	elseif keyword == "let" then
		local dest = getTargetOfVariable(nextToken())
		if nextToken() ~= "=" then
			error("compiler error: let is missing equals sign")
		end
		compileExpression(nextToken)
		print("mov "..dest..", eax")
	elseif keyword == "if" then
		local jumpLabel = ".j"..jumpnum
		jumpnum = jumpnum + 1
		
		compileExpression(nextToken)
		print("cmp eax, 0")
		print("jne "..jumpLabel)
		readStatement(nextToken)
		print(jumpLabel..":")
	elseif keyword == "while" then
		local jumpLabelS = ".j"..jumpnum
		jumpnum = jumpnum + 1
		local jumpLabelE = ".j"..jumpnum
		jumpnum = jumpnum + 1
		
		print(jumpLabelS..":")
		compileExpression(nextToken)
		print("cmp eax, 0")
		print("jne "..jumpLabelE)
		readStatement(nextToken)
		print("jmp "..jumpLabelS)
		print(jumpLabelE..":")
	elseif keyword == "ASM" then
		body = nextToken()
		if body:match('^"') then
			body = body:sub(2,#body-1)
		end
		body = body:gsub('\n%s*', '\n')
		body = body:gsub('^%s*', '')
		body = body:gsub('%s*$', '')
		print(body)
	elseif keyword == "{" then
		repeat
			local action = readStatement(nextToken)
		until not action
	elseif keyword == "}" then
		return nil
	elseif keyword then
		return compileExpression(keyword, nextToken)
	end
	if keyword then
		return true
	end
end

function readDeclaration(keyword, nextToken)
	if not nextToken then
		nextToken = keyword
		keyword = nextToken()
	end
	if keyword == "extern" or keyword == "intern" or keyword == "public" or keyword == "private" then
		declareFunction(nextToken)
		as_functionHeader(keyword)
	elseif keyword == "namespace" then
		currentNamespace = nextToken()
		if currentNamespace == "none" then
			currentNamespace = ""
		end
	else
		return readStatement(keyword, nextToken)
	end
	if keyword then
		return true
	end
end

function compile(nextToken)
	local declarations = {}
	repeat
		local action = readDeclaration(nextToken)
	until not action
	return declarations
end

local file = io.open(arg[1], 'r')
local program = file:read('a')
file:close()

local tokeniser = tokenise(program)  
compile(tokeniser)
