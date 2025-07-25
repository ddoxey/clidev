" Load the “dark theme” settings
if filereadable(expand("~/.vim/theme.vim"))
  source ~/.vim/theme.vim
endif

" Preserve current indent on new lines
set autoindent

" Make backspaces behave sensibly in insert mode
set backspace=indent,eol,start

" Indentation settings
set tabstop=4               " A tab equals four spaces
set expandtab               " Convert tabs to spaces
set shiftwidth=4            " Indent/outdent by four spaces
set shiftround              " Round indent to nearest multiple of shiftwidth

" Enable search highlighting and show matches for % pairs (including < and >)
set hlsearch
set matchpairs+=<:>

set number  " line numbers and relative position of cursor

set title  " window title to the current file
set ruler

" Enable mouse support in insert and normal modes
set mouse=i

" Toggle paste mode with F12
set pastetoggle=<F12>

" ─────────────────────────────────────────────────────────────────────────
" Key Mappings
" ─────────────────────────────────────────────────────────────────────────

" Remap “#” in insert mode so that it’s easier to overwrite an existing “#”
inoremap # X^H#
inoremap # X<C-H>#

" Complete-opt configuration for popup menu
set completeopt=longest,menuone

" Enter key selects the highlighted completion menu item if pumvisible
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" Clever Tab: if at beginning of line (only whitespace), insert a literal Tab;
" otherwise trigger keyword completion (Ctrl-N)
function! CleverTab()
    if strpart(getline('.'), 0, col('.')-1) =~ '^\s*$'
        return "\<Tab>"
    else
        return "\<C-X>\<C-N>"
    endif
endfunction
inoremap <Tab> <C-R>=CleverTab()<CR>
inoremap <C-Tab> <C-X><C-U>

" ─────────────────────────────────────────────────────────────────────────
" Code Rework
" ─────────────────────────────────────────────────────────────────────────
function! RenameVariable()
  " Step 1: Save current cursor position
  let l:save_cursor = getpos('.')

  " Step 2: Get the word under the cursor
  let l:word = expand('<cword>')
  let l:original = l:word

  " Step 3: Check for m_ prefix
  let l:has_prefix = l:word =~? '^m_'

  " Step 4: Remove m_ prefix if present
  if l:has_prefix
    let l:word = substitute(l:word, '^m_', '', '')
  endif

  " Step 5: Convert camelCase to snake_case
  let l:snake = substitute(l:word, '\([a-z0-9]\)\([A-Z]\)', '\1_\L\2', 'g')
  let l:snake = tolower(l:snake)

  " Step 6: Add underscore suffix if m_ was removed
  if l:has_prefix
    let l:snake .= '_'
  endif

  " Step 7: Perform global substitution
  let l:escaped = escape(l:original, '\')
  execute '%s/\V\<'.l:escaped.'\>/' . l:snake . '/g'

  " Step 8: Restore cursor position
  call setpos('.', l:save_cursor)

  echo 'Renamed ' . l:original . ' → ' . l:snake . ' (global)'
endfunction

function! RenameMethod()
  " Save current cursor position
  let l:save_cursor = getpos('.')

  " Get the word under the cursor
  let l:word = expand('<cword>')
  let l:original = l:word

  " Split on underscore, capitalize each part, then join
  let l:parts = split(l:word, '_')
  let l:camel = join(map(l:parts, 'toupper(strpart(v:val, 0, 1)) . strpart(v:val, 1)'), '')

  " Perform global substitution
  let l:escaped = escape(l:original, '\')
  execute '%s/\V\<'.l:escaped.'\>/' . l:camel . '/g'

  " Restore cursor position
  call setpos('.', l:save_cursor)

  echo 'Renamed ' . l:original . ' → ' . l:camel . ' (global)'
endfunction

function! TidyWS()
    let filename = expand('%:t:r')
    let l:save = winsaveview()
    :retab
    silent! %s/\s\+$//g
    call winrestview(l:save)
    echo "Whitespace: tidied"
endfunction
nnoremap <F6> :call TidyWS()<CR>


