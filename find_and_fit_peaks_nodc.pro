;; Written by Lisa A. Poyneer
;;; Basde on the methods in telemetry_analysis_07/analyze_dataset.pro
;;; but with some new methods. In particular, the old method simply
;;; fit PSDs with fixed alphas with projection,. This new method finds
;;; the best alpha with curvefit. It also jointly fits everything
;;; together at the end.


;; this version does not explicitly fit DC first. Instead it fits all
;; peaks, and then sorts them and assigns to DC the one that has the
;; minimum magnitude
@fitter_alpha_complex
@fitter_all_together
function find_and_fit_peaks_nodc, atm_psds, k=kflag, l=lflag, more=moreflag, display=dflag, verbose=vflag, $
                                  stop=stopflag


  dims = size(atm_psds)
  n = dims[1]
  per_len = dims[3]
  omega = shift((findgen(per_len) - per_len/2)/per_Len*2*!pi, per_len/2)

  ;;;; firs thing we do is a fit to the DC term.
  ;;; this is low-order and is controlled by two paramters: 
  ;;; alpha and a power level


  max_n_lay = 5. + 1
  if keyword_set(moreflag) then max_n_lay = 10.

  ;; stuff to return
  alpha_dc = make_array(n,n)
  variance_dc = make_array(n,n)
  rms_dc = make_array(n,n)

  alphas_peaks = make_array(n,n, max_n_lay)
  variance_peaks =  make_array(n,n, max_n_lay)
  est_omegas_peaks =  make_array(n,n, max_n_lay)
  rms_peaks = make_array(n,n, max_n_lay)

  fit_atm_psds = atm_psds*0.
  fit_atm_peaks_psds = atm_psds*0.


  valid = make_array(n,n) + 1.
  valid[0,0] = 0.

  tolerance_for_dc = 0.005

  mask_rad = .01

  searchrad_dc = 0.02
  alpha_for_dc = 0.995

  searchrad_layer = 0.01
  searchrad_lower = 0.012
  alpha_for_layer = 0.999
  min_layer_rms_frac = 0.2 ;; must have 20% the RMS of the DC!

  min_alpha = 0.95
  max_alpha = 0.9998

  peak_template = gen_periodogram(make_array(/comp, per_len, per_len) + 1, per_len)
  peak_template_ft = conj(fft(peak_template))

  for k=0, n-1 do begin
     for l=0, n-1 do begin
        if valid[k,l] then begin

           if keyword_set(vflag) then print, 'On Fmode ', k, l

           this_psd = reform(atm_psds[k,l,*])
           fit_psd = this_psd*0.
           dc_fit_psd = this_psd*0.
           
           mask = this_psd*0 + 1. ;;; a mask to block out finding things too close to 
           ;;; previously found peaks!

           keeplooking = 1
           for t=0, max_n_lay-1 do begin
              if keeplooking then begin
                 ;;; remove what we've fit so far
                 this_psd = reform(atm_psds[k,l,*] - fit_psd)
                 ;;;; truncate any negative values
                 zl = where(this_psd LT 0., numz)
                 if numz GT 0 then this_psd[zl] = 0.


                 ;; for correlation also mask out a certain range
                 ;; around the last peak found!
                 this_psd = this_psd*mask

                 ;;; correlate with the shape to find a peak.
                 correl = real_part(fft(peak_template_ft*fft(this_psd), 1))
                 sig_to_search = correl

                 ;;; subpixel accuracy with the peak location
                 maxv = max(sig_to_search, xloc)
                 if (xloc eq 0) THEN m1_xloc = per_len - 1 else m1_xloc = xloc - 1
                 if (xloc eq per_len-1) THEN p1_xloc = 0 else p1_xloc = xloc + 1
                 ccm1 = sig_to_search[m1_xloc]
                 ccp1 = sig_to_search[p1_xloc]
                 cc0  = sig_to_search[xloc]
                 f_loc = 0.5*(ccm1-ccp1)/(ccm1+ccp1-2.0*cc0) + xloc
                 if f_loc GT per_len/2 then f_loc = f_loc - per_len
                 est_omega = f_loc*(omega[1]-omega[0])

                 ;;; do our fit only close to the found peak, and not
                 ;;; too close to DC.
                 weights = (abs(omega - est_omega) LE searchrad_layer) ; AND (abs(omega) GT searchrad_lower)
                 if total(weights) EQ 0. then begin
                    if keyword_set(vflag) then print, k, l, '  WARNING: no points to fit peak to!'
                    ;; this is triggered with est_omega is a NAN
                    keeplooking = 0
                 endif
                 coeff = [alpha_for_layer, est_omega, 1.]
                 fita=[1,0,1]
                 res = curvefit(omega, this_psd, weights, coeff, fita=fita, function_name='fitter_alpha_complex')

                 ;; a set of error conditions
                 problem1 = (coeff[2]) LE 0                                       ;;;; power is negative. Bad!
                 problem2 = (coeff[0] LT min_alpha) OR (coeff[0] GT max_alpha)    ;;; bad alpha
                 if problem1 OR problem2 then begin
                    if keyword_set(vflag) then print, k, l, '  WARNING!: bad fit on coefficients. Aborting further peak finding....', t
