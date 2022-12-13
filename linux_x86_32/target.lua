local output = {}

local function flip_start()
	if not output.text or #output.text < 1 then
		output.text = {""}
	end
	table.insert(output.text, "")
end

local function flip_switch()
	if output.text and #output.text >= 2 then
		table.insert(output.text, "")
	end
end

local function flip_end()
	if output.text and #output.text >= 3 then
		local string = table.remove(output.text) .. table.remove(output.text)
		output.text[#output.text] = output.text[#output.text] .. string
	end
end

local function init(string)
	if not output.init then output.init = "" end
	output.init = output.init .. string .. '\n'
end
local function bss(string)
	if not output.bss then output.bss = "" end
	output.bss = output.bss .. string .. '\n'
end
local function data(string)
	if not output.data then output.data = "" end
	output.data = output.data .. string .. '\n'
end
local function text(string)
	if not output.text or #output.text < 1 then output.text = {""} end
	output.text[#output.text] = output.text[#output.text] .. string .. '\n'
end

local function finish(outfile)
	local string = (output.init or "")
		.. (output.bss and ("section .bss\n" .. output.bss) or "")
		.. (output.data and ("section .data\n" .. output.data) or "")
		.. (output.text and "section .text\n" .. table.concat(output.text, '') or "")
	output = {}
	
	local line = 1
	for l in string:gmatch("[^\n]+") do
		print(line, l)
		line = line + 1
	end

	local asm_path = os.tmpname()

	local file = io.open(asm_path, 'w')
	file:write(string)
	file:close()

	if not os.execute("nasm -f elf "..asm_path.." -o "..outfile) then
		os.remove(asm_path)
		error("fennec compiler error: could not assemble final object file")
	end

	os.remove(asm_path)
end

local function offsetString(amount, positiveBias, negativeBias)
	local amount = 4 * (amount + (amount>0 and (positiveBias or 0) or -(negativeBias or 0)))
	if amount == 0 then
		return ''
	else
		return (amount>0 and '+' or '-') .. tostring(amount>0 and amount or -amount)
	end
end

local builtins = {
	['add'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov eax, [esp]")
		for i=1,n-1 do text("add eax, [esp"..offsetString(i).."]") end
	end},
	['sub'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov eax, [esp]")
		for i=1,n-1 do text("sub eax, [esp"..offsetString(i).."]") end
	end},
	['neg'] = {required = 1, moreAllowed = false, f=function(n)
		text("mov eax, [esp]")
		text("neg eax")
	end},
	['mul'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov eax, [esp]")
		for i=1,n-1 do text("mul eax, [esp"..offsetString(i).."]") end
	end},
	['div'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov eax, [esp]")
		for i=1,n-1 do
			text("mov edx, 0")
			text("div dword [esp"..offsetString(i).."]")
		end
	end},
	['idiv'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov eax, [esp]")
		for i=1,n-1 do
			text("cqo")
			text("idiv dword [esp"..offsetString(i).."]")
		end
	end},
	['mod'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov eax, [esp]")
		text("xor edx, edx")
		text("div dword [esp+4]")
		text("mov eax, edx")
	end},
	['imod'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov eax, [esp]")
		text("cqo")
		text("idiv dword [esp+4]")
		text("mov eax, edx")
	end},

	['eq'] = {required = 2, moreAllowed = false, f=function(n)
		text("xor eax, eax")
		text("mov ebx, [esp]")
		text("cmp ebx, [esp+4]")
		text("setz al")
	end},
	['ne'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov eax, [esp]")
		text("xor eax, [esp+4]")
	end},
	['lt'] = {required = 2, moreAllowed = false, f=function(n)
		text("xor eax, eax")
		text("mov ebx, [esp]")
		text("inc ebx")
		text("cmp ebx, [esp+4]")
		text("setle al")
	end},
	['lte'] = {required = 2, moreAllowed = false, f=function(n)
		text("xor eax, eax")
		text("mov ebx, [esp]")
		text("cmp ebx, [esp+4]")
		text("setle al")
	end},
	['gt'] = {required = 2, moreAllowed = false, f=function(n)
		text("xor eax, eax")
		text("mov ebx, [esp+4]")
		text("inc ebx")
		text("cmp ebx, [esp]")
		text("setle al")
	end},
	['gte'] = {required = 2, moreAllowed = false, f=function(n)
		text("xor eax, eax")
		text("mov ebx, [esp+4]")
		text("cmp ebx, [esp]")
		text("setle al")
	end},
	['not'] = {required = 1, moreAllowed = false, f=function(n)
		text("xor eax, eax")
		text("cmp [esp], 0")
		text("setz al")
		text("xor eax, 1")
	end},
	['and'] = {required = 2, moreAllowed = true, f=function(n)
		text("cmp dword [esp], 0")
		text("mov eax, 0")
		text("setz al")
		text("dec eax")
		if n > 2 then
			for i=2,n-1 do
				text("test eax, [esp"..offsetString(i-1).."]")
				text("mov eax, 0")
				text("setz al")
				text("dec eax")
			end
		end
		text("and eax, [esp"..offsetString(n-1).."]")
	end},
	['or'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov eax, [esp]")
		for i=1,n-1 do text("or eax, [esp"..offsetString(i).."]") end
	end},

	['bnot'] = {required = 1, moreAllowed = false, f=function(n)
		text("mov eax, [esp]")
		text("not eax")
	end},
	['band'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov eax, [esp]")
		for i=1,n-1 do text("and eax, [esp"..offsetString(i).."]") end
	end},
	['lsl'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov eax, [esp]")
		text("mov cl, [esp"..offsetString(1).."]")
		text("shl eax, cl")
	end},
	['lsr'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov eax, [esp]")
		text("mov cl, [esp"..offsetString(1).."]")
		text("shr eax, cl")
	end},
	['asr'] = {required = 2, moreAllowed = false,f=function(n)
		text("mov eax, [esp]")
		text("mov cl, [esp"..offsetString(1).."]")
		text("sar eax, cl")
	end},

	['syscall'] = {required = 1, moreAllowed = true, f=function(n)
		text("mov eax, [esp]")
		local registers = {"ebx", "ecx", "edx", "esi", "edi"}
		for i=1,n-1 do
			text("mov "..registers[i]..", [esp"..offsetString(i).."]")
		end
		text("int 80h")
	end},

	['load8'] = {required = 1, moreAllowed = false, f=function(n)
		text("mov ebx, [esp]")
		text("xor eax, eax")
		text("mov al, [ebx]")
	end},
	['load16'] = {required = 1, moreAllowed = false, f=function(n)
		text("mov ebx, [esp]")
		text("xor eax, eax")
		text("mov ax, [ebx]")
	end},
	['load32'] = {required = 1, moreAllowed = false, f=function(n)
		text("mov ebx, [esp]")
		text("mov eax, [ebx]")
	end},

	['store8'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov ebx, [esp]")
		text("mov al, [esp+4]")
		text("mov [ebx], al")
	end},
	['store16'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov ebx, [esp]")
		text("mov ax, [esp+4]")
		text("mov [ebx], ax")
	end},
	['store32'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov ebx, [esp]")
		text("mov eax, [esp+4]")
		text("mov [ebx], eax")
	end},
}

builtins["asl"] = builtins["lsl"]
builtins["bor"] = builtins["or"]
builtins['loadWord'] = builtins['load32']
builtins['storeWord'] = builtins['store32']
builtins['loadByte'] = builtins['load8']
builtins['storeByte'] = builtins['store8']

local function as_variableTarget(variable)
	return "[ebp"..offsetString(variable.allocated and -variable.id or variable.id, 1).."]"
end

local function as_public(name)
	init("global " .. name)
end

local function as_extern(name)
	init("extern " .. name)
end

local function as_functionDefinition(name, allocated, vararg_named)
	text(name..":")
	text("push ebp")
	text("mov ebp, esp")
	if allocated > 0 then
		text("sub esp, "..4*allocated)
	end
	if vararg_named then
		text("lea eax, "..as_variableTarget({allocated=false, id=vararg_named+1}))
		text("mov [ebp-4], eax")
	end
end

local function as_arrayDefinition(name, size)
	bss(name..": alignb 4, resb "..size)
end

local function as_return()
	text("mov esp, ebp")
	text("pop ebp")
	text("ret")
end

local function as_numlit(value)
	text("mov eax, "..value)
end

oldstrings = {}
stringnum = 0

local function as_stringlit(str)
	local pos = oldstrings[str]
	if not pos then
		pos = stringnum
		stringnum = stringnum + 1
		oldstrings[str] = pos
		
		local numericalString = ""
		for i=1, #str do
			numericalString = numericalString .. tostring(string.byte(str,i)) .. ", "
		end
		numericalString = numericalString .. "0"
		data("_s"..tostring(pos)..": db "..numericalString)
	end
	text("lea eax, [_s"..tostring(pos).."]")
end

local function as_store(variable)
	text("mov "..as_variableTarget(variable)..", eax")
end
local function as_load(variable)
	text("mov eax, "..as_variableTarget(variable))
end

jumpstack = {}
jumpnum = 0

local function as_ifthen()
	text("cmp eax, 0")
	text("je _j"..jumpnum)
	table.insert(jumpstack, jumpnum)
	jumpnum = jumpnum + 1
end
local function as_ifelse()
	local prevjumpnum = table.remove(jumpstack)
	text("jmp _j"..jumpnum)
	text("_j"..prevjumpnum..":")
	table.insert(jumpstack, jumpnum)
	jumpnum = jumpnum + 1
end
local function as_ifend()
	local prevjumpnum = table.remove(jumpstack)
	text("_j"..prevjumpnum..":")
end
local function as_whileif()
	text("_j"..jumpnum..":")
	table.insert(jumpstack, jumpnum)
	jumpnum = jumpnum + 1
end
local function as_whiledo()
	text("cmp eax, 0")
	text("je _j"..jumpnum)
	table.insert(jumpstack, jumpnum)
	jumpnum = jumpnum + 1
end
local function as_whileend()
	local endjumpnum = table.remove(jumpstack)
	local returnjumpnum = table.remove(jumpstack)
	text("jmp _j"..returnjumpnum)
	text("_j"..endjumpnum..":")
end

local functionArgumentPasses = {}
local function as_functionCall_init()
	table.insert(functionArgumentPasses, 0)
	flip_start()
end
local function as_functionCall_pass()
	text("mov [esp"..offsetString(functionArgumentPasses[#functionArgumentPasses]).."], eax")

	functionArgumentPasses[#functionArgumentPasses]
		= functionArgumentPasses[#functionArgumentPasses] + 1
end
local function as_functionCall_fini(func)
	flip_switch()
	if functionArgumentPasses[#functionArgumentPasses] > 0 then
		text("sub esp, "..functionArgumentPasses[#functionArgumentPasses]*8)
	end
	flip_end()
	if builtins[func] then
		builtins[func].f(functionArgumentPasses[#functionArgumentPasses])
	else
		text("call "..func)
	end
	if functionArgumentPasses[#functionArgumentPasses] > 0 then
		text("add esp, "..functionArgumentPasses[#functionArgumentPasses]*8)
	end
	return table.remove(functionArgumentPasses)
end

local function as_functionPointer(name)
	text("lea eax, ["..name.."]")
end
local function as_arrayPointer(name)
	text("lea eax, ["..name.."]")
end

local function as_variablePointer(variable)
	text("lea eax, "..as_variableTarget(variable))
end

local function as_allocate(variable)
	text("sub esp, eax")
	text("not esp")
	text("or esp, 0x1F")
	text("not esp")
	text("mov "..as_variableTarget(variable).. ", esp")
end

return {
	WORD_SIZE = 4,
	
	finish = finish,

	builtin = function(name) return builtins[name] end,
	
	functionDefinition = as_functionDefinition,
	public = as_public,
	extern = as_extern,
	arrayDefinition = as_arrayDefinition,
	
	variableTarget = as_variableTarget,
	numlit = as_numlit,
	stringlit = as_stringlit,
	arrayPointer = as_arrayPointer,
	functionPointer = as_functionPointer,
	variablePointer = as_variablePointer,

	ret = as_return,
	allocate = as_allocate,
	store = as_store,
	load = as_load,

	ifthen = as_ifthen,
	ifelse = as_ifelse,
	ifend = as_ifend,
	whileif = as_whileif,
	whiledo = as_whiledo,
	whileend = as_whileend,
	
	call_init = as_functionCall_init,
	call_fini = as_functionCall_fini,
	pass = as_functionCall_pass
}
