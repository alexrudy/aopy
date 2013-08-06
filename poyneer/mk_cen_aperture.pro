; 
;  mk_cen_aperture.pro
;  telem_analysis_13
;  
;  Created by Jaberwocky on 2013-05-09.
;  Copyright 2013 Jaberwocky. All rights reserved.
; 

function mk_cen_aperture, N, R, ox, oy
    xind = rebin(findgen(n) - ox, n, n)
    yind = transpose(rebin(findgen(n) - oy, n, n))
    rind = sqrt(xind^2 + yind^2)
    pin = rind LE r
    return,pin
end