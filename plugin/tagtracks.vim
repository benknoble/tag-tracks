if exists('g:loaded_tagtracks')
  finish
endif
let g:loaded_tagtracks = 1

command TagTracks if exists('w:tagtracks_info') |
      \ call tagtracks#StopTagTracks() |
      \ else |
      \ call tagtracks#StartTagTracks() |
      \ endif
