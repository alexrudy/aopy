;; Written by Lisa Poyneer

;;;; a simple atm/noise splitter. Fits a flat noise floor to the
;;; high temporal freq PSD and subtracts that from the rest 
;;; to get the atmosphere.

pro split_psds_into_atm_and_noise, modal_psds, atm_psds, noise_psds

  option = 1 ;;; fancier

  dims = size(modal_psds)
  n = dims[1]
  per_len = dims[3]

  wid = per_len/8.

  noise_psds = modal_psds*0.
  atm_psds = modal_psds
  for k=0, n-1 do begin
     for l=0, n-1 do begin
        this_psd = modal_psds[k,l,*]
        noise_level = median(this_psd[per_len/2-wid:per_len/2+wid])
        noise_psds[k,l,*] = noise_level

        if option eq 0 then begin
           this_psd = this_psd - noise_psds[k,l,*]
           zl = where(this_psd LE 0., numz)
           if numz GT 0 then $
              this_psd[zl] = 0.
           atm_psds[k,l,*] = this_psd
        endif


        if option eq 1 then begin
           ;; be fancy here. What we'd like to do is mask out
           ;; the portions where noise dominates the atm.
           noise_rms = stddev(this_psd[per_len/2-wid:per_len/2+wid])
           print,noise_rms
           writefits,"psd.fits",this_psd[per_len/2-wid:per_len/2+wid]
           mask = this_psd LT noise_level + 2*noise_rms
           zl = where(mask EQ 1, numz)
           if numz GT 0 then $
              this_psd[zl] = 0.
           atm_psds[k,l,*] = this_psd
        endif

     endfor
  endfor
end
