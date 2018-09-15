# fzf-merlin

Show outline of OCaml/Reason code with merlin in fzf.

## Installation

If you use [vim-plug][]:

    Plug 'andreypopp/fzf-merlin'

Then add a mapping:

    au FileType ocaml nnoremap <C-n> <Esc>:FZFMerlinOutline<CR>
