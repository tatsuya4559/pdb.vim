let s:save_cpo = &cpoptions
set cpoptions&vim

if exists('g:loaded_pdb')
  finish
endif
let g:loaded_pdb = 1

command! ToggleBreakpoint :call pdb#toggle_breakpoint()
command! StartDebug :call pdb#debug()

let &cpoptions = s:save_cpo
unlet s:save_cpo
