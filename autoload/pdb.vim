let s:breakpoints = {}

let s:next_bp_id = 0
function! s:get_bp_id() abort
  let s:next_bp_id += 1
  return s:next_bp_id
endfunction

sign define breakpoint text=BP texthl=Search

function! s:set_breakpoint(filename, linenr) abort
  let key = printf('%s:%d', a:filename, a:linenr)
  let id = s:get_bp_id()
  let s:breakpoints[key] = {
        \ 'id': id,
        \ 'filename': a:filename,
        \ 'linenr': a:linenr,
        \ }
  " set sign
  exe printf('sign place %d line=%d name=breakpoint', id, a:linenr)
endfunction

function! s:unset_breakpoint(filename, linenr) abort
  let key = printf('%s:%d', a:filename, a:linenr)
  let id = s:breakpoints[key].id
  unlet s:breakpoints[key]
  " unset sign
  exe printf('sign unplace %d', id)
endfunction

function! pdb#set_breakpoint() abort
  let filename = expand('%')
  let linenr = line('.')
  call s:set_breakpoint(filename, linenr)
endfunction

function! pdb#unset_breakpoint() abort
  let filename = expand('%')
  let linenr = line('.')
  call s:unset_breakpoint(filename, linenr)
endfunction

function! pdb#debug() abort
  let filename = expand('%')
  if len(s:breakpoints) > 0
    let options = s:breakpoints->keys()->map({_, v -> printf('-c "break %s"', v)})
  else
    let options = ['-c continue']
  endif
  let run_command = printf('python -m pdb %s %s', join(options, ' '), filename)
  echo run_command
  exe printf('vert terminal ++close %s', run_command)
endfunction

