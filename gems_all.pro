; 
;  gems_all.pro
;  telem_analysis_13
;  
;  Created by Alexander Rudy on 2013-05-09.
;  Copyright 2013 Alexander Rudy. All rights reserved.
; 
pro gems_all
    
    cases = [10,11,12,15,16,17,18,19,20,21,22,25,26,27,28,29,115,116,117,118,119,125,126,127,128,129]
    
    for i=0, n_elements(cases)-1 do begin
        obs = get_case_gems(cases[i])
        process_raw_data,obs,ngs=2,cut=3
        process_phase,obs
        process_fmodes,obs
    endfor
    
end