;                       print, 'problem 1: power = ', coeff[2]
;                       print, 'problem 2: alpha = ', coeff[0]
                    res = this_psd*0.
                    keeplooking = 0
                 endif else begin
                    alphas_peaks[k,l,t] = coeff[0]
                    est_omegas_peaks[k,l,t] = est_omega
                    variance_peaks[k,l,t] = coeff[2]
                    rms_peaks[k,l,t] = sqrt(total(res))
                    fit_psd = fit_psd + res

                    mask = mask*(abs(omega - est_omega) GT mask_rad)

                 endelse
                 if keyword_set(dflag) then begin
                    mystring = 'Layers '
                    mystring = mystring  + 'Best-fit: curvefit, '
                    mystring = strcompress(mystring + 'alpha = ' + string(alphas_peaks[k,l,t]) + $
                                           ', omega = ' + string(est_omegas_peaks[k,l,t]) + $
                                           ', variance = ' + string(variance_dc[k,l]))

                    plot, shift(omega, per_len/2), shift(this_psd, per_len/2),  xrange=[-1,1]*.2, $
                          title=mystring
                    oplot, shift(omega, per_len/2), shift(res, per_len/2), color=250
                    oplot, shift(omega, per_len/2), shift(this_psd - res, per_len/2), color=100
                    stop
                 endif
                 if keyword_set(vflag) then print, 'Done with layer # ', t
              endif
           endfor

           ;; done finding peaks. Now we have to find which is 'DC'
           ;; for each and assign it to that!


           fit_atm_psds[k,l,*] = fit_psd 
           fit_atm_peaks_psds[k,l,*] = fit_psd - dc_fit_psd

           if keyword_set(dflag) then begin
              mystring = 'All ' 
              mystring = strcompress(mystring + 'k = ' + string(round(k)) + $
                                     ', l = ' + string(round(l)))

              plot, shift(omega, per_len/2), shift(reform(atm_psds[k,l,*]), per_len/2), xrange=[-1,1]*.2, $
                    title=mystring, /ylog
              oplot, shift(omega, per_len/2), shift(reform(fit_atm_psds[k,l,*]), per_len/2), color=250
              oplot, shift(omega, per_len/2), shift(reform(fit_atm_peaks_psds[k,l,*]), per_len/2), color=175, line=2
              oplot, shift(omega, per_len/2), shift(reform(fit_atm_psds[k,l,*]-fit_atm_peaks_psds[k,l,*]), per_len/2), color=200, line=2
              oplot, shift(omega, per_len/2), (shift(reform(atm_psds[k,l,*]-fit_atm_psds[k,l,*]), per_len/2)), color=50

              for t = 0, max_n_lay-1 do $
                 if est_omegas_peaks[k,l,t] NE 0. then $
                    oplot, [1,1]*est_omegas_peaks[k,l,t], [1e-4,1e4], line=1

              print, 'Initial fit (individual)'
              print, '           alpha        rms       omega'
              print, '-------------------------------------'
;              print, '      DC', alpha_dc[k,l], rms_dc[k,l]
              for t = 0, max_n_lay-1 do $
                 if est_omegas_peaks[k,l,t] NE 0. then $
                    print, t, alphas_peaks[k,l,t], rms_peaks[k,l,t], est_omegas_peaks[k,l,t]
              print, '-------------------------------------'
              stop
           endif


           ;;;; now stop if we've been told to

           if keyword_set(kflag) then begin
              if keyword_set(kflag) then begin
                 if (k EQ kflag) and (l eq lflag) then begin
                    print, ' '
                    print, 'Stopping at your request....'
                    print, ' '

                    stop
                 endif
              endif
           endif

