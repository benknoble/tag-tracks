if exists('g:loaded_tagtracks')
  finish
endif
let g:loaded_tagtracks = 1

function FormatTagItem(index, item) abort
  const item_nr = a:index + 1
  const tagname = a:item.tagname
  const match = a:item.matchnr
  const filename = bufname(a:item.bufnr)
  const original_loc = printf('%s:%d: %s',
        \ bufname(a:item.from[0]),
        \ a:item.from[1],
        \ getbufline(a:item.from[0], a:item.from[1])[0])
  return #{item: item_nr,
        \ tag: tagname,
        \ match: match,
        \ file: filename,
        \ origin: original_loc}
endfunction

function FormatTagStack(tags) abort
  const lines = mapnew(a:tags.items, funcref('FormatTagItem'))

  const item_length = max([strlen('Item')] + mapnew(lines, {_, v -> strlen(v.item)})) + 1
  const tag_length = max([strlen('Tag')] + mapnew(lines, {_, v -> strlen(v.tag)})) + 1
  const match_length = max([strlen('Match')] + mapnew(lines, {_, v -> strlen(v.match)})) + 1
  const file_length = max([strlen('File')] + mapnew(lines, {_, v -> strlen(v.file)})) + 1

  return [  ' ' .
        \   'Item' . repeat(' ', item_length - strlen('Item')) .
        \   'Tag' . repeat(' ', tag_length - strlen('Tag')) .
        \   'Match' . repeat(' ', match_length - strlen('Match')) .
        \   'File' . repeat(' ', file_length - strlen('File')) .
        \   'Origin']
        \ + mapnew(lines, {k, v -> printf('%s%s%s%s%s%s',
        \   (k is# a:tags.curidx - 1) ? '>' : ' ',
        \   v.item . repeat(' ', item_length - strlen(v.item)),
        \   v.tag . repeat(' ', tag_length - strlen(v.tag)),
        \   v.match . repeat(' ', match_length - strlen(v.match)),
        \   v.file . repeat(' ', file_length - strlen(v.file)),
        \   v.origin)})
        \ + [(a:tags.curidx > a:tags.length) ? '>' : '']
endfunction

function DisplayTagTracks(display_id, tagtracks_id, timer)
  if state() isnot# 'c'
    " wait until not busy…
    " 'c' for only executing this callback
    return
  endif
  const [display_tabnr, display_winnr] = win_id2tabwin(a:display_id)
  " don't update when not in the right tab
  " or when the display cannot be found
  if tabpagenr() isnot# display_tabnr || display_winnr is# 0
    return
  endif

  " get the tagstack
  const tagstack = gettagstack(a:tagtracks_id)
  " format it
  const tagsitems = FormatTagStack(tagstack)

  " get the buffer to update
  const display_bufnr = winbufnr(display_winnr)

  " delete old content, like %delete
  silent call deletebufline(display_bufnr, 1, '$')
  " add the new content, like put =tagsitems | 1delete
  call setbufline(display_bufnr, 1, tagsitems)
endfunction

function StartTagTracks()
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
  let w:tagtracks_info = #{
        \ timer: timer_start(500, function('DisplayTagTracks', [display_id, tagtracks_id]), #{repeat: -1}),
        \ display_id: display_id
        \ }
endfunction

function StopTagTracks()
  if exists('w:tagtracks_info')
    call timer_stop(w:tagtracks_info.timer)
    const win_nr_to_close = win_id2win(w:tagtracks_info.display_id)
    if win_nr_to_close isnot# 0
      execute win_nr_to_close 'close'
    endif
    unlet w:tagtracks_info
  endif
endfunction
