if exists('g:loaded_jumptree')
  finish
endif
let g:loaded_jumptree = 1

let s:cpo_save = &cpo
set cpo&vim

function s:getjumplist(...)
  " make sure the cursor is not on the same line as the last jumplist entry,
  " because otherwise Neovim permanently deletes that entry when viewing the
  " jumplist. see src/nvim/mark.c:1196-1207, commit 5eca52aa
  let curpos = getcurpos()
  call setpos('.', [0, line("''") % line('$') + 1, 0, 0])
  let jumplist = call('getjumplist', a:000)
  call setpos('.', curpos)
  return jumplist
endfunction

function s:initvars()
  " creating windown variables using `autocmd WinNew *` is just not reliable
  " (case in point, `vimdiff`), so instead we defensively call this function
  " before using any window variables to create them if they haven't yet been
  if !exists('w:jumptree') || empty(w:jumptree)
    let [w:jumptree_idx, w:jumptree_flt] = [0, 0]
    let w:jumptree = [{'loc': getpos('.')}]
    let w:jumptree[0].loc[0] = bufnr()
    return
  endif
endfunction

function s:sync()
  call s:initvars()

  let loc = s:getjumplist()[0][-1]
  let loc = [loc.bufnr, loc.lnum, loc.col + 1, loc.coladd]
  if loc != w:jumptree[-1].loc " jumplist has a new entry
    let w:jumptree_flt = 1 " mark cursor as floating
    if loc != w:jumptree[w:jumptree_idx].loc " deduplicate
      call add(w:jumptree, {'loc': loc, 'up': w:jumptree_idx})
      let w:jumptree_idx = len(w:jumptree) - 1
    endif
  endif
endfunction

function s:do(move)
  call s:initvars()

  " if cursor is floating (as in, this is the first <c-o>/<c-i>/g<c-o>/g<c-i>
  " after a jump), commit the current cursor position to the jumptree. same
  " idea as src/nvim/mark.c:300, commit 9884ba70
  if w:jumptree_flt
    normal! m'
    call s:sync()
    let w:jumptree_flt = 0
  endif

  for _ in range(v:count1) | call a:move() | endfor

  let cur = w:jumptree[w:jumptree_idx]
  execute 'keepjumps' 'buffer' cur.loc[0]
  call setpos('.', cur.loc)
endfunction

function s:up()
  let cur = w:jumptree[w:jumptree_idx]
  if has_key(cur, 'up')
    let w:jumptree[cur.up].down = w:jumptree_idx
    let w:jumptree_idx = cur.up
  endif
endfunction

function s:down()
  let cur = w:jumptree[w:jumptree_idx]
  if has_key(cur, 'down')
    let w:jumptree_idx = cur.down
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

autocmd BufEnter,CursorMoved * call s:sync()

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

let &cpo = s:cpo_save
unlet s:cpo_save