;           print, 'OK - try out this new method!'
;           stop

              ;;; let's go through and find which are the
              ;;; significant peaks
              ;;; and fit the PSD jointly.

              ;;; first - determine how many of the max_n_lay are
              ;;;         actually valid!

           this_psd = reform(atm_psds[k,l,*])

           if keyword_set(stopflag) then stop

           ;; very first thing - find one close to DC1
           
           plocs= where(variance_peaks[k,l,*] NE 0., numf)
           if numf LE 0 then begin
              if keyword_set(vflag) then print, k, l, '  WARNING!: no peaks were found at all!!!!'
              ; stop
           endif
           
           ;; now find the peak with the most power that is very close
           ;; to DC and assign it to DC!

           nodc = 0
           dclocs = where(abs(est_omegas_peaks[k,l,plocs]) LE tolerance_for_dc, numdc)
           if numdc LE 0 then begin
              if keyword_set(vflag) then print, k, l, '  WARNING!: did not find a DC peak! Continuing....'
              nodc = 1
              alpha_dc[k,l] = 0.
              variance_dc[k,l] = 0.
              rms_dc[k,l] = 0.
              dc_fit_psd = this_psd*0.
;              stop
           endif else begin
              ;; pick the one with the most power!
              foo = max(rms_peaks[k,l,plocs[dclocs]], maxl)
              minl0 = dclocs[maxl]
              minl = plocs[minl0]
              alpha_dc[k,l] = alphas_peaks[k,l,minl]
              alphas_peaks[k,l,minl] = 0.
              est_omegas_peaks[k,l,minl] = 0.
           ;;; not exact for now - since forcing omega = 0, but will
           ;;;                     be OK in the interim.

              myshape = 1./(1 - 2*alpha_dc[k,l]*cos(omega) + alpha_dc[k,l]^2)
              
              variance_dc[k,l] = total(myshape*this_psd)/total(myshape^2)
              variance_peaks[k,l,minl] = 0.
              dc_fit_psd = variance_dc[k,l]*myshape
              rms_dc[k,l] = sqrt(total(dc_fit_psd))
              rms_peaks[k,l,minl] = 0.

              ;;;; also will remove other peaks that are within the
              ;;;; tolerance but were not selected!

              zlocs = where(abs(est_omegas_peaks[k,l,plocs]) LT tolerance_for_dc, numl)
              if numl GT 0 then begin
                 if keyword_set(vflag) then print, k, l, '  removing some peaks too close to DC!'
                 est_omegas_peaks[k,l,plocs[zlocs]] = 0.
                 variance_peaks[k,l,plocs[zlocs]] = 0.
                 rms_peaks[k,l,plocs[zlocs]] = 0.
              endif

           endelse
           fit_psd = dc_fit_psd

           ;; note - if NO dc was found, all peaks are kept
           vlocs = where(rms_peaks[k,l,*] GT rms_dc[k,l]*min_layer_rms_frac, numv)
           if numv LE 0 then begin
              if keyword_set(vflag) then print, k, l, '  No significant non-DC peaks found in joint fit step! '
              alphas_peaks[k,l,*] = 0
              est_omegas_peaks[k,l,*] = 0
              variance_peaks[k,l,*] = 0
              rms_peaks[k,l,*] = 0

              fit_atm_psds[k,l,*] = dc_fit_psd 
              fit_atm_peaks_psds[k,l,*] = 0.              
           endif else begin
              ;;;; we have peaks with enough power

              ;;; assemble the initial estiamtes from individual fits
              ;;; into the vector

              ;;;;; DC
              coeff = make_array(2 + max_n_lay*3)
              fita = make_array(2 + max_n_lay*3)

              ;;; the layers
              coeff[0:1] = [alpha_dc[k,l], variance_dc[k,l]]
              for vv=0, numv-1 do $
                 coeff[2+3*vv:2+3*(vv+1)-1] = [alphas_peaks[k,l,vlocs[vv]], $
                                               est_omegas_peaks[k,l,vlocs[vv]], $
                                               variance_peaks[k,l,vlocs[vv]]]

              ;;; specify which free paramters to use
              if nodc then $
                 fita[0:1] = [0,0] else $
                    fita[0:1] = [1,1]
              for vv=0, numv-1 do $
                 fita[2+3*vv:2+3*(vv+1)-1] = [1,0,1]

              ;;;; weight it - a certain distance beyond the maximum
              ;;;;             peak found
              weights = abs(omega) LE (max(abs(est_omegas_peaks[k,l,vlocs])) + searchrad_dc)
              res = curvefit(omega, this_psd, weights, coeff, fita=fita, function_name='fitter_all_together')

                 ;;;; put these new values back into storage
              alpha_dc[k,l] = coeff[0]
              variance_dc[k,l] = coeff[1]
              myshape = variance_dc[k,l]/(1 - 2*alpha_dc[k,l]*cos(omega) + alpha_dc[k,l]^2)
              rms_dc[k,l] = sqrt(total(myshape))

              dc_fit_psd = myshape

              fit_psd = dc_fit_psd
              alphas_peaks[k,l,*] = 0.
              variance_peaks[k,l,*] = 0.
              est_omegas_peaks[k,l,*] = 0.
              rms_peaks[k,l,*] = 0.
              for vv=0, numv-1 do begin
                 alphas_peaks[k,l,vlocs[vv]] = coeff[2+3*vv]
                 est_omegas_peaks[k,l,vlocs[vv]] = coeff[2+3*vv+1]
                 variance_peaks[k,l,vlocs[vv]] = coeff[2+3*vv+2]

                 myshape = variance_peaks[k,l,vlocs[vv]]/$
                           (1 - 2*alphas_peaks[k,l,vlocs[vv]]*cos(omega-est_omegas_peaks[k,l,vlocs[vv]]) + $
                            alphas_peaks[k,l,vlocs[vv]]^2)
                 rms_peaks[k,l,vlocs[vv]] = sqrt(total(myshape))

                 problem1 = rms_peaks[k,l,vlocs[vv]] LT rms_dc[k,l]*min_layer_rms_frac
                 problem2 = (alphas_peaks[k,l,vlocs[vv]]  LT min_alpha) OR (alphas_peaks[k,l,vlocs[vv]]  GT max_alpha)
                 if problem1 OR problem2 then begin
                    if problem1 then $
                       if keyword_set(vflag) then print, k, l, '  After joint fit, this peak is not strong enough. Removing: ', vlocs[vv]
                    if problem2 then $
                       if keyword_set(vflag) then print, k, l, '  After joint fit, alpha is out of range.          Removing: ', vlocs[vv], $
                                                         est_omegas_peaks[k,l,vlocs[vv]] , alphas_peaks[k,l,vlocs[vv]]
                    alphas_peaks[k,l,vlocs[vv]] = 0
                    est_omegas_peaks[k,l,vlocs[vv]] = 0
                    variance_peaks[k,l,vlocs[vv]] = 0
                    rms_peaks[k,l,vlocs[vv]] = 0
                 endif else begin
                    fit_psd = fit_psd + myshape
                 endelse
                 
              endfor
              fit_atm_peaks_psds[k,l,*] = fit_psd - dc_fit_psd
              fit_atm_psds[k,l,*] = fit_psd
           endelse



