if exists('g:jumptree_loaded')
  finish
endif

let g:jumptree_loaded = 1


function s:sync()
  " yeet the cursor to wherever, so Neovim doesn't sneakily remove the last jumplist
  " entry when querying the jumplist. see src/nvim/mark.c:1196-1207, commit 5eca52aa
  let l:cursor_save = getcurpos('.')
  call setpos('.', [0, line('$') - 1, 0, 0])

  let l:loc = getjumplist()[0][-1]
  let l:loc = [l:loc.bufnr, l:loc.lnum, l:loc.col + 1, l:loc.coladd]
  " if a new entry has been pushed onto the jumplist, mark the cursor as floating
  if empty(w:jumptree) || l:loc != w:jumptree[-1].loc
    let w:jumptree_float = 1
    " if the new entry's location is different from the current location, record it
    if empty(w:jumptree) || l:loc != w:jumptree[w:jumptree_idx].loc
      call add(w:jumptree, {'loc': l:loc})
      let w:jumptree[len(w:jumptree) - 1].up = w:jumptree_idx
      let w:jumptree[w:jumptree_idx].down = len(w:jumptree) - 1
      let w:jumptree_idx = len(w:jumptree) - 1
    endif
  endif

  call setpos('.', l:cursor_save)
endfunction

function s:do(move)
  " if this is the first <c-o>/<c-i>/g<c-o>/g<c-i> after a jump, commit the current
  " cursor position to the jumplist. same idea as src/nvim/mark.c:300, commit 9884ba70
  if w:jumptree_float
    normal! m'
    call s:sync()
    let w:jumptree_float = 0
  endif

  for _ in range(v:count1) | call a:move() | endfor

  let l:cur = w:jumptree[w:jumptree_idx]
  execute 'keepjumps' 'buffer' l:cur.loc[0]
  call setpos('.', l:cur.loc)
endfunction

function s:up()
  let l:cur = w:jumptree[w:jumptree_idx]
  if w:jumptree_idx > 0 && has_key(l:cur, 'up')
    let w:jumptree[l:cur.up].down = w:jumptree_idx
    let w:jumptree_idx = l:cur.up
  endif
endfunction

function s:down()
  let l:cur = w:jumptree[w:jumptree_idx]
  if has_key(l:cur, 'down')
    let w:jumptree_idx = l:cur.down
  endif
endfunction

function s:older()
  if w:jumptree_idx > 0
    let w:jumptree_idx -= 1
  endif
endfunction

function s:newer()
  if w:jumptree_idx < len(w:jumptree) - 1
    let w:jumptree_idx += 1
  endif
endfunction


let w:jumptree = [] | let w:jumptree_idx = 0 | let w:jumptree_float = 0
autocmd WinNew * let w:jumptree = [] | let w:jumptree_idx = 0 | let w:jumptree_float = 0
autocmd BufNew,BufEnter,CursorMoved * call s:sync()

nnoremap <Plug>JumptreeUp    <cmd>call <sid>do(function('<sid>up'))<cr>
nnoremap <Plug>JumptreeDown  <cmd>call <sid>do(function('<sid>down'))<cr>
nnoremap <Plug>JumptreeOlder <cmd>call <sid>do(function('<sid>older'))<cr>
nnoremap <Plug>JumptreeNewer <cmd>call <sid>do(function('<sid>newer'))<cr>

if !exists('g:jumptree_no_mappings') || !g:jumptree_no_mappings
  nnoremap <c-o>  <Plug>JumptreeUp
  nnoremap <c-i>  <Plug>JumptreeDown
  nnoremap g<c-o> <Plug>JumptreeOlder
  nnoremap g<c-i> <Plug>JumptreeNewer
endif
