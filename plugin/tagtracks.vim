if exists('g:loaded_tagtracks')
  finish
endif
let g:loaded_tagtracks = 1

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
  const tagsitems = win_execute(a:tagtracks_id, 'tags')->split('\n')

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
