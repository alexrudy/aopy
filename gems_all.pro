; 
;  gems_all.pro
;  telem_analysis_13
;  
;  Created by Alexander Rudy on 2013-05-09.
;  Copyright 2013 Alexander Rudy. All rights reserved.
; 
pro gems_all
    
    cases = [10,11,12,15,16,17,18,19,20,21,22,25,26,27,28,29,115,116,117,118,119,125,126,127,128,129, 135,136,137,138,139,145,146,147,148,149,155,156,157,158,159,205,206,207,208,209,215,216,217,218,219,225,226,227,228,229]
    cases = [235, 236, 237, 238, 239]
    for i=0, n_elements(cases)-1 do begin
        obs = get_case_gems(cases[i])
        process_raw_data,obs,ngs=3,cut=1.5
        ; process_phase,obs
        process_fmodes,obs, /relaxalpha, /relaxrms
    endfor
    
end