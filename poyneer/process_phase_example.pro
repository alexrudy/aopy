pro process_fmodes, ca 

  ;; ca is the structure of the observation

  ;; read in the Fmodes
  sig = readfits(ca.processed_path+'_fmodes.fits', h1) 

  dims = size(sig)
  n = dims[1]
  len = dims[3]


  ;;;; now do what you like here!!!


end


