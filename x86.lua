
local function as_functionHeader(keyword)
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
		return true
	end
end

local function as_return()
	if currentFunction then
		print("mov esp, ebp")
		print("pop ebp")
		print("ret")
	end
end

local function as_variableTarget(name)
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

local function as_numlit(value)
	print("mov eax, "..tostring(value))
end

local function as_store(dest)
	print("mov "..getTargetOfVariable(dest)..", eax")
end
local function as_load(dest)
	print("mov eax, "..getTargetOfVariable(dest))
end

local function as_label(jumpId)
	print(".j"..jumpId..":")
end
local function as_goto(jumpId)
	print("jmp .j"..jumpId)
end

local function as_if(jumpId)
	print("cmp eax, 0")
	print("jne .j"..jumpId)
end
local function as_fi(jumpId)
	as_label(jumpId)
end

local function as_stack_init()
	print("push ebp")
	print("mov ebp, esp")
end
local function as_stack_fini()
	print("mov esp, ebp")
	print("pop ebp")
end

local function as_functionCall_init(func)
	print("sub esp, "..functionArgCounts[func]*4)
end
local function as_functionCall_pass(func, i)
	i = (functionArgCounts[func] - i - 1) * 4
	if i > 0 then
		print("mov [esp+"..tostring(i).."], eax")
	else
		print("mov [esp], eax")
	end
end
local function as_functionCall_fini(func)
	print("call "..func)
	print("add esp, "..functionArgCounts[func]*4)
end

local function as_functionPointer(name)
	print("lea eax, "..name)
end

local function as_variablePointer(name)
	print("lea eax, "..getTargetOfVariable(name))
end

return {
	functionHeader = as_functionHeader,
	ret = as_return,
	variableTarget = as_variableTarget,
	numlit = as_numlit,
	store = as_store,
	load = as_load,
	label = as_label,
	branch = as_goto,
	ifthen = as_if,
	fi = as_fi,
	functionCall_init = as_functionCall_init,
	functionCall_pass = as_functionCall_pass,
	functionCall_fini = as_functionCall_fini,
	functionPointer = as_functionPointer,
	variablePointer = as_variablePointer
}
