; 
;  save_wind_map.pro
;  WindPrediction
;  
;  Created by Jaberwocky on 2013-07-22.
;  Copyright 2013 Jaberwocky. All rights reserved.
; 


;
; Save the wind data to a FITS file in a standard, readable format.
;
;

pro save_wind_map, wind_data, obs
    
    mkhdr, h1, wind_data.metric, /extend
    fxaddpar, h1, 'TSCOPE', obs.telescope, 'Telescope of observation'
    fxaddpar, h1, 'RAWPATH', obs.raw_path, 'File path and name of raw telemetry archive'
    fxaddpar, h1, 'PROCPATH', obs.processed_path, 'File path and name of the processes data'
    fxaddpar, h1, 'DTYPE', 'Wind Map', 'In spatial domain'
    writefits,obs.processed_path+'_fwmap.fits',wind_data.metric,h1
    mkhdr, h2, wind_data.vx, /image
    fxaddpar, h2, 'DTYPE', 'Wind vx scale', 'in m/s'
    writefits,obs.processed_path+'_fwmap.fits',wind_data.vx,h2,/append
    mkhdr, h3, wind_data.vy, /image
    fxaddpar, h3, 'DTYPE', 'Wind vy scale', 'in m/s'
    writefits,obs.processed_path+'_fwmap.fits',wind_data.vy,h3,/append
    mkhdr, h4, wind_data.layer_list, /image
    fxaddpar, h4, 'DTYPE', 'Wind Layer List', ''
    writefits,obs.processed_path+'_fwmap.fits',wind_data.layer_list,h4,/append

    print,"Done Processing FModes"
    
end