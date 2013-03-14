; 
;  make_case_sim.pro
;  telem_analysis_13
;  
;  Created by Jaberwocky on 2013-03-11.
;  Copyright 2013 Jaberwocky. All rights reserved.
; 


pro make_case_sim, obs
    
;    
    forward_function blowingScreen_init,blowingScreen_get
    
    
    params = { $
        r0: 0.10, $
        windx: 25, $
        dp: 1 $
    }
    
    wind = params.windx / obs.d / obs.rate
    m = obs.n + wind*obs.len*params.dp
    screen = blowingScreen_init(obs.n,m,params.r0,obs.d/params.dp,seed=obs.seed)
    screen2 = blowingScreen_init(obs.n,2*obs.n,params.r0,obs.d/params.dp,seed=obs.seed)
    phi_fine_t = fltarr(obs.n,obs.n,obs.len)
    phi_fine = fltarr(obs.n,obs.n)
    for t=0,obs.len-1 do begin
        wait,.001
        phi_fine = blowingScreen_get(screen,wind*t*params.dp) * obs.pingrid
        phi_static = blowingScreen_get(screen2,0) * obs.pingrid
        phi_fine_t[*,*,t] = phi_fine + phi_static
    endfor
    
    ; phi_coarse_t = rebin(phi_fine_t,n,n,obs.len+1,/sample)
    
    mkhdr, h1, phi_fine_t
    fxaddpar, h1, 'TSCOPE', obs.telescope, 'Telescope of observation'
    fxaddpar, h1, 'RAWPATH', obs.raw_path, 'File path and name of raw telemetry archive'
    fxaddpar, h1, 'PROCPATH', obs.processed_path, 'File path and name of the processes data'
    fxaddpar, h1, 'DTYPE', 'Spatial signals', 'In spatial domain'
    writefits, obs.raw_path, phi_fine_t, h1
    ; mkhdr, h2, phi_coarse_t
    
end