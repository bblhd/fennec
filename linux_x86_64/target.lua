local outputTargets = {""}

local function open()
	table.insert(outputTargets, "")
end

local function close(n)
	n = n or 1
	while #outputTargets >= 2 and n > 0 do
		local string = table.remove(outputTargets)
		outputTargets[#outputTargets] = outputTargets[#outputTargets] .. string
		n = n - 1
	end
end

local function out(string)
	if #outputTargets >= 1 then
		outputTargets[#outputTargets] = outputTargets[#outputTargets] .. string .. '\n'
	else
		print(string)
	end
end

local function flip(n)
	if #outputTargets >= 1 then
		n = math.min(#outputTargets, n)
		for i=1, math.floor(n/2), 1 do
			local temp = outputTargets[#outputTargets-n+i]
			outputTargets[#outputTargets-n+i] = outputTargets[#outputTargets-i+1]
			outputTargets[#outputTargets-i+1] = temp
		end
	end
end

local function finish(outfile)
	local string = table.concat(outputTargets, '')
	outputTargets = {""}

	local asm_path = os.tmpname()

	local file = io.open(asm_path, 'w')
	file:write(string)
	file:close()

	if not os.execute("nasm -f elf64 "..asm_path.." -o "..outfile) then
		os.remove(asm_path)
		error("fennec compiler error: could not assemble final object file")
	end

	os.remove(asm_path)
end

local function as_variableTarget(variable)
	local offset = variable.id + (not variable.allocated and 1 or 0)
	offset = tostring(offset * 8)
	offset = (variable.allocated and "-" or "+") .. offset
	return "[rbp"..offset.."]"
end

local function as_public(name)
	out("global " .. name)
end

local function as_extern(name)
	out("extern " .. name)
end

local function as_functionDefinition(name, allocated, vararg_named)
	out(name..":")
	out("push rbp")
	out("mov rbp, rsp")
	if allocated > 0 then
		out("sub rsp, "..8*allocated)
	end
	if vararg_named then
		out("lea rax, "..as_variableTarget({allocated=false, id=vararg_named+1}))
		out("mov [rbp-8], rax")
	end
end

local function as_arrayDefinition(name, size)
	out("section .bss")
	out(name..": resb "..size)
	out("section .text")
end

local function as_return()
	out("mov rsp, rbp")
	out("pop rbp")
	out("ret")
end

local function as_numlit(value)
	out("mov rax, "..value)
end

oldstrings = {}
stringnum = 0

local function as_stringlit(str)
	if not oldstrings[str] then
		pos = stringnum
		stringnum = stringnum + 1
		oldstrings[str] = pos
		
		out("section .data")
		local numericalString = ""
		for i=1, #str do
			numericalString = numericalString .. tostring(string.byte(str,i)) .. ", "
		end
		numericalString = numericalString .. "0"
		out("_s"..tostring(pos)..": db "..numericalString)
		out("section .text")
	end
	out("lea rax, qword [_s"..tostring(pos).."]")
end

local function as_store(variable)
	out("mov "..as_variableTarget(variable)..", rax")
end
local function as_load(variable)
	out("mov rax, "..as_variableTarget(variable))
end

jumpstack = {}
jumpnum = 0

local function as_ifthen()
	out("cmp rax, 0")
	out("je _j"..jumpnum)
	table.insert(jumpstack, jumpnum)
	jumpnum = jumpnum + 1
end
local function as_ifelse()
	local prevjumpnum = table.remove(jumpstack)
	out("jmp _j"..jumpnum)
	out("_j"..prevjumpnum..":")
	table.insert(jumpstack, jumpnum)
	jumpnum = jumpnum + 1
end
local function as_ifend()
	local prevjumpnum = table.remove(jumpstack)
	out("_j"..prevjumpnum..":")
end
local function as_whileif()
	out("_j"..jumpnum..":")
	table.insert(jumpstack, jumpnum)
	jumpnum = jumpnum + 1
end
local function as_whiledo()
	out("cmp rax, 0")
	out("je _j"..jumpnum)
	table.insert(jumpstack, jumpnum)
	jumpnum = jumpnum + 1
end
local function as_whileend()
	local endjumpnum = table.remove(jumpstack)
	local returnjumpnum = table.remove(jumpstack)
	out("jmp _j"..returnjumpnum)
	out("_j"..endjumpnum..":")
end

local functionArgumentPasses = {}
local function as_functionCall_init()
	table.insert(functionArgumentPasses, 0)
end
local function as_functionCall_pass_init()
	open()
	functionArgumentPasses[#functionArgumentPasses]
		= functionArgumentPasses[#functionArgumentPasses] + 1
end
local function as_functionCall_pass_fini()
	out("push rax")
end
local function as_functionCall_fini(func)
	flip(functionArgumentPasses[#functionArgumentPasses])
	close(functionArgumentPasses[#functionArgumentPasses])
	out("call "..func)
	if functionArgumentPasses[#functionArgumentPasses] > 0 then
		out("add rsp, "..functionArgumentPasses[#functionArgumentPasses]*8)
	end
	return table.remove(functionArgumentPasses)
end

local function as_functionPointer(name)
	out("lea rax, ["..name.."]")
end

local function as_arrayPointer(name)
	out("lea rax, ["..name.."]")
end

local function as_variablePointer(variable)
	out("lea rax, "..as_variableTarget(variable))
end

local function as_allocate(variable)
	out("sub rsp, rax")
	out("mov "..as_variableTarget(variable).. ", rsp")
end

function as_globalStart()
	out("section .text")
end

return {
	finish = finish,
	globalStart = as_globalStart,
	globalEnd = function() end,
	
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
	pass_init = as_functionCall_pass_init,
	pass_fini = as_functionCall_pass_fini
}
