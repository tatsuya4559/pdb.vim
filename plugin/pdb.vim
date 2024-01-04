let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('g:loaded_pdb')
  finish
endif
let g:loaded_pdb = 1

command! PdbToggleBreakpoint :call pdb#toggle_breakpoint(pdb#get_target_file(), line('.'))
command! PdbDebug :call pdb#debug()
command! PdbClear :call pdb#clear_instructions()

augroup __pdb__
    autocmd!
    autocmd VimLeave * call pdb#remove_instruction_file()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
