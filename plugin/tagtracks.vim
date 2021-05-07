if exists('g:loaded_tagstack')
  finish
endif
let g:loaded_tagstack = 1

function DisplayTagStack(display_id, tagstack_id, timer)
  const [display_tabnr, display_winnr] = win_id2tabwin(a:display_id)
  " don't update when not in the right tab
  if tabpagenr() isnot# display_tabnr
    return
  endif

  " get the tagstack
  const tagsitems = win_execute(a:tagstack_id, 'tags')->split('\n')

  " " if you prefer to have more control over the format, use the below code
  " const tagstack_winnr = win_id2win(a:tagstack_id)
  " const tagstack = gettagstack(tagstack)
  " const tagsindex = tagstack.curidx
  " const tagsitems = tagstack.items
  " " format it…

  " get the buffer to update
  const display_bufnr = winbufnr(display_winnr)

  " delete old content, like %delete
  silent call deletebufline(display_bufnr, 1, "$")
  " add the new content, like put =tagsitems | 1delete
  call appendbufline(display_bufnr, 0, tagsitems)
endfunction

function StartTagStack()
  if exists('w:stack_info')
    return
  endif
  " window id whose tagstack we want to display
  const tagstack_id = win_getid()
  new
  setlocal buftype=nofile
  setlocal bufhidden=hide
  setlocal noswapfile
  setlocal nobuflisted
  " window id where display will live
  const display_id = win_getid()

  let w:stack_info = #{
        \ timer: timer_start(500, function('DisplayTagStack', [display_id, tagstack_id]), #{repeat: -1}),
        \ display_id: display_id
        \ }
  wincmd p
endfunction

function StopTagStack()
  if exists('w:stack_info')
    call timer_stop(w:stack_info.timer)
    execute win_id2win(w:stack_info.display_id) 'close'
    unlet w:stack_info
  endif
endfunction
