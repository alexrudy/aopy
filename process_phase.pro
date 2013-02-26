@edgemask

pro process_phase, obs 

  ;; obs is the structure of the observation

  ;; read in the phase
  sig = readfits(obs.processed_path+'_phase.fits', h1) 
  dims = size(sig)
  n = dims[1]
  len = dims[3]
  maxpass = len-1
  ; maxpass = 2
  ;;;; now do what you like here!!!
  
  ;; make an aperture mask
  ap = sig(*,*,0) ne 0 ; Develop the aperture mask.
  apmask = edgemask(ap,apinner)
  pap = ptr_new(ap)
  papinner = ptr_new(apinner)
  wind_prior_GN = [0.0,0.0]
  wind_GN = fltarr(3,maxpass)
  wind_2D = fltarr(3,maxpass)
  
  ;; iterate over our results
  for t=2,maxpass do begin
          pcurr = ptr_new(sig[*,*,t])
          pprev = ptr_new(sig[*,*,t-1])
          u_x = estimate_wind_GN(pcurr,pprev,n,pap,papinner,wind_prior_GN,1)
          ptr_free,pcurr
          ptr_free,pprev
          wind_GN[0:1,t-2] = u_x
          wind_GN[2] = t / obs.rate
          wind_prior_GN = u_x
  endfor
  
  wind_GN = wind_GN * obs.d * obs.rate
  
  
  writefits,'processed_GN_wind.fits',wind_GN,h1


end


