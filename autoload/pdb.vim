let s:breakpoints = {}
let s:rownums = []

sign define breakpoint text=BP texthl=Search
function! s:set_breakpoint_sign(id, line) abort
  echo printf('sign place %d line=%d name=breakpoint', a:id, a:line)
  exe printf('sign place %d line=%d name=breakpoint', a:id, a:line)
endfunction

function! pdb#set_breakpoint() abort
  let filename = expand('%')
  let rownum = line('.')
  let key = printf('%s:%s', filename, rownum)
  let s:breakpoints[key] = v:true
  call add(s:rownums, rownum)
  let id = len(s:rownums)
  call s:set_breakpoint_sign(id, rownum)
endfunction

function! pdb#debug() abort
  let filename = expand('%')
  if len(s:rownums) > 0
    let option = printf('-c "break %d"', s:rownums[0])
  else
    let option = '-c continue'
  endif
  let run_command = printf('python -m pdb %s %s', option, filename)
  echo run_command
  exe printf('vert terminal ++close %s', run_command)
endfunction

