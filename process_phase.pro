@edgemask

pro process_phase, obs 
        
  ;; obs is the structure of the observation
        
  ;; read in the phase
  sig = readfits(obs.processed_path+'_phase.fits', h1) 
  dims = size(sig)
  n = dims[1]
  len = dims[3]
  maxpass = len-1
  
  ;; REDUCTION PARAMETERS
  methods = ['GN','RT','2D','XY']
  n_methods = n_elements(methods)
  
  ;; make an aperture mask
  ap = sig(*,*,0) ne 0 ; Develop the aperture mask.
  apmask = edgemask(ap,apinner)
  pap = ptr_new(ap)
  papinner = ptr_new(apinner)
  
  ;; Make wind priors
  wind_prior = fltarr(n_methods,2)
  u_x = fltarr(2)
  wind = fltarr(n_methods,3,maxpass)
  
  ;; Make Search Size
  
  ss = { xy: 1e-4, twod: 1e-4}
  
  maxit = { gn:1, rt:1, xy: 1, twod: 1 }
  
  
  ;; Iterator Variables
  alert_step = floor(maxpass / 10)
  
  message,"Starting Wind Prediction",/info
  
  ;; iterate over our results
  for t=1,maxpass do begin
          pcurr = ptr_new(sig[*,*,t])
          pprev = ptr_new(sig[*,*,t-1])
          
          ;; Gauss-Newton
          method = 0
          method_name = methods(method)
          u_x = estimate_wind_GN(pcurr,pprev,n,pap,papinner,wind_prior[method,*],maxit.gn)
          wind[method,0:1,t-1] = u_x * obs.d * obs.rate
          wind[method,2,t-1] = t / obs.rate
          wind_prior[method,0:1] = u_x

          
          ;; RT
          method = 1
          method_name = methods(method)
          u_x = estimate_wind_rt(pcurr,pprev,wind_prior[method,*],maxit.rt)
          wind[method,0:1,t-1] = u_x * obs.d * obs.rate
          wind[method,2,t-1] = t / obs.rate
          wind_prior[method,0:1] = u_x
          
          ;; 2D
          method = 2
          method_name = methods(method)
          u_x = estimate_wind_2da(pcurr,pprev,wind_prior[method,*],ss.twod,n,papinner,maxit.twod)
          wind[method,0:1,t-1] = u_x * obs.d * obs.rate
          wind[method,2,t-1] = t / obs.rate
          wind_prior[method,0:1] = u_x
          
          ;; XY
          method = 3
          method_name = methods(method)
          if (t mod 2) eq 0 then begin
                  u_x = estimate_wind_2d_xa(pcurr,pprev,wind_prior[method,*],ss.xy,n,papinner,maxit.xy)
          endif else begin
                  u_x = estimate_wind_2d_ya(pcurr,pprev,wind_prior[method,*],ss.xy,n,papinner,maxit.xy)
          endelse
          wind[method,0:1,t-1] = u_x * obs.d * obs.rate
          wind[method,2,t-1] = t / obs.rate
          wind_prior[method,0:1] = u_x

          
          ptr_free,pcurr
          ptr_free,pprev
          
          if (t mod alert_step) eq 0 then begin
                  print, format='($,A,"% ")',strtrim(ceil(100.0 * (float(t) / float(maxpass))),2)
          endif

  endfor
   
  ;; Save data to a FITS file
  writefits,obs.processed_path+'_wind.fits',wind,h1
  
  ;; Free pointers
  ptr_free,pap
  ptr_free,papinner

end


