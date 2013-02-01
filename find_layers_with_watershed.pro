;; written by Lisa A. Poyneer
;;; adapted from telemetry_analysis_07/watershed_peak_finder.pro
@my_centroid
function find_layers_with_watershed, metric, vx, lax=laxflag, stop=stopflag


  ;; basic parameters that you might change

  min_likelihood = 0.7 ;;; must have 70% likelihood to be found
  if keyword_set(laxflag) then min_likelihood = laxflag

  max_n_lay = 5.
  




  dims = size(metric)

  nx = dims[1]
  ny = dims[2]

  x = rebin(findgen(nx) - (nx-1)/2, nx, ny)
  y = transpose(rebin(findgen(ny) - (ny-1)/2, ny, nx))

  ;;; this is because of how the vector is defined
  delta_v = (vx[1]-vx[0])

  ;;; smooth the map to reduce noise
  map_smoothing_factor = 7
  smoothed_map = median_filter(metric, map_smoothing_factor)

  ;; invert it
  mymap = max(smoothed_map) - smoothed_map
  ;; convert to byte format, which is what the IDL 
  mymap_byte = byte(mymap/max(mymap)*255)

  ;;; use the built-in function
  segmentation = watershed(mymap_byte)
  overlay = segmentation NE 0.

  if keyword_set(stopflag) then begin
     exptv, metric*overlay
     stop
  endif

  thresh_amt = 0.75 ;;; throw out the bottom 75% of the region down
  ;; from the maximum value.

  ;; store the information!
  results = make_array(4, max_n_lay)

  ;;; start off and modify as we find things.
  modified_segmentation = segmentation
  modified_overlay = modified_segmentation NE 0.
  modified_map = metric*modified_overlay
  

  keeplooking = 1
  for t=0, max_n_lay-1 do begin
     if keeplooking then begin
        
        ;;; find the maximum value in the input metric
        maxv = max(modified_map, maxl)
        if maxv LE min_likelihood then begin
           print, 'in watershed - no significant layers left!!!!'
           print, 'finishing up.....', t
           keeplooking = 0
        endif else begin
           x0 = maxl mod nx
           y0 = (maxl - x0)/nx
           this_region_numbering = modified_segmentation[x0,y0]
           if this_region_numbering EQ 0. then begin
              print, 'WANRING: maximum value ended up on a segment boundary.'
              print, 'This should never happen'
              stop
           endif else begin
              ;; find the best location of the center of the hill 
              ;; in this region by centroiding on a thresholded
              ;; portion of it.
              
              mysig = metric*(modified_segmentation EQ this_region_numbering)
              mysig = (mysig - maxv*thresh_amt)
              mysig = mysig*(mysig GE 0.)

              locs = my_centroid(mysig)
              results[*,t] = [locs[0]*delta_v, locs[1]*delta_v, $
                              metric[x0,y0], 0]
              ;;; return the sub-pixel velocity, the metric at the
              ;;; maximum pixel, and 0 (can't recall what the 0 is for)

              ;; now have to remove this from what we are looking at!
              rlocs = where(modified_segmentation EQ this_region_numbering, numr)
              if numr LE 0 then begin
                 print, 'WARNING: no points in segmentation that match the foudn peak region!'
                 print, 'This should never happen'
                 stop
              endif
              modified_segmentation[rlocs] = 0.
              modified_overlay = modified_segmentation NE 0.
              modified_map = metric*modified_overlay

           endelse
        endelse
     endif
  endfor

  locs = where(results[2,*] EQ 0., numl)
  if numl GE 0 then $
     maxl = locs[0]-1 else $
        maxl = max_n_lay-1

  if maxl EQ -1 then begin
     print, 'No layers found!'
     return, make_array(4)
  endif

  return, results[*,0:maxl]

end
