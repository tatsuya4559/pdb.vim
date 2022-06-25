let s:Breakpoints = {
      \ 'data': {},
      \ '_next_bp_id': 0
      \ }

function! s:Breakpoints.as_option() abort
  return self.data->keys()->map({_, v -> printf('-c "break %s"', v)})
endfunction

function! s:Breakpoints.len() abort
  return len(self.data)
endfunction

function! s:Breakpoints.add(filename, linenr) abort
  let key = printf('%s:%d', a:filename, a:linenr)
  let id = self.next_bp_id()
  let self.data[key] = {
        \ 'id': id,
        \ 'filename': a:filename,
        \ 'linenr': a:linenr,
        \ }
  " set sign
  exe printf('sign place %d line=%d name=breakpoint', id, a:linenr)
endfunction

function! s:Breakpoints.remove(filename, linenr) abort
  let key = printf('%s:%d', a:filename, a:linenr)
  let id = self.data[key].id
  unlet self.data[key]
  " unset sign
  exe printf('sign unplace %d', id)
endfunction

function! s:Breakpoints.next_bp_id() abort
  let self._next_bp_id += 1
  return self._next_bp_id
endfunction

sign define breakpoint text=BP texthl=Search

function! pdb#set_breakpoint() abort
  let filename = expand('%')
  let linenr = line('.')
  call s:Breakpoints.add(filename, linenr)
endfunction

function! pdb#unset_breakpoint() abort
  let filename = expand('%')
  let linenr = line('.')
  call s:Breakpoints.remove(filename, linenr)
endfunction

function! pdb#toggle_breakpoint() abort
  let filename = expand('%')
  let linenr = line('.')
  let key = printf('%s:%d', filename, linenr)
  if s:Breakpoints.data->has_key(key)
    call s:Breakpoints.remove(filename, linenr)
  else
    call s:Breakpoints.add(filename, linenr)
  endif
endfunction

function! pdb#debug() abort
  let filename = expand('%')
  if s:Breakpoints.len() > 0
    let options = s:Breakpoints.as_option()
  else
    let options = ['-c continue']
  endif
  let run_command = printf('python -m pdb %s %s', join(options, ' '), filename)
  echo run_command
  exe printf('vert terminal ++close %s', run_command)
endfunction

