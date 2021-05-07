if exists('g:loaded_tagtracks')
  finish
endif
let g:loaded_tagtracks = 1

function DisplayTagTracks(display_id, tagtracks_id, timer)
  const [display_tabnr, display_winnr] = win_id2tabwin(a:display_id)
  " don't update when not in the right tab
  if tabpagenr() isnot# display_tabnr
    return
  endif

  " get the tagstack
  const tagsitems = win_execute(a:tagtracks_id, 'tags')->split('\n')

  " get the buffer to update
  const display_bufnr = winbufnr(display_winnr)

  " delete old content, like %delete
  silent call deletebufline(display_bufnr, 1, "$")
  " add the new content, like put =tagsitems | 1delete
  call appendbufline(display_bufnr, 0, tagsitems)
endfunction

function StartTagTracks()
  if exists('w:tagtracks_info')
    return
  endif
  " window id whose tagstack we want to display
  const tagtracks_id = win_getid()
  new
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nobuflisted
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
    call timer_stop(w:tracks_info.timer)
    execute win_id2win(w:tracks_info.display_id) 'close'
    unlet w:tracks_info
  endif
endfunction
