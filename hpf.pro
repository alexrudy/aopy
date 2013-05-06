; 
;  hpf.pro
;  telem_analysis_13
;  
;  Created by Jaberwocky on 2013-05-03.
;  Copyright 2013 Jaberwocky. All rights reserved.
; 

function hpf, frequencies, cutoff
    dim = size(frequencies,/DIMENSIONS)
    C = 1.0
    filter = 1.0 / (1.0d + C*(cutoff/DIST(dim[0],dim[1]))^2.0)
    rv = frequencies * cutoff
    return, rv
end