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

  for l:item in l:resp.value

    if l:item.type ==# 'warning'
      let l:type = 'W'
    else
      let l:type = 'E'
    endif

    call add(l:errors, {
          \ "text": l:item.message,
          \ "type": l:type,
          \ "lnum": l:item.start.line,
          \ "col": l:item.start.col + 1,
          \ "end_lnum": l:item.end.line,
          \ "end_col": l:item.end.col,
          \ })

    for l:sub in l:item.sub
      call add(l:errors, {
            \ "text": l:sub.message,
            \ "type": l:type,
            \ "lnum": l:sub.start.line,
            \ "col": l:sub.start.col + 1,
            \ "end_lnum": l:sub.end.line,
            \ "end_col": l:sub.end.col,
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
