;;; Written by Lisa A. Poyneer

pro make_movie_phase, obs, slow=slowflag
;;; given a case, load in the phase from disk and save a movie of it 
;;; at a given frame rate

  phase = readfits(obs.processed_path+'_phase.fits')
  dims = size(phase)
  n = dims[1]
  len = dims[3]

;;; color scale is +/- 4 sigma around the mean
  v0 = mean(phase)
  sd = stddev(phase)
  ns = 4.
  minv = v0 - ns*sd
  maxv = v0 + ns*sd


;;; convert

  low = 0.
  high = 255.
  slope = (high-low)/(maxv-minv)
  intercept = high - slope*maxv

  data = phase*slope + intercept
  delvar, phase

  mask = data LE 0.
  data = data*(1-mask) + mask*0
  mask = data GT 255
  data = data*(1-mask) + mask*255


;; now make the movie


  cmd = '\rm tmp/img*.gif'
  print, cmd
  spawn, cmd
  print, ' '

;;;;; now save the files

  ufac = 8. ;; 8 pixels per actuator


  if keyword_set(slowflag) then $
     delta = round(obs.rate/25./10.) else $     
        delta = round(obs.rate/25.)

  if keyword_set(slowflag) then $
     last = len/10-1 else $
        last = len-1

  for t=0, last, delta do begin
     thisframe = data[*,*,t]
     thisframe_byte = byte(rebin(round(thisframe), $
                                 dims[1]*ufac, dims[2]*ufac, /samp))
     write_gif, 'tmp/img'+number_string(t/delta, len/delta+ 1)+'.gif', thisframe_byte
  endfor

;;; now create the movie

  savename = 'movies/movie_'+obs.telescope+'_'+obs.filename+'_phase'
  if keyword_set(slowflag) then savename = savename + '_slow'
  savename = savename + '.gif'


  cmd = 'whirlgif -time 4 -o '+savename+' tmp/img*.gif'
  print, cmd
  spawn, cmd
  print, ' '






end
