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
  ap = ones(n,n) ; use the full range of available apertures
  apmask = edgemask(ap,apinner)
  pap = ptr_new(ap)
  papinner = ptr_new(apinner)
  wind_prior = [0.0,0.0]
  openw,2,"output.dat"
  ;; iterate over our results
  for t=2,maxpass do begin
          pcurr = ptr_new(sig[*,*,t])
          pprev = ptr_new(sig[*,*,t-1])
          u_x = estimate_wind_GN(pcurr,pprev,n,pap,papinner,wind_prior,1)
          printf,2,u_x[0],u_x[1]
          wind_prior = u_x
  endfor


end


