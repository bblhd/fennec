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

	local asm_path = os.tmpname()

	local file = io.open(asm_path, 'w')
	file:write(string)
	file:close()

	if not os.execute("nasm -f macho64 "..asm_path.." -o "..outfile) then
		os.remove(asm_path)
		error("fennec compiler error: could not assemble final object file")
	end

	os.remove(asm_path)
end

local function offsetString(amount, positiveBias, negativeBias)
	local amount = 8 * (amount + (amount>0 and (positiveBias or 0) or -(negativeBias or 0)))
	if amount == 0 then
		return ''
	else
		return (amount>0 and '+' or '-') .. tostring(amount>0 and amount or -amount)
	end
end

builtins = {
	['add'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov rax, [rsp]")
		for i=1,n-1 do text("add rax, [rsp"..offsetString(i).."]") end
	end},
	['sub'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov rax, [rsp]")
		for i=1,n-1 do text("sub rax, [rsp"..offsetString(i).."]") end
	end},
	['neg'] = {required = 1, moreAllowed = false, f=function(n)
		text("mov rax, [rsp]")
		text("neg rax")
	end},
	['mul'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov rax, [rsp]")
		for i=1,n-1 do text("mul qword [rsp"..offsetString(i).."]") end
	end},
	['div'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov rax, [rsp]")
		for i=1,n-1 do
			text("mov rdx, 0")
			text("div qword [rsp"..offsetString(i).."]")
		end
	end},
	['idiv'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov rax, [rsp]")
		for i=1,n-1 do
			text("cqo")
			text("idiv qword [rsp"..offsetString(i).."]")
		end
	end},
	['mod'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov rax, [rsp]")
		text("mov rdx, 0")
		text("div qword [rsp+8]")
		text("mov rax, rdx")
	end},
	['imod'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov rax, [rsp]")
		text("cqo")
		text("idiv qword [rsp+8]")
		text("mov rax, rdx")
	end},

	['eq'] = {required = 2, moreAllowed = false, f=function(n)
		text("xor rax, rax")
		text("mov rbx, [rsp]")
		text("cmp rbx, [rsp+8]")
		text("setz al")
	end},
	['ne'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov rax, [rsp]")
		text("xor rax, [rsp+8]")
	end},
	['lt'] = {required = 2, moreAllowed = false, f=function(n)
		text("xor rax, rax")
		text("mov rbx, [rsp]")
		text("inc rbx")
		text("cmp rbx, [rsp+8]")
		text("setle al")
	end},
	['lte'] = {required = 2, moreAllowed = false, f=function(n)
		text("xor rax, rax")
		text("mov rbx, [rsp]")
		text("cmp rbx, [rsp+8]")
		text("setle al")
	end},
	['gt'] = {required = 2, moreAllowed = false, f=function(n)
		text("xor rax, rax")
		text("mov rbx, [rsp+8]")
		text("inc rbx")
		text("cmp rbx, [rsp]")
		text("setle al")
	end},
	['gte'] = {required = 2, moreAllowed = false, f=function(n)
		text("xor rax, rax")
		text("mov rbx, [rsp+8]")
		text("cmp rbx, [rsp]")
		text("setle al")
	end},
	['not'] = {required = 1, moreAllowed = false, f=function(n)
		text("xor rax, rax")
		text("cmp [rsp], 0")
		text("setz al")
		text("xor rax, 1")
	end},
	['and'] = {required = 2, moreAllowed = true, f=function(n)
		text("cmp qword [rsp], 0")
		text("mov rax, 0")
		text("setz al")
		text("dec rax")
		if n > 2 then
			for i=2,n-1 do
				text("test rax, [rsp"..offsetString(i-1).."]")
				text("mov rax, 0")
				text("setz al")
				text("dec rax")
			end
		end
		text("and rax, [rsp"..offsetString(n-1).."]")
	end},
	['or'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov rax, [rsp]")
		for i=1,n-1 do text("of rax, [rsp"..offsetString(i).."]") end
	end},

	['bnot'] = {required = 1, moreAllowed = false, f=function(n)
		text("mov rax, [rsp]")
		text("not rax")
	end},
	['band'] = {required = 2, moreAllowed = true, f=function(n)
		text("mov rax, [rsp]")
		for i=1,n-1 do text("and rax, [rsp"..offsetString(i).."]") end
	end},
	['lsl'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov rax, [rsp]")
		text("mov cl, [rsp+8]")
		text("shl rax, cl")
	end},
	['lsr'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov rax, [rsp]")
		text("mov cl, [rsp+8]")
		text("shr rax, cl")
	end},
	['asr'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov rax, [rsp]")
		text("mov cl, [rsp+8]")
		text("sar rax, cl")
	end},

	['syscall'] = {required = 1, moreAllowed = true, f=function(n)
		text("mov rax, [rsp]")
		local registers = {"rdi", "rsi", "rdx", "rcx", "r8", "r9"}
		for i=1,n-1 do
			text("mov "..registers[i]..", [rsp"..offsetString(i).."]")
		end
		text("syscall")
	end},

	['load8'] = {required = 1, moreAllowed = false, f=function(n)
		text("mov rbx, [rsp]")
		text("xor rax, rax")
		text("mov al, [rbx]")
	end},
	['load16'] = {required = 1, moreAllowed = false, f=function(n)
		text("mov rbx, [rsp]")
		text("xor rax, rax")
		text("mov ax, [rbx]")
	end},
	['load32'] = {required = 1, moreAllowed = false, f=function(n)
		text("mov rbx, [rsp]")
		text("xor rax, rax")
		text("mov eax, [rbx]")
	end},
	['load64'] = {required = 1, moreAllowed = false, f=function(n)
		text("mov rax, [rsp]")
		text("mov rax, [rax]")
	end},

	['store8'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov rbx, [rsp]")
		text("mov rax, [rsp+8]")
		text("mov [rbx], al")
	end},
	['store16'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov rbx, [rsp]")
		text("mov rax, [rsp+8]")
		text("mov [rbx], ax")
	end},
	['store32'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov rbx, [rsp]")
		text("mov rax, [rsp+8]")
		text("mov [rbx], eax")
	end},
	['store64'] = {required = 2, moreAllowed = false, f=function(n)
		text("mov rbx, [rsp]")
		text("mov rax, [rsp+8]")
		text("mov [rbx], rax")
	end},
}

