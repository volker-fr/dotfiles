"
" Plugins
"
call plug#begin('~/.vim/plugged')
Plug 'vimwiki/vimwiki'
Plug 'altercation/vim-colors-solarized'
Plug 'Yggdroot/indentLine'
Plug 'nathanaelkane/vim-indent-guides' " due of json issues with Yggdroot/indentLine
Plug 'vim-syntastic/syntastic'
call plug#end()

"
" General settings
"
set undofile " create <FILENAME>.un~ to undo steps even when file was closed
set undodir=$HOME/.cache/vim/ " where to store the undofile

set expandtab " tab becomes whitespace


"
" Keyboard shortcuts
"
let mapleader='\'
nmap <Leader>p :set paste!<CR>


"
" presentation, highlighting etc
"
syntax enable
set background=dark
colorscheme solarized

highlight WhitespaceEOL ctermbg=red guibg=red
match WhitespaceEOL /\s\+$/

set list listchars=tab:⇥⇥   " show tab as special char

" Remember where we left off last time
" http://vim.wikia.com/wiki/Make_views_automatic
autocmd Filetype !json BufWinLeave *.* mkview
autocmd Filetype !json BufWinEnter *.* silent loadview

" Indent plugin https://github.com/Yggdroot/indentLine/issues/172
autocmd Filetype json set ts=4 sw=4
"autocmd Filetype json %!python -m json.tool
autocmd Filetype json let g:indentLine_setConceal = 0
autocmd Filetype json :IndentGuidesEnable



"
" vimwiki
"
let wiki_personal = { 'path':  '~/repos/vimwiki/personal/',
                    \ 'diary_index': 'Home',
                    \ 'index': 'Home',
                    \ 'syntax': 'markdown',
                    \ 'ext': '.md',
                    \ 'diary_link_fmt': '%Y-%m-01'}
" compile list
let g:vimwiki_list = [wiki_personal]
if has("autocmd")
  autocmd BufNewFile */diary/????-??-??.md call s:new_vimwiki_diary_template()
  " git pull and commit/push
  autocmd BufRead *.md call system('cd '.expand("%:h").' && [ -f .autogit ] && git pull --no-edit')
  autocmd BufWritePost *.md call system('cd '.expand("%:h").' && [ -f .autogit ] && git add "'.expand("%").'" && git commit -m "$(date) update" && git push')
endif

function s:new_vimwiki_diary_template()
  " diary tempalte + execute substitution in it
  read ~/repos/vimwiki/templates/diary.tpl | execute "normal ggdd"
  " execute VIM_EVAL tag
  %substitute#\[:VIM_EVAL:\]\(.\{-\}\)\[:END_EVAL:\]#\=eval(submatch(1))#ge
  silent %substitute#%monthly%#
  execute "g/^%/d"
endfunction
