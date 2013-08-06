; 
;  hpf.pro
;  telem_analysis_13
;  
;  Created by Jaberwocky on 2013-05-03.
;  Copyright 2013 Jaberwocky. All rights reserved.
; 

function hpf, frequencies, cutoff, butterworth_filter=butterworth_filter
    dim = size(frequencies,/DIMENSIONS)
    C = 1.0
    if keyword_set(butterworth_filter) then begin
        filter = 1.0 - butterworth(dim[0],dim[1],cutoff=cutoff)
    endif else begin
        d = DIST( obs.n, obs.n )
        filter = fltarr(obs.n , obs.n ) + 1.0
        filter[where(d le cutoff)] = 0.0
    endelse
    rv = frequencies * filter
    return, rv
end