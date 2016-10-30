" ------------------------------------------------------------------
" FZF harness
" ------------------------------------------------------------------

let s:TYPE = {'dict': type({}), 'funcref': type(function('call'))}

function! s:get_color(attr, ...)
  for group in a:000
    let code = synIDattr(synIDtrans(hlID(group)), a:attr, 'cterm')
    if code =~ '^[0-9]\+$'
      return code
    endif
  endfor
  return ''
endfunction

function! s:defaults()
  let rules = copy(get(g:, 'fzf_colors', {}))
  let colors = join(map(items(filter(map(rules, 'call("s:get_color", v:val)'), '!empty(v:val)')), 'join(v:val, ":")'), ',')
  return empty(colors) ? '' : ('--color='.colors)
endfunction

function! s:wrap(name, opts, bang)
  " fzf#wrap does not append --expect if sink or sink* is found
  let opts = copy(a:opts)
  if get(opts, 'options', '') !~ '--expect' && has_key(opts, 'sink*')
    let Sink = remove(opts, 'sink*')
    let wrapped = fzf#wrap(a:name, opts, a:bang)
    let wrapped['sink*'] = Sink
  else
    let wrapped = fzf#wrap(a:name, opts, a:bang)
  endif
  return wrapped
endfunction

function! s:fzf(name, opts, extra)
  let [extra, bang] = [{}, 0]
  if len(a:extra) <= 1
    let first = get(a:extra, 0, 0)
    if type(first) == s:TYPE.dict
      let extra = first
    else
      let bang = first
    endif
  elseif len(a:extra) == 2
    let [extra, bang] = a:extra
  else
    throw 'invalid number of arguments'
  endif

  let eopts  = has_key(extra, 'options') ? remove(extra, 'options') : ''
  let merged = extend(copy(a:opts), extra)
  let merged.options = join(filter([s:defaults(), get(merged, 'options', ''), eopts], '!empty(v:val)'))
  return fzf#run(s:wrap(a:name, merged, bang))
endfunction

" ------------------------------------------------------------------
" MerlinOutline
" ------------------------------------------------------------------

python <<EOF
import vim
import merlin

fzf_merlin_outline_outlines = []
fzf_merlin_outline_send_cmd = lambda cmd: None

def fzf_merlin_outline_linearize(prefix, lst):
    for x in lst:
        name = "%s%s" % (prefix, x['name'])
        fzf_merlin_outline_outlines.append(
          {'name': name, 'pos': x['start'], 'kind': x['kind']})
        fzf_merlin_outline_linearize(name + ".", x['children'])

def fzf_merlin_outline_get_outlines():
    fzf_merlin_outline_outlines[:] = []
    fzf_merlin_outline_linearize("", fzf_merlin_outline_send_cmd("outline"))
    fzf_merlin_outline_outlines.sort(key = lambda x: len(x['name']))

def fzf_merlin_outline_init():
    fzf_merlin_outline_get_outlines()
    if len(fzf_merlin_outline_outlines) == 0:
        return
    longest = len(fzf_merlin_outline_outlines[-1]['name'])
    i = 0
    for x in fzf_merlin_outline_outlines:
        name = x['name'].replace("'", "''")
        vim.command("call add(l:modules, '%4d : %*s\t--\t%s')" %
                    (i, longest, name, x['kind']))
        i += 1

def fzf_merlin_outline_accept():
    idx = int(vim.eval("a:str").strip().split(' ')[0])
    try:
        x = fzf_merlin_outline_outlines[idx]
        l = x['pos']['line']
        c = x['pos']['col']
        vim.current.window.cursor = (l, c)
    except KeyError as e:
        print(str(e))

def fzf_merlin_outline_update_and_send(process, ctxt, cmd):
    ctxt['query'] = cmd
    return process.command(ctxt)

def fzf_merlin_outline_preinit():
    global fzf_merlin_outline_send_cmd
    merlin.sync()
    process = merlin.merlin_process()
    context = merlin.context("fake_query")
    fzf_merlin_outline_send_cmd = lambda *cmd: fzf_merlin_outline_update_and_send(process, context, cmd)
EOF

function! s:fzf_merlin_outline_accept(str)
  python fzf_merlin_outline_accept()
endfunction

function! fzf_merlin#merlin_outline(...)
  let l:modules = []
  python fzf_merlin_outline_preinit()
  python fzf_merlin_outline_init()
  return s:fzf('fzf_merlin_outline', {
  \ 'source':  l:modules,
  \ 'sink':   function('s:fzf_merlin_outline_accept'),
  \ 'options': '+m -x --tiebreak=index --header-lines=0 --ansi -d "\t" -n 2,1..2 --prompt="MerlinOutline> "',
  \}, a:000)
endfunction
