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
				if str:sub(i,i) ~= '\\' then
					i = i + 1
				end
				i = i + 1
			end
			if i > #str then
				error("compiler error: no end of string")
			end
			token = str:sub(2,i-1)
			str = str:sub(i+1)
		elseif str:match('^%d') then
			if str:match('^0%D') then
				token, str = str:match("^(0)(.*)$")
			else
				if str:match('^0x') then
					token, str = str:match("^(0x[1-9]%d*)(.*)$")
				elseif str:match('^0b') then
					token, str = str:match("^(0b[1-9]%d*)(.*)$")
				else
					token, str = str:match("^([1-9]%d*)(.*)$")
				end
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
		if #currentFunction.args > 0 or #currentFunction.vars > 0 then
			print("push edi")
			print("mov edi, esp")
		end
		if #currentFunction.vars > 0 then
			print("add esp, "..4*#currentFunction.vars)
		end
	end
end

function as_return()
	if currentFunction then
		if #currentFunction.args > 0 or #currentFunction.vars > 0 then
			print("mov edi, [edi]")
		end
		print("ret")
	end
end

function offstr(varoff)
	if varoff < 0 then
		return tostring(varoff)
	elseif varoff == 0 then
		return ""
	else
		return "+"..tostring(varoff)
	end
end

function getVaroff(name)
	for k,v in ipairs(currentFunction.args) do
		if v == name then
			return k + 1
		end
	end
	if varoff == nil then
		for k,v in ipairs(currentFunction.vars) do
			if v == name then
				return -k
			end
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
		if fixStack then
			print("mov esp, ebp")
			print("pop ebp")
		end
		local functionName = getCanonicalName(nextToken())
		local varoff = functionArgCounts[functionName] - 0
		while true do
			if compileExpression(nextToken(), nextToken, true) then
				varoff = varoff - 1
				if varoff < 0 then
					error("compiler error: too many arguments for "..functionName)
				end
				print("mov [esp"..offstr(4*varoff).."], eax")
			elseif varoff > 0 then
				error("compiler error: not enough many arguments for "..functionName)
			else
				break
			end
		end
		print("call "..functionName)
	elseif token == "{" then
		repeat
			local action = readStatement(nextToken)
		until not action
	elseif token == ")" then
		if fixStack then
			print("mov esp, ebp")
			print("pop ebp")
		end
		return nil
	elseif token == "}" then
		if fixStack then
			print("mov esp, ebp")
			print(tab.."pop ebp")
		end
		return nil
	elseif token:match('^%a') then
		print("mov eax, [edi"..offstr(4*getVaroff(token)).."]")
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

jumpnum = 0

function readStatement(keyword, nextToken)
	if not nextToken then
		nextToken = keyword
		keyword = nextToken()
	end
	if keyword == "return" then
		compileExpression(nextToken)
		as_return()
	elseif keyword == "let" then
		local dest = getVaroff(nextToken())
		if nextToken() ~= "=" then
			error("compiler error: let is missing equals sign")
		end
		compileExpression(nextToken)
		print("mov [edi"..offstr(4*dest).."], eax")
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
	as_return()
	return declarations
end

local file = io.open(arg[1], 'r')
local program = file:read('a')
file:close()

local tokeniser = tokenise(program)  
compile(tokeniser)
