" *** Configuration ***

if !exists('g:pdb_startup_command')
    let g:pdb_startup_command = 'python -m pdb %s'
endif

if !exists('g:pdb_instruction_file')
    let g:pdb_instruction_file = '.pdbrc'
endif

" Supported values are:
" - new          Opens a horizontal window (default)
" - vnew         Opens a vertical window
" - enew         Opens a new full screen window
" - tabnew       Opens a new full screen window in a new tab
if !exists('g:pdb_new_command')
    let g:pdb_new_command = 'new'
endif

if !exists('g:pdb_breakpoint_sign')
    let g:pdb_breakpoint_sign = '●'
endif

if !exists('g:pdb_breakpoint_sign_highlight')
    let g:pdb_breakpoint_sign_highlight = 'WarningMsg'
endif

if !exists('g:pdb_enable_linenr_highlighting')
    let g:pdb_enable_linenr_highlighting = v:false
end

if !exists('g:pdb_sign_group')
    let g:pdb_sign_group = 'pdb'
endif

if !exists('g:pdb_sign_priority')
    let g:pdb_sign_priority = 10
endif

if !exists('g:pdb_enable_syntax_highlighting')
    let g:pdb_enable_syntax_highlighting = v:true
end

if g:pdb_enable_linenr_highlighting
    exe printf('sign define pdb_breakpoint text=%s texthl=%s numhl=%s', g:pdb_breakpoint_sign, g:pdb_breakpoint_sign_highlight, g:pdb_breakpoint_sign_highlight)
else
    exe printf('sign define pdb_breakpoint text=%s texthl=%s', g:pdb_breakpoint_sign, g:pdb_breakpoint_sign_highlight)
endif

let s:sign_parameters = printf('group=%s priority=%d', g:pdb_sign_group, g:pdb_sign_priority)

" *** Implementation ***

" pdb_instructions holds all the instructions to pdb in a dict.
let s:pdb_instructions = {}

let s:pdb_termbufnr = 0

function! s:serialize_instruction(instruction) abort
    return printf('%s %s:%d', a:instruction.command, a:instruction.file, a:instruction.line)
endfunction

function! pdb#remove_instruction_file() abort
    call delete(g:pdb_instruction_file)
endfunction

function! s:write_instruction_file() abort
    let instructions = []
    for val in values(s:pdb_instructions)
        call add(instructions, s:serialize_instruction(val))
    endfor
    call writefile(instructions, g:pdb_instruction_file)
endfunction

function! pdb#add_instruction(command, file, line, sign_name) abort
    let id = eval(max(keys(s:pdb_instructions)) + 1)
    let instruction = #{
                \ command: a:command,
                \ file: a:file,
                \ line: a:line,
                \ sign_name: a:sign_name,
                \ }
    let s:pdb_instructions[id] = instruction
    exe printf('sign place %d %s line=%d name=%s file=%s', 
                \ id, s:sign_parameters, a:line, a:sign_name, a:file)

    if s:pdb_termbufnr
        call term_sendkeys(s:pdb_termbufnr, s:serialize_instruction(instruction) .. "\<cr>")
    endif
endfunction

function! pdb#remove_instruction(id) abort
    let instruction = s:pdb_instructions[a:id]
    call remove(s:pdb_instructions, a:id)
    exe printf('sign unplace %d %s', a:id, s:sign_parameters)

    if s:pdb_termbufnr
        if instruction.command ==# 'break'
            let instruction.command = 'clear'
        endif
        call term_sendkeys(s:pdb_termbufnr, s:serialize_instruction(instruction) .. "\<cr>")
    endif
endfunction

function! pdb#find_instruction(command, file, line) abort
    for [id, val] in items(s:pdb_instructions)
        if val.command ==# a:command
                    \ && val.file ==# a:file
                    \ && val.line == a:line
            return id
        endif
    endfor
    return 0
endfunction

function! pdb#clear_instructions() abort
    for id in keys(s:pdb_instructions)
        call pdb#remove_instruction(id)
    endfor
endfunction

function! pdb#add_breakpoint(file, line) abort
    call pdb#add_instruction('break', a:file, a:line, 'pdb_breakpoint')
endfunction

function! pdb#remove_breakpoint(file, line) abort
    let id = pdb#find_instruction('break', a:file, a:line)
    if id != 0
        call pdb#remove_instruction(id)
    endif
endfunction

function! pdb#toggle_breakpoint(file, line) abort
    let id = pdb#find_instruction('break', a:file, a:line)
    if id
        call pdb#remove_instruction(id)
    else
        call pdb#add_breakpoint(a:file, a:line)
    endif
endfunction

function! pdb#get_target_file() abort
    return expand('%:p')
endfunction

function! pdb#debug() abort
    if stridx(g:pdb_startup_command, '%s') >= 0
        let cmd = printf(g:pdb_startup_command, pdb#get_target_file())
    else
        let cmd = g:pdb_startup_command
    endif

    call s:write_instruction_file()

    exe g:pdb_new_command
    let s:pdb_termbufnr = bufnr()

    call term_start([&shell, &shellcmdflag, cmd], #{ curwin: v:true })

    if g:pdb_enable_syntax_highlighting
        set syntax=python
    endif
endfunction
