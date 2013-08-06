@imagemagick_helpers
pro make_layer_freq_image, fit_data, wind_data, obs, maxv=maxflag, png=pngflag

  peaks_hz = fit_data.est_omegas_peaks/(2*!pi)*obs.rate
  layer_list = wind_data.layer_list

  dist_hz = 1.   ;;; must be within 1 hz of layer's value

  dims = size(peaks_hz)
  n_lay = dims[3]
  n = dims[1]
  ;;; make the fourier modes grid
  delta_f = 1./(obs.n*obs.d) ;;; spatial frequency
  generate_freq_grids, fx, fy, obs.n, scale=delta_f


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

  max_n_lay = max([n_lay, n_found])


  ;;; put the foundl ayers into panels, sorted by strength
  layers_hz = make_array(n,n,n_found)
  for t=0, n_found-1 do begin
     vx = layer_list[0,t]
     vy = layer_list[1,t]
     layers_hz[*,*,t] = vx*fx + vy*fy
  endfor

  matched_layer_mask = make_array(n,n,n_lay, n_found)
  ;; no find matches - back this out from the data
  for t=0, n_lay-1 do begin
     for k=0, n-1 do begin
        for l=0, n-1 do begin
           for t1=0, n_found-1 do begin
              if abs(peaks_hz[k,l,t] - layers_hz[k,l,t1]) LE dist_hz then $
                 matched_layer_mask[k,l,t,t1] = 1
           endfor
        endfor
     endfor
  endfor
  
  peaks_hz_matched = make_array(n,n,max_n_lay)
  for t1=0, n_found-1 do $
     for k=0, n-1 do $
        for l=0, n-1 do $
           for t=0, n_lay-1 do $
              if matched_layer_mask[k,l,t, t1] EQ 1 then $
                 peaks_hz_matched[k,l,t1] = peaks_hz[k,l,t]



  ;; Put the peaks into panels, unsorted
  grid1 = make_array(n*max_n_lay + 1*(max_n_lay-1), n)
  for t=0, n_lay-1 do $
     grid1[t*(n+1):t*(n+1) + n-1,*] = shift(peaks_hz[*,*,t], n/2, n/2)