builtins["asl"] = builtins["lsl"]
builtins["bor"] = builtins["or"]
builtins['loadWord'] = builtins['load64']
builtins['storeWord'] = builtins['store64']
builtins['loadByte'] = builtins['load8']
builtins['storeByte'] = builtins['store8']

local function as_variableTarget(variable)
	return "[rbp"..offsetString(variable.allocated and -variable.id or variable.id, 1).."]"
end

local function as_public(name)
	init("global " .. name)
end

local function as_extern(name)
	init("extern " .. name)
end

local function as_functionDefinition(name, allocated, vararg_named)
	text(name..":")
	text("push rbp")
	text("mov rbp, rsp")
	if allocated > 0 then
		text("sub rsp, "..8*allocated)
	end
	if vararg_named then
		text("lea rax, "..as_variableTarget({allocated=false, id=vararg_named+1}))
		text("mov [rbp-8], rax")
	end
end

local function as_arrayDefinition(name, size)
	bss(name..": alignb 8, resb "..size)
end

local function as_return()
	text("mov rsp, rbp")
	text("pop rbp")
	text("ret")
end

local function as_numlit(value)
	text("mov rax, "..value)
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
	text("lea rax, qword [_s"..tostring(pos).."]")
end

local function as_store(variable)
	text("mov "..as_variableTarget(variable)..", rax")
end
local function as_load(variable)
	text("mov rax, "..as_variableTarget(variable))
end

jumpstack = {}
jumpnum = 0

local function as_ifthen()
	text("cmp rax, 0")
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
	text("cmp rax, 0")
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
	text("mov [rsp"..offsetString(functionArgumentPasses[#functionArgumentPasses]).."], rax")

	functionArgumentPasses[#functionArgumentPasses]
		= functionArgumentPasses[#functionArgumentPasses] + 1
end
local function as_functionCall_fini(func)
	flip_switch()
	if functionArgumentPasses[#functionArgumentPasses] > 0 then
		text("sub rsp, "..functionArgumentPasses[#functionArgumentPasses]*8)
	end
	flip_end()
	if builtins[func] then
		builtins[func].f(functionArgumentPasses[#functionArgumentPasses])
	else
		text("call "..func)
	end
	if functionArgumentPasses[#functionArgumentPasses] > 0 then
		text("add rsp, "..functionArgumentPasses[#functionArgumentPasses]*8)
	end
	return table.remove(functionArgumentPasses)
end

local function as_functionPointer(name)
	text("lea rax, ["..name.."]")
end

local function as_arrayPointer(name)
	text("lea rax, ["..name.."]")
end

local function as_variablePointer(variable)
	text("lea rax, "..as_variableTarget(variable))
end

local function as_allocate(variable)
	text("sub rsp, rax")
	text("not rsp")
	text("or rsp, 0x3F")
	text("not rsp")
	text("mov "..as_variableTarget(variable).. ", rsp")
end

init("default rel")

return {
	WORD_SIZE = 8,

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
