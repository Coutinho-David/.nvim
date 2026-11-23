nnoremap  <C-k>  :cnext<CR>zz
nnoremap  <C-j>  :cprev<CR>zz
nnoremap  <leader>k :lnext<CR>zz
nnoremap  <leader>j :lprev<CR>zz
nnoremap  <leader>q :call ToggleQFList(1)<CR>
nnoremap  <C-q> :call ToggleQFList(0)<CR>

" Toggle to quickfix
let g:my_qf_l = 0
let g:my_qf_g = 0

fun! ToggleQFList(global)
  if a:global
    if g:my_qf_g == 1
      let g:my_qf_g = 0
      cclose
    else
      let g:my_qf_g = 1
      copen
    end
  else
    if g:my_qf_l == 1
      let g:my_qf_l = 0
      lclose
    else
      let g:my_qf_l = 1
      lopen
    end
  endif
endfun
