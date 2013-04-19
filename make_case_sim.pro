; 
;  make_case_sim.pro
;  telem_analysis_13
;  
;  Created by Jaberwocky on 2013-03-11.
;  Copyright 2013 Jaberwocky. All rights reserved.
; 


pro make_case_sim, obs
    
;    
    blowingscreen
    
    
    params = { $
        r0: 0.10, $
        windx: [25,50], $
        dp: 1, $
        layers: 2 $
    }
    

    screens = LIST()
    for l=0,params.layers-1 do begin
        wind = params.windx[l] / obs.d / obs.rate
        m = obs.n + wind*obs.len*params.dp
        screen = blowingScreen_init(obs.n,m,params.r0,obs.d/params.dp,seed=obs.seed + l)
        screens.add,screen
    endfor
    phi_fine_t = fltarr(obs.n,obs.n,obs.len)
    phi_fine_l = fltarr(obs.n,obs.n,params.layers)
    phi_fine = fltarr(obs.n,obs.n)
    for t=0,obs.len-1 do begin
        wait,.0001
        for l=0,params.layers-1 do begin
            phi_fine_l[*,*,l] = rotate(blowingScreen_get(screens[l],wind*t*params.dp) * obs.pingrid,l)
        endfor
        if l gt 1 then begin
            phi_fine[*,*] = total(phi_fine_l,3)
        endif else begin
            phi_fine = phi_fine_l
        endelse
        phi_nop = depiston(phi_fine,obs.pingrid)  * obs.pingrid
        phi_nop_nott = detilt(phi_fine,obs.pingrid)  * obs.pingrid
        phi_fine_t[*,*,t] = phi_nop_nott
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