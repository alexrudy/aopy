;; written by Lisa A. Poyneer
;;;; adapted from telemetry-analysis_07/find_wind_in_peaks
@generate_freq_grids
@find_layers_with_watershed
function find_and_fit_layers, peaks_hz, obs, lax=laxflag

  ;;; parameters that we might change

  lowest_hz = 2. ;;;; can't measure a peak below 2 Hz.
  dist_hz = 1.   ;;; must be within 1 hz of layer's value

  frac = 0.4 
  ;;;; this fraction of all Fmodes must have a layer frequency over
  ;;;; lowest_hz in order for that layer to be detected. 




  dims = size(peaks_hz)
  n_lay = dims[3]

 
  ;; a straightforward, brute-force algorith,
  ;;; construct a grid of vx and vy
  ;;; for each vx, vy, calculate the expetced layer frequencies
  ;;; match that to the peaks found.

  ;;; make the fourier modes grid
  delta_f = 1./(obs.n*obs.d) ;;; spatial frequency

  generate_freq_grids, fx, fy, obs.n, scale=delta_f

  fx = rebin(fx, obs.n, obs.n, n_lay)
  fy = rebin(fy, obs.n, obs.n, n_lay)

  max_v = 40.
  min_v = -max_v
  delta_v = 0.5
  num_v = (max_v-min_v)/delta_v + 1

  ;;; This is so that the velocities and maps match 
  ;;; what is in the original analysis.

  vx_found = findgen(num_v)*delta_v + min_v
  vy_foud = vx_found

  vx = reverse(vx_found)
  vy = vx

  valid = make_array(obs.n,obs.n) + 1.
  valid[0,0] = 0.


  found_high_enough = abs(peaks_hz) GT lowest_hz

  min_possible = frac*total(valid) 

  matched = make_array(num_v, num_v)
  possible = make_array(num_v, num_v)
  metric = make_array(num_v, num_v)
  assignment = make_array(obs.n, obs.n, n_lay)
  
  for vx1=0, num_v-1 do begin
     part1 = fx*vx[vx1]
     for vy1=0, num_v-1 do begin
        layer_peaks_hz = part1 + fy*vy[vy1]
        to_look_in = abs(layer_peaks_hz) GT lowest_hz
        possible[vx1,vy1] = total(to_look_in[*,*,0])
        if possible[vx1,vy1] GT min_possible then begin
           matched[vx1, vy1] = total(total((abs(layer_peaks_hz - peaks_hz) LE dist_hz) $
                                           AND (found_high_enough AND to_look_in), 3) NE 0)
           metric[vx1,vy1] = matched[vx1,vy1]/possible[vx1,vy1]
        endif
     endfor
  endfor


  ;;; now that we've got the metric, find and fit them with watershed!
  thisres = find_layers_with_watershed(metric, vx, lax=laxflag)

  res = {vx:vx, vy:vy, metric:metric, layer_list:thisres}
  make_wind_map, /old, res, obs

  return, res


end
