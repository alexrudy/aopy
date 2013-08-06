; 
;  subdivide_obs.pro
;  telem_analysis_13
;  
;  Created by Alexander Rudy on 2013-05-23.
;  Copyright 2013 Alexander Rudy. All rights reserved.
; 


pro subdivide_obs, obs, divisions=dflag
    
    process_raw_data, obs
    
    divisions = 2048
    if keyword_set(dflag) then divisions = dflag
    
    sig = readfits(obs.processed_path+'_fmodes.fits', h1) 
    dims = size(sig)
    len = dims[3]
    
    orig_processed_path = obs.processed_path
    
    num_intervals = floor(len/(divisions)) 
    start_indices = findgen(num_intervals)*divisions
    
    for i=0, num_intervals-1 do begin
        obs.processed_path = strcompress(orig_processed_path + "_" + string(round(i)),/remove_all)
        print,obs.processed_path
        starti = start_indices[i]
        endi = start_indices[i] + divisions - 1
        out_sig = sig[*,*,starti:endi,*]
        writefits, obs.processed_path+'_fmodes.fits', out_sig, h1
        ; process_phase, obs
        process_fmodes, obs
    end
    
    obs.processed_path = orig_processed_path
    
end
    
    