;                 stop
           if keyword_set(dflag) then begin
              mystring = 'All, jointly fit ' 
              mystring = strcompress(mystring + 'k = ' + string(round(k)) + $
                                     ', l = ' + string(round(l)))

              plot, shift(omega, per_len/2), shift(reform(atm_psds[k,l,*]), per_len/2), xrange=[-1,1]*.2, $
                    title=mystring, /ylog
              oplot, shift(omega, per_len/2), shift(reform(fit_atm_psds[k,l,*]), per_len/2), color=250
              oplot, shift(omega, per_len/2), shift(reform(fit_atm_peaks_psds[k,l,*]), per_len/2), color=175, line=2
              oplot, shift(omega, per_len/2), shift(reform(fit_atm_psds[k,l,*]-fit_atm_peaks_psds[k,l,*]), per_len/2), color=200, line=2
              oplot, shift(omega, per_len/2), (shift(reform(atm_psds[k,l,*]-fit_atm_psds[k,l,*]), per_len/2)), color=50

              for t = 0, max_n_lay-1 do $
                 if est_omegas_peaks[k,l,t] NE 0. then $
                    oplot, [1,1]*est_omegas_peaks[k,l,t], [1e-4,1e4], line=1
              oplot, [1,1]*0., [1e-4,1e4], line=2


              print, 'Joint fit (final)'
              print, '           alpha        rms       omega'
              print, '-------------------------------------'
              print, '      DC', alpha_dc[k,l], rms_dc[k,l]
              for t = 0, max_n_lay-1 do $
                 if est_omegas_peaks[k,l,t] NE 0. then $
                    print, t, alphas_peaks[k,l,t], rms_peaks[k,l,t], est_omegas_peaks[k,l,t]
              print, '-------------------------------------'

              stop
           endif


        endif
     endfor
  endfor
  
  return, {alpha_dc:alpha_dc, $
           variance_dc:variance_dc, $
           rms_dc:rms_dc, $
           alphas_peaks:alphas_peaks, $
           variance_peaks:variance_peaks, $
           rms_peaks:rms_peaks, $
           est_omegas_peaks:est_omegas_peaks, $
           fit_atm_psds:fit_atm_psds, $
           fit_atm_peaks_psds:fit_atm_peaks_psds}




end
