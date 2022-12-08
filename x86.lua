

local function getTargetOfVariable(name)
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

local function as_functionHeader(keyword)
	if keyword == "extern" then
		print("extern " .. currentFunction.name)
		currentFunction = nil
	elseif keyword == "public" or keyword == "private" then
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

oldstrings = {}
stringnum = 0

local function as_stringlit(str)
	if not oldstrings[str] then
		pos = stringnum
		stringnum = stringnum + 1
		oldstrings[str] = pos
		
		print("section .data")
		local numericalString = ""
		for i=1, #str do
			numericalString = numericalString .. tostring(string.byte(str,i)) .. ", "
		end
		numericalString = numericalString .. "0"
		print("_string"..tostring(pos)..": db "..numericalString)
		print("section .text")
	end
	print("lea eax, [_string"..tostring(pos).."]")
end

local function as_store(dest)
	print("mov "..getTargetOfVariable(dest)..", eax")
end
local function as_load(dest)
	print("mov eax, "..getTargetOfVariable(dest))
end

jumpstack = {}
jumpnum = 0

local function as_ifthen()
	print("cmp eax, 0")
	print("je _jump"..jumpnum)
	table.insert(jumpstack, jumpnum)
	jumpnum = jumpnum + 1
end
local function as_ifelse()
	local prevjumpnum = table.remove(jumpstack)
	print("jmp _jump"..jumpnum)
	print("_jump"..prevjumpnum..":")
	table.insert(jumpstack, jumpnum)
	jumpnum = jumpnum + 1
end
local function as_ifend()
	local prevjumpnum = table.remove(jumpstack)
	print("_jump"..prevjumpnum..":")
end
local function as_whileif()
	print("_jump"..jumpnum..":")
	table.insert(jumpstack, jumpnum)
	jumpnum = jumpnum + 1
end
local function as_whiledo()
	print("cmp eax, 0")
	print("je _jump"..jumpnum)
	table.insert(jumpstack, jumpnum)
	jumpnum = jumpnum + 1
end
local function as_whileend()
	local endjumpnum = table.remove(jumpstack)
	local returnjumpnum = table.remove(jumpstack)
	print("jmp _jump"..returnjumpnum)
	print("_jump"..endjumpnum..":")
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
	i = (i-1) * 4
	if i > 0 then
		print("mov [esp+"..tostring(i).."], eax")
	elseif i < 0 then
		print("mov [esp-"..tostring(-i).."], eax")
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

local function as_allocate(name)
	print("sub esp, eax")
	print("mov "..getTargetOfVariable(name).. ", esp")
end

function as_globalStart()
	print("section .text")
end

return {
	globalStart = as_globalStart,
	globalEnd = function() end,
	functionHeader = as_functionHeader,
	ret = as_return,
	variableTarget = as_variableTarget,
	numlit = as_numlit,
	stringlit = as_stringlit,
	store = as_store,
	load = as_load,
	ifthen = as_ifthen,
	ifelse = as_ifelse,
	ifend = as_ifend,
	whileif = as_whileif,
	whiledo = as_whiledo,
	whileend = as_whileend,
	allocate = as_allocate,
	functionCall_init = as_functionCall_init,
	functionCall_pass = as_functionCall_pass,
	functionCall_fini = as_functionCall_fini,
	functionPointer = as_functionPointer,
	variablePointer = as_variablePointer
}
