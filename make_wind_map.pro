@imagemagick_helpers
pro make_wind_map, wind_data, obs, oldcolor=oflag, png=pngflag, lax=laxflag

  ;;; lax means we've used a lower limit for detections. Change
  ;;; the color scale!

  metric = wind_data.metric
  vx = wind_data.vx
  layer_list = wind_data.layer_list

  if keyword_set(oflag) then loadct, 5

  dims = size(metric)
  n = dims[1]
  
  ;; vx shold be symmetric and odd-length
  delv = vx[1]-vx[0]
  maxvel = max(vx)
  maxvel_10 = round(maxvel/10)*10.
  maxvelr_10 = round(maxvel*sqrt(2.)/10)*10.



  if keyword_set(pngflag) then begin

     if keyword_set(laxflag) then begin
        mymax = laxflag*2.
        title_suffix = ' LAX! white = '+strcompress(/rem, string(format='(F5.2)', 1e2*laxflag*2)+'%')
     endif else begin
        mymax = 1.
        title_suffix = ''
     endelse


     maxv = 1.
     minv = 0.


     sig = metric

     sig = sig/mymax
     
     dims = size(sig)

     ;; pad the sig to give space to annote
     border = (dims[1]-1)/8.
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
        (transpose(rebin(findgen(cbyh-cbyl + 1), cbyh-cbyl + 1,cbxh-cbxl + 1 ))/(cbyh-cbyl))*maxv

     low = 0.
     high = 255.
     slope = (high-low)/(maxv-minv)
     intercept = high - slope*maxv

     sig = sig*slope + intercept
     mask = sig LE 0.
     sig = sig*(1-mask) + mask*0
     mask = sig GT 255
     sig = sig*(1-mask) + mask*255

     
     ufac = 3

     panelrad = ufac*(dims[1] - 2*border)/2.

     sig_byte = byte(rebin(round(sig), $
                           dims[1]*ufac, dims[2]*ufac, /samp))
     fname = 'figures/wind_map_'+obs.telescope + '_' + obs.filename + '.gif'
     fname_png = 'figures/wind_map_'+obs.telescope + '_' + obs.filename + '.png'
     write_gif, fname, sig_byte


     ;;; ************************************************************
     ;;; ************************************************************
     ;;; ************************************************************
     ;;; ************************************************************
     ;;; add in the annotations

     ;;; the color bar
     imh_text, fname, /center, panelrad + ufac*border*.375, -(panelrad + ufac*border*0.25), $
               strcompress(/rem, string(round(1e2*mymax))) +' %'
     imh_text, fname, /center, panelrad + ufac*border*.375, (panelrad + ufac*border*0.25), '0 %'
     imh_rect, fname, ufac*cbxl, ufac*cbyl, ufac*(cbxh+1), ufac*(cbyh+1), color='black'

     ;;;; the axes
     imh_text, fname, /center, 0, -(panelrad + ufac*border*0.5), obs.telescope + ": " + obs.filename, /bold ,/big
     imh_text, fname, /center, 0, (panelrad + ufac*border*0.5), 'X-velocity in pupil (m/s)'
     for m=-maxvel_10, maxvel_10, 10 do $
        imh_text, fname, /center, ufac*m/delv, (panelrad + ufac*border*0.25), strcompress(/re, string(round(m)))
     for m=-maxvel_10, maxvel_10, 10 do $
        imh_text, fname, /center, -(panelrad + ufac*border*0.25), -ufac*m/delv, strcompress(/re, string(round(m)))
     
     ;; the circle and line grids
     for m=10, maxvel_10, 10 do $
        imh_circle, fname, ufac*((dims[1]-1)/2) + 1, ufac*((dims[2]-1)/2) + 1, ufac*m/delv, color='white', /dash
     imh_line, fname, ufac*((dims[1]-1)/2) + 1, ufac*border, ufac*((dims[1]-1)/2) + 1, ufac*(dims[2]-border), color='white', /dash
     imh_line, fname, ufac*border, ufac*((dims[1]-1)/2) + 1, ufac*(dims[2]-border), ufac*((dims[1]-1)/2) + 1, color='white', /dash

     ;;; the layers

     if keyword_set(oflag) then textcolor = 'white' else textcolor = 'red'

     if n_elements(layer_list) GT 0 then begin
        if n_elements(layer_list) EQ 4 then begin
           ;;;; the dot
           imh_dot, fname, ufac*(dims[1]/2 + layer_list[0]/delv),  ufac*(dims[2]/2 - layer_list[1]/delv), 2
           ;;;; the label
           imh_text, fname, ufac*(dims[1]/2 + layer_list[0]/delv) + 1,  ufac*(dims[2]/2 - layer_list[1]/delv), $
                     strcompress(string(round(100*layer_list[2])))+'%', color='black', /bold
        endif else begin
           dims0 = size(layer_list)
           nlay = dims0[2]
           for l=0, nlay-1 do begin
           ;;;; the dot
              imh_dot, fname, ufac*(dims[1]/2 + layer_list[0,l]/delv),  ufac*(dims[2]/2 - layer_list[1,l]/delv), 2
           ;;;; the label
              imh_text, fname, ufac*(dims[1]/2 + layer_list[0,l]/delv) + 1,  ufac*(dims[2]/2 - layer_list[1,l]/delv), $
                        strcompress(string(round(100*layer_list[2,l])))+'%', color='black', /bold
           endfor
        endelse
     endif

     ;; y axis title
     cmd = 'mogrify -rotate "90" '+ fname
     spawn, cmd
     imh_text, fname, /center, 0, -(panelrad + ufac*border*0.5), 'Y-velocity in pupil (m/s)'
     cmd = 'mogrify -rotate "-90" '+ fname
     spawn, cmd

     ;; Done!
     cmd = 'convert '+ fname + " " + fname_png
     spawn, cmd
     cmd = '\rm '+ fname
     spawn, cmd

  endif else begin

     if keyword_set(laxflag) then begin
        mymax = laxflag*2.
        title_suffix = ' LAX! top = '+strcompress(/rem, string(format='(F6.0)', 1e2*laxflag*2)+'%')
     endif else begin
        mymax = 1.
        title_suffix = ''
     endelse



     exptv, /data, metric, min=0, max=mymax
     offset = -6
     ynudge = -10/delv*.1


     title = obs.telescope + ': ' + obs.filename + title_suffix
     xyouts, charsize=1.75, align=0.5, (n-1)/2, n + 3, title

     m = 0
     oplot, [0,0] + ((n-1)/2 + m/delv), [0,n], line=2
     oplot, [0,n],[0,0] + ((n-1)/2 + m/delv),  line=2

     for m=-maxvel_10, maxvel_10, 10 do begin
        xyouts, (n-1)/2 + m/delv, offset, align=0.5, charsize=1.25, strcompress(/re, string(round(m)))     
        xyouts, offset, (n-1)/2 + m/delv - ynudge, align=0.5, charsize=1.25, strcompress(/re, string(round(m)))     
     endfor

     ;; now draw circles!
     into = findgen(n)
     for m=10, maxvelr_10, 10 do begin
        oplot, into, sqrt((m/delv)^2- (into-(n-1)/2)^2) + (n-1)/2, line=2
        oplot, into, -(sqrt((m/delv)^2- (into-(n-1)/2)^2)) + (n-1)/2, line=2
     endfor

     xyouts, (n-1)/2, offset*2, align=0.5, charsize=1.25, 'X-velocity in pupil (m/s)'
     xyouts, offset*2, (n-1)/2, align=0.5, charsize=1.25, 'Y-velocity in pupil (m/s)', orientation=90


     if n_elements(layer_list) GT 0 then begin
        if n_elements(layer_list) EQ 4 then begin
           oplot, psym=4, [(n-1)/2 + layer_list[0]/delv], [(n-1)/2 + layer_list[1]/delv], color=0
           oplot, psym=2, [(n-1)/2 + layer_list[0]/delv], [(n-1)/2 + layer_list[1]/delv], color=255
           xyouts, align=0.5, charsize=1.25, (n-1)/2 + layer_list[0]/delv, (n-1)/2 + layer_list[1]/delv +offset, $
                   strcompress(string(round(100*layer_list[2]))+'%')
        endif else begin
           dims = size(layer_list)
           nlay = dims[2]
           for l=0, nlay-1 do begin
              oplot, psym=4, [(n-1)/2 + layer_list[0,l]/delv], [(n-1)/2 + layer_list[1,l]/delv], color=0
              oplot, psym=2, [(n-1)/2 + layer_list[0,l]/delv], [(n-1)/2 + layer_list[1,l]/delv], color=255
              xyouts, align=0.5, charsize=1.25, (n-1)/2 + layer_list[0,l]/delv, (n-1)/2 + layer_list[1,l]/delv + offset, $
                      strcompress(string(round(100*layer_list[2,l]))+'%')
           endfor
        endelse
     endif


  endelse

  if keyword_set(oflag) then loadct, 39


end
