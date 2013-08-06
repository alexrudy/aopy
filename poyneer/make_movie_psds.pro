;;; Written by Lisa A. Poyneer

;; new version. - requires imageMagick is installed via MacPorts
;;; this allows the frame rate and other annotations to be added
;;; conveniently to the GIFs.

;; requires whirlgif to be installed via Macports


pro make_movie_psds, atm_psds0, fit_atm_psds0, layer_list, ca, $
                     stop=stopflag, preview=pflag, fits=fitsflag

  atm_psds = atm_psds0
  fit_atm_psds = fit_atm_psds0
  

  frac = 16.

  ;; given the PSds and the found layers, make a movie showing 
  ;;; these off side by side!

  if n_elements(layer_list) GT 0 then begin
     if n_elements(layer_list) EQ 4 then begin
        n_found = 1
     endif else begin
        dims = size(layer_list)
        n_found = dims[2]
     endelse
  endif else begin
     print, 'No layers found in list!'
     return
  endelse

  dims = size(atm_psds)
  n = dims[1]
  per_len = dims[3]

  ;;;;; normalize across spatial frequencies to take out the
  ;;;;; atmospheric poewr spectrum and make peaks more obvious

;  stop

  power = total(atm_psds, 3)
  log_power = alog10(power)
  smoothed_log_power = shift(gauss2dfit(shift(log_power, ca.n/2, ca.n/2)), ca.n/2, ca.n/2)
  smoothed_power = 10.^smoothed_log_power

  for t=0, per_len-1 do $
     atm_psds[*,*,t] = atm_psds[*,*,t]/smoothed_power

  for t=0, per_len-1 do $
     fit_atm_psds[*,*,t] = fit_atm_psds[*,*,t]/smoothed_power

  log_atm_psds = alog10(atm_psds)
  log_fit_atm_psds = alog10(fit_atm_psds)


  ;; adjust to the color scale
;;; color scale is +/- 4 sigma around the mean
  foo = fit_atm_psds[*,*,0:per_len/frac]
  log_foo = alog10(foo)
  minv = min(log_foo[where(foo NE 0.)])
  zl = where(atm_psds EQ 0., numz)
  if numz GT 0 then log_atm_psds[zl] = minv
  zl = where(fit_atm_psds EQ 0., numz)
  if numz GT 0 then log_fit_atm_psds[zl] = minv
  
  maxv = max([log_atm_psds, log_fit_atm_psds])

;;; convert

  low = 0.
  high = 255.
  slope = (high-low)/(maxv-minv)
  intercept = high - slope*maxv

  data = log_atm_psds*slope + intercept
  delvar, log_atm_psds
  mask = data LE 0.
  data = data*(1-mask) + mask*0
  mask = data GT 255
  data = data*(1-mask) + mask*255

  data_fit = log_fit_atm_psds*slope + intercept
  delvar, log_fit_atm_pds
  mask = data_fit LE 0.
  data_fit = data_fit*(1-mask) + mask*0
  mask = data_fit GT 255
  data_fit = data_fit*(1-mask) + mask*255

  ;;; now make the mask that shows that layers that we found!

  delta_f = 1./(ca.n*ca.d) ;;; spatial frequency
  generate_freq_grids, fx, fy, ca.n, scale=delta_f

  delta_ft = per_len/ca.rate
  hz = shift(findgen(per_len) - per_len/2, per_len/2)/(per_len/2)*ca.rate/2.

  layers_hz = make_array(n,n,n_found)
  for t=0, n_found-1 do begin
     vx = layer_list[0,t]
     vy = layer_list[1,t]
     layers_hz[*,*,t] = vx*fx + vy*fy
  endfor  

  alpha = 0.99
  data_mask0 = make_array(n,n,per_len, n_found)
  for t=0, n_found-1 do $
     for k=0, n-1 do $
        for l=0, n-1 do $
           data_mask0[k,l,*,t] = (1-alpha)^2/$
     (1 - 2*alpha*cos(2*!pi/ca.rate*(hz-layers_hz[k,l,t])) + $
      alpha^2)

  if n_found EQ 1 then $
     data_mask = data_mask0 else $
        data_mask = max(data_mask0, dimension=4)

  data_mask = data_mask*.75

  data_mask = data_mask*255
  mask = data_mask GT 255
  data_mask = data_mask*(1-mask) + mask*255
  
  ;; everything together!
  all_data = [shift(data, n/2, n/2, 0), shift(data_fit, n/2, n/2, 0), shift(data_mask, n/2, n/2, 0)]
  all_data = [[[all_data[*,*,per_len-per_len/frac:per_len-1]]], [[all_data[*,*,0:per_len/frac-1]]]]
  hz = [hz[per_len-per_len/frac:per_len-1], hz[0:per_len/frac-1]]

  if keyword_set(stopflag) then stop

  delvar, data
  delvar, data_fit
  delvar, data_mask
  

  if keyword_set(pflag) then begin
     for t=0, per_len/(frac/2)-1 do begin
        wait, 1/24.
        exptv, min=0, max=255, all_data[*,*,t]
     endfor
     print, 'If this was good, IDL> .cont to save.'
     print, 'Else IDL> return to abort'
     print, ' '
     stop
  endif


  savename = 'movies/movie_'+ca.telescope+'_'+ca.filename+'_psds_layers'

  if keyword_set(fitsflag) then begin
     writefits, savename+'.fits', all_data
     cmd = 'ds9 ' + savename+'.fits' + '&'
     print, cmd
     spawn, cmd

  endif else begin
;; now make the movie

     cmd = '\rm tmp/img*.gif'
     print, cmd
     spawn, cmd
;  print, ' '

;;;;; now save the files

     ufac = 8. ;; 8 pixels per frequency

     for t=0, per_len/(frac/2)-1 do begin
;     print, t, per_len/(frac/2)-1
        thisframe = all_data[*,*,t]
        thisframe_byte = byte(rebin(round(thisframe), $
                                    n*3*ufac, n*ufac, /samp))
        ; fname = 'tmp/img'+number_string(t, per_len+ 1)+'.gif'
        fname = 'tmp/img'+STRING(t,FORMAT='(I2.2)')+'.gif'
        write_gif, fname, thisframe_byte

        ;; add in notation for the temporal frequency
        cmd = 'mogrify ' + ' -draw "text '+$
              strcompress(/rem, string(round(2*ufac)))+ ',' + $
              strcompress(/rem, string(round(ufac*n - 4)))+ ' ' + "'" + $
              string(hz[t], format='(F10.1)') + " Hz'" + '"' + $
              ' ' + fname
        spawn, cmd
     endfor

     ;; add in the dataset filename to every frame
     cmd = 'mogrify ' + ' -draw "text '+$
           strcompress(/rem, string(round(2*ufac)))+ ',' + $
           strcompress(/rem, string(round(2*ufac)))+ ' ' + "'" + $
           ca.processed_path + "'" + '"' + $
           ' tmp/*.gif' 
     spawn, cmd
     
;;; now create the movie
     savename = savename + '.gif'
     cmd = 'whirlgif -time 4 -o '+savename+' tmp/img*.gif'

     print, cmd
     spawn, cmd
     print, ' '


  endelse




end
