function tagtracks#FormatTagItem(index, item) abort
  const item_nr = a:index + 1
  const tagname = a:item.tagname
  const match = a:item.matchnr
  const original_loc = printf('%s:%d: %s',
        \ bufname(a:item.from[0]),
        \ a:item.from[1],
        \ getbufline(a:item.from[0], a:item.from[1])[0])
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
  " delete SafeState autocommand
  silent! execute 'autocmd! tag_tracks'.a:tagtracks_id 'SafeState *'

  const [display_tabnr, display_winnr] = win_id2tabwin(a:display_id)
  " don't update when not in the right tab
  " or when the display cannot be found
  if tabpagenr() isnot# display_tabnr || display_winnr is# 0
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

function tagtracks#DisplayTagTracksSafely(display_id, tagtracks_id, timer) abort
  execute 'augroup tag_tracks'.a:tagtracks_id
    autocmd!
    execute "autocmd SafeState * if mode() is# 'n' | call tagtracks#DisplayTagTracks(".a:display_id.", ".a:tagtracks_id.") | endif"
  augroup end
endfunction

function tagtracks#StartTagTracks()
  if exists('w:tagtracks_info')
    return
  endif
  " window id whose tagstack we want to display
  const tagtracks_id = win_getid()
  new
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nobuflisted
  file TagTracks
  " window id where display will live
  const display_id = win_getid()

  wincmd p
  " trigger first display manually so we don't wait for too long
  call tagtracks#DisplayTagTracks(display_id, tagtracks_id)
  let w:tagtracks_info = #{
        \ timer: timer_start(500, function('tagtracks#DisplayTagTracksSafely', [display_id, tagtracks_id]), #{repeat: -1}),
        \ display_id: display_id,
        \ tagtracks_id: tagtracks_id
        \ }
endfunction

function tagtracks#StopTagTracks()
  if exists('w:tagtracks_info')
    call timer_stop(w:tagtracks_info.timer)
    const win_nr_to_close = win_id2win(w:tagtracks_info.display_id)
    if win_nr_to_close isnot# 0
      execute win_nr_to_close 'close'
    endif
    silent! execute 'autocmd! tag_tracks'.w:tagtracks_info.tagtracks_id 'SafeState *'
    unlet w:tagtracks_info
  endif
endfunction
