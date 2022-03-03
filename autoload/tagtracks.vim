function tagtracks#FormatTagItem(index, item) abort
  const item_nr = a:index + 1
  const tagname = a:item.tagname
  const match = a:item.matchnr

  " getbufline() returns an empty List if the buffer passed is not loaded.
  " So, if the file corresponding to a TagStack entry is not open, then that
  " entry's FROM expression will not be displayed. This limitation is present
  " in the native `:tags' command as well.
  const text_list = getbufline(a:item.from[0], a:item.from[1])
  const text = empty(text_list) ? '' : text_list[0]

  const original_loc = printf('%s:%d %s',
        \ bufname(a:item.from[0]),
        \ a:item.from[1],
        \ text)
  return #{item: item_nr,
        \ tag: tagname,
        \ match: match,
        \ origin: original_loc}
endfunction

function tagtracks#FormatTagStack(tags) abort
  const lines = mapnew(a:tags.items, funcref('tagtracks#FormatTagItem'))

  const item_length = max([strlen('Item')] + mapnew(lines, {_, v -> strlen(v.item)})) + 1
  const tag_length = max([strlen('Tag')] + mapnew(lines, {_, v -> strlen(v.tag)})) + 1
  const match_length = max([strlen('Match')] + mapnew(lines, {_, v -> strlen(v.match)})) + 1

  return [  ' ' .
        \   'Item' . repeat(' ', item_length - strlen('Item')) .
        \   'Tag' . repeat(' ', tag_length - strlen('Tag')) .
        \   'Match' . repeat(' ', match_length - strlen('Match')) .
        \   'Origin']
        \ + mapnew(lines, {k, v -> printf('%s%s%s%s%s',
        \   (k is# a:tags.curidx - 1) ? '>' : ' ',
        \   v.item . repeat(' ', item_length - strlen(v.item)),
        \   v.tag . repeat(' ', tag_length - strlen(v.tag)),
        \   v.match . repeat(' ', match_length - strlen(v.match)),
        \   v.origin)})
        \ + [(a:tags.curidx > a:tags.length) ? '>' : '']
endfunction

function tagtracks#DisplayTagTracks(display_id, tagtracks_id)
  " bail if either window was closed
  const [display_tabnr, display_winnr] = win_id2tabwin(a:display_id)
  const [tagtracks_tabnr, tagtracks_winnr] = win_id2tabwin(a:tagtracks_id)
  if display_winnr is# 0 || tagtracks_winnr is# 0
    call tagtracks#StopTagTracks(a:display_id)
    return
  endif

  " don't update if tag tracks window is not current window
  if win_getid() != a:tagtracks_id
    return
  endif

  " get the tagstack
  const tagstack = gettagstack(a:tagtracks_id)
  " format it
  const tagsitems = tagtracks#FormatTagStack(tagstack)

  " get the buffer to update
  const display_bufnr = winbufnr(display_winnr)

  " delete old content, like %delete
  silent call deletebufline(display_bufnr, 1, '$')
  " add the new content, like put =tagsitems | 1delete
  call setbufline(display_bufnr, 1, tagsitems)
endfunction

function tagtracks#StartTagTracks()
  if exists('w:tagtracks_info')
    return
  endif
  " window id whose tagstack we want to display
  const tagtracks_id = win_getid()
  new
  setlocal nonumber
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nobuflisted
  file TagTracks
  " window id where display will live
  const display_id = win_getid()

  wincmd p
  let w:tagtracks_info = #{
        \ display_id: display_id,
        \ tagtracks_id: tagtracks_id
        \ }

  " update HUD when safe
  execute 'augroup tag_tracks'.display_id
    execute "autocmd SafeState * if mode() is# 'n' | call tagtracks#DisplayTagTracks(".display_id.", ".tagtracks_id.") | endif"
  augroup end
endfunction

" This function is called in only three cases. When the user:
"   1. closes the HUD.
"   2. closes the window being tracked.
"   3. issues the :TagTracks command in a window being tracked.
" For a given HUD, only one case ever occurs.
function tagtracks#StopTagTracks(display_id = v:none)
  const display_id = a:display_id ?? w:tagtracks_info.display_id

  " close window: this is conditional since the user could have manually
  " closed the HUD.
  const win_nr_to_close = win_id2win(display_id)
  if win_nr_to_close isnot# 0
    execute win_nr_to_close 'quit'
  endif

  " cleanup autocmd and variable: unlet of w:tagtracks_info is conditional
  " since the user could have manually closed the window being tracked.
  execute 'autocmd! tag_tracks'.display_id
  if exists('w:tagtracks_info')
    unlet w:tagtracks_info
  endif
endfunction
