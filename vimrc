"
" Plugins
"
call plug#begin('~/.vim/plugged')
Plug 'vimwiki/vimwiki'
Plug 'altercation/vim-colors-solarized'
Plug 'Yggdroot/indentLine'
Plug 'nathanaelkane/vim-indent-guides' " due of json issues with indentLine
Plug 'vim-syntastic/syntastic' " testing
Plug 'airblade/vim-gitgutter' " show git changes on the left side of each line
Plug 'tpope/vim-fugitive' " show git branch in status line & :Gblame
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-endwise' " auto end, fi
Plug 'vim-scripts/nginx.vim' " vim syntax hilightning
Plug 'ctrlpvim/ctrlp.vim'
Plug 'pearofducks/ansible-vim'
call plug#end()

"
" General settings
"
set undodir=$HOME/.vim/cache " where to store the undofile
set undofile            " create files to undo even after vim is closed

" Tab settings
set expandtab           " tab becomes whitespace
set tabstop=4           " one expanded tab is 4 chars long
set shiftwidth=4        " how long should a auto ident be shifted in?

" search settings
set hlsearch            " highlight the word we search for
set incsearch           " start searching & hilight before return is pressed
set ignorecase          " Don't care about case when searching

" misc
set wildmenu            " show more options on :command<tab> tabcompletion
set colorcolumn=80      " show 80 character limit
set title               " set title/also show filename in iterm etc.
set showcmd             " show command input as I type (right bottom)
set cursorline          " show the line we are in
"set belloff=all        " disable all error bells. Seem to required > v6
set noerrorbells visualbell " old vim
if &diff == 'nodiff'    " don't run it when using vim diff, else vim crashes
    set shellcmdflag=-ic    " run interactive shell to make functions available
endif
" To download missing languages: set spelllang=de
set spelllang=en,de
set spell

"
" Status line
"
set laststatus=2 " status bar. show 2=always, 1=only when more as one window
" If airline isn't used, the following statusbar will be shown
set statusline=
set statusline+=[%n] " vim buffer number
set statusline+=[%<%F] " filename full path
set statusline+=%h%w%m%r " Help, preview window, modified & readonly flag
set statusline+=\%{exists('g:loaded_fugitive')?fugitive#statusline():''}
set statusline+=%#error# " highlight with error color setting
set statusline+=%{&paste?'[paste]':''} " show "set paste" mode
set statusline+=%* " reset color setting
set statusline+=%= " separate statusline in left and right
set statusline+=[%{&ff}] " file format
set statusline+=[%{strlen(&fenc)?&fenc:&enc}] " file encoding
set statusline+=%y " file type
set statusline+=[%P\ %l/%L\:\ %v\] " location in file


"
" Keyboard shortcuts
"
let mapleader='\'
nmap <Leader>p :set paste!<CR>
" enable the numbering
nmap <Leader>n :setlocal relativenumber!<CR>
" copy to clipboard
nmap <Leader>c :%w !pbcopy<CR>

" jump between syntastic errors
nmap ]n :lnext<CR>
nmap [n :lprevious<CR>

" change tabs
map <c-l> :tabn<CR>
map <c-j> :tabp<CR>

"
" presentation, highlighting etc
"
syntax enable
set background=dark
colorscheme solarized
"
" background git-gutter sidebar
highlight SignColumn ctermbg=0

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

" Golang: don't show the tab symbol and gofmt will format in tab anyway
autocmd Filetype go setlocal noexpandtab
autocmd Filetype go setlocal nolist

autocmd BufReadPost Jenkinsfile set syntax=groovy
autocmd BufReadPost Jenkinsfile set filetype=groovy

autocmd BufRead,BufNewFile */nginx.conf set filetype=nginx
autocmd BufRead,BufNewFile */nginx/*/* set filetype=nginx

autocmd BufRead,BufNewFile */playbooks/*.yml set filetype=ansible

"
" airline
"
let g:airline_powerline_fonts = 1   " use UFT-8 symbols; requires patched font

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
  " diary template + execute substitution in it
  read ~/repos/vimwiki/templates/diary.tpl | execute "normal ggdd"
  " execute VIM_EVAL tag
  %substitute#\[:VIM_EVAL:\]\(.\{-\}\)\[:END_EVAL:\]#\=eval(submatch(1))#ge
  silent %substitute#%monthly%#
  execute "g/^%/d"
endfunction

" Syntastic
let g:syntastic_python_flake8_args='--ignore=E501'
" Allways populate :Errors right away. This will allow jumping between errors
" with :lnext & :lprev
let g:syntastic_always_populate_loc_list=1
" check when opening a new file
let g:syntastic_check_on_open = 1

"
" golang
"
let g:syntastic_go_checkers = ['go', 'golint']
" The go plugin take a lot of resources. Hilightning slows scrolling down
" I only need the formating option
let g:gofmt_command = "goimports"
" copied from https://github.com/mrtazz/vimfiles/blob/master/vimrc
function! s:GoFormat()
    let view = winsaveview()
    silent execute "%!" . g:gofmt_command
    if v:shell_error
        let errors = []
        for line in getline(1, line('$'))
            let tokens = matchlist(line, '^\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)')
            if !empty(tokens)
                call add(errors, {"filename": @%,
                                 \"lnum":     tokens[2],
                                 \"col":      tokens[3],
                                 \"text":     tokens[4]})
            endif
        endfor
        if empty(errors)
            % | " Couldn't detect gofmt error format, output errors
        endif
        undo
        if !empty(errors)
            call setqflist(errors, 'r')
        endif
        echohl Error | echomsg "Gofmt returned error" | echohl None
    endif
    call winrestview(view)
endfunction
command! Fmt call s:GoFormat()

autocmd FileType go autocmd BufWritePre <buffer> Fmt

" Open new files in a new tab in CtrlP
let g:ctrlp_prompt_mappings = {
    \ 'AcceptSelection("e")': ['<c-t>'],
    \ 'AcceptSelection("t")': ['<cr>', '<2-LeftMouse>'],
    \ }