;  stop

  grid2 = make_array(n*max_n_lay + 1*(max_n_lay-1), n)
  if n_found EQ 1 then begin
     ;;;; since IDL has changed it from a 4D to a 3D array !
     for t=0, n_lay-1 do $
        grid2[t*(n+1):t*(n+1) + n-1,*] =  shift(peaks_hz[*,*,t]*(matched_layer_mask[*,*,t] NE 0.), n/2, n/2)
  endif else begin
     for t=0, n_lay-1 do $
        grid2[t*(n+1):t*(n+1) + n-1,*] =  shift(peaks_hz[*,*,t]*(total(matched_layer_mask[*,*,t,*], 4) NE 0.), n/2, n/2)
  endelse


  grid3 = make_array(n*max_n_lay + 1*(max_n_lay-1), n)
  for t=0, n_found-1 do $
     grid3[t*(n+1):t*(n+1) + n-1,*] =  shift(peaks_hz_matched[*,*,t], n/2, n/2)

  grid4 = make_array(n*max_n_lay + 1*(max_n_lay-1), n)
  for t=0, n_found-1 do $
     grid4[t*(n+1):t*(n+1) + n-1,*] =  shift(layers_hz[*,*,t], n/2, n/2)
  maxv = max(abs(grid4))

  if keyword_set(maxflag) then maxv = maxflag

  grid3b = ((grid3 NE 0.)*3. - 2.)*maxv*.95



  for t=0, max_n_lay-2 do begin
     grid1[n + t*(n+1),*] = maxv*2
     grid2[n + t*(n+1),*] = maxv*2
     grid3[n + t*(n+1),*] = maxv*2
     grid3b[n + t*(n+1),*] = maxv*2
     grid4[n + t*(n+1),*] = maxv*2
  endfor
  
  space = make_array(n*max_n_lay + 1*(max_n_lay-1),1) + maxv*2.
  sig = [[grid4], [space], [grid3b], [space], [grid3], [space], [grid2], [space], [grid1]]


  if keyword_set(pngflag) then begin
     ;;;; save to disk in a nice form.
     
     ;; pad the sig to give space to annote
     border = round(n*.75)
     dims = size(sig)


     newsig = make_array(dims[1]+2*border, dims[2] + 2*border) + maxv*2
     newsig[border:border+dims[1]-1, border:border+dims[2]-1] = sig
     sig = newsig
     dims = size(sig)

     ;; add in a color bar
     cbxl = round(dims[1]-border*.75)
     cbxh = round(dims[1]-border*0.5)
     cbyl = border
     cbyh = dims[2]-border-1

     sig[cbxl:cbxh, cbyl:cbyh] = $
        (transpose(rebin(findgen(cbyh-cbyl + 1), cbyh-cbyl + 1,cbxh-cbxl + 1 ))/(cbyh-cbyl)*2 - 1)*maxv

     minv = -maxv
     low = 0.
     high = 255.
     slope = (high-low)/(maxv-minv)
     intercept = high - slope*maxv

     sig = sig*slope + intercept
     mask = sig LE 0.
     sig = sig*(1-mask) + mask*0
     mask = sig GT 255
     sig = sig*(1-mask) + mask*255

     
     ufac = 4
     if obs.n EQ 26 then ufac = 3 ;; keck
     if obs.n EQ 16 then ufac = 5 ;; altair

     panelradx = ufac*(dims[1] - 2*border)/2.
     panelrady = ufac*(dims[2] - 2*border)/2.


     sig_byte = byte(rebin(round(sig), $
                           dims[1]*ufac, dims[2]*ufac, /samp))
     fname = 'figures/layer_freq_'+obs.telescope + '_' + obs.filename + '.gif'
     fname_png = 'figures/layer_freq_'+obs.telescope + '_' + obs.filename + '.png'
     write_gif, fname, sig_byte


     ;;; the color bar
     imh_text, fname, /center, panelradx + ufac*border*.375, -(panelrady + ufac*border*0.25), strcompress(/rem, string(round(maxv))) + " Hz"
     imh_text, fname, /center, panelradx + ufac*border*.375, (panelrady + ufac*border*0.25), strcompress(/rem, string(round(minv))) + " Hz"
     imh_rect, fname, ufac*cbxl, ufac*cbyl, ufac*(cbxh+1), ufac*(cbyh+1), color='black'

     ;;; case
     imh_text, fname, /center, 0, -(panelrady + ufac*border*0.5), obs.telescope + ": " + obs.filename, /bold, /big

     ;;; layers
     for t=0, n_found-1 do begin
        xloc = ufac*(t - (max_n_lay-1.)/2.)*(n+1)
        imh_text, fname, /center, xloc, (panelrady + ufac*border*0.25), $
                  strcompress('Layer ' + string(round(t)) + ': ' $
                          + string(round(100*layer_list[2,t]))) + "%"
        imh_text, fname, /center, xloc, (panelrady + ufac*border*0.5), $
                  strcompress("<" + string(layer_list[0,t], format='(F10.1)') + ', ' + $
                              string(layer_list[1,t], format='(F10.1)') + ">") 
     endfor

     ;; rotate it
     cmd = 'mogrify -rotate "90" '+ fname
     spawn, cmd

     imh_text, fname, /center, ufac*(4 - (5-1.)/2.)*(n+1), -(panelradx + ufac*border*0.25), "Found peaks"
     imh_text, fname, /center, ufac*(3 - (5-1.)/2.)*(n+1), -(panelradx + ufac*border*0.25), "Matched"
     imh_text, fname, /center, ufac*(2 - (5-1.)/2.)*(n+1), -(panelradx + ufac*border*0.25), "Sorted"
     imh_text, fname, /center, ufac*(1 - (5-1.)/2.)*(n+1), -(panelradx + ufac*border*0.25), "Mask"
     imh_text, fname, /center, ufac*(0 - (5-1.)/2.)*(n+1), -(panelradx + ufac*border*0.25), "Pure layers"
     ;; rotate it
     cmd = 'mogrify -rotate "-90" '+ fname
     spawn, cmd

     cmd = 'convert '+ fname + " " + fname_png
     spawn, cmd
     cmd = '\rm '+ fname
     spawn, cmd

  endif else begin

     offset = -2
     exptv, sig, min=-maxv, max=maxv ,/data
     xyouts, orientation=90, align=0.5, charsize=1.25, offset, (n+1)*4 + n/2, 'Found peaks'
     xyouts, orientation=90, align=0.5, charsize=1.25, offset*2, (n+1)*3 + n/2, 'Found peaks that'
     xyouts, orientation=90, align=0.5, charsize=1.25, offset, (n+1)*3 + n/2, 'match a layer'
     xyouts, orientation=90, align=0.5, charsize=1.25, offset, (n+1)*2 + n/2, 'Found: layers'
     xyouts, orientation=90, align=0.5, charsize=1.25, offset, (n+1)*1 + n/2, 'Found: mask'
     xyouts, orientation=90, align=0.5, charsize=1.25, offset, (n+1)*0 + n/2, 'Theory: layers'


     xyouts, charsize=1.75, align=0.5, 0.5*(n*max_n_lay + max_n_lay-1),(n+1)*5 + 1 ,  $
             obs.telescope + ': ' + obs.filename
  endelse

;  stop

end
