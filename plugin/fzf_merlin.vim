command! -bang FZFMerlinOutline call fzf_merlin#merlin_outline(<bang>0)

function! s:command_callback (bufnr)
  let l:fname = expand("%:p")
  let l:cmd = 'ocamlmerlin server errors -filename ' . fname
  return l:cmd
endfunction

function! s:callback (buffer, lines)
  let l:errors = []
  let l:json = join(a:lines, "\n")
  let l:resp = json_decode(l:json)

  let l:dummy_loc = {'line': 1, 'col': -1}

  for l:item in l:resp.value

    if l:item.type ==# 'warning'
      let l:type = 'W'
    else
      let l:type = 'E'
    endif

    let l:message = join(split(l:item.message, "\n"), " ")
    let l:message = substitute(l:message, ' \+', ' ', 'g')

    " Signature mismatch errors span too many lines so we limit it to report
    " only start loc.
    if l:message[0] =~ "^Signature mismatch"
      call add(l:errors, {
            \ "text": l:message,
            \ "type": l:type,
            \ "lnum": get(l:item, 'start', dummy_loc).line,
            \ "col": get(l:item, 'start', dummy_loc).col + 1,
            \ })
    else
      call add(l:errors, {
            \ "text": l:message,
            \ "type": l:type,
            \ "lnum": get(l:item, 'start', dummy_loc).line,
            \ "col": get(l:item, 'start', dummy_loc).col + 1,
            \ "end_lnum": get(l:item, 'end', dummy_loc).line,
            \ "end_col": get(l:item, 'end', dummy_loc).col,
            \ })
    endif

    for l:sub in l:item.sub
      call add(l:errors, {
            \ "text": l:sub.message,
            \ "type": l:type,
            \ "lnum": get(l:sub, 'start', dummy_loc).line,
            \ "col": get(l:sub, 'start', dummy_loc).col + 1,
            \ "end_lnum": get(l:sub, 'end', dummy_loc).line,
            \ "end_col": get(l:sub, 'end', dummy_loc).col,
            \ })
    endfor
  endfor

  return l:errors
endfunction

call ale#linter#Define('ocaml', {
  \   'name': 'ocaml-merlin',
  \   'executable': 'ocamlmerlin',
  \   'command_callback': function('s:command_callback'),
  \   'callback': function('s:callback'),
  \})

call ale#linter#Define('reason', {
  \   'name': 'reason-merlin',
  \   'executable': 'ocamlmerlin',
  \   'command_callback': function('s:command_callback'),
  \   'callback': function('s:callback'),
  \})
