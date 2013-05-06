@find_and_fit_peaks_nodc
@gen_periodogram
@split_psds_into_atm_and_noise
@make_plot_psd
@find_and_fit_peaks
@find_and_fit_layers
@find_layers_with_watershed
@make_wind_map
@make_layer_freq_image
@make_plot_psd
@make_movie_psds
@get_case_keck
@get_case_altair
@get_case_gems
;;; Written by Lisa A. Poyneer
;;; based on telemetry_analysis_07/analyze_data.pro

;;;; This loads in the Fmodes (fx by fy by time)
;;; and processes them into a 3D fourier cube.

pro process_fmodes, obs, per_len=pflag, more=moreflag, lax=laxflag, verbose=vflag, display=dflag, $
                    save_graphics_files=sflag, retearly=reteflag, relaxalpha = relaxflag, relaxrms = relaxrms

  if obs.rate GT 800 then per_len = 2048. else per_len = 1024.
  if keyword_set(pflag) then per_len = pflag 
  if (alog(per_len) - round(alog(per_len))) GT 1e-6 then begin
     print, 'Your input per_len must be a power of two!'
     return
  endif
  
  hz = shift((findgen(per_len) - Per_len/2)/per_len*obs.rate, per_len/2) ;; from -rate/2 to rate/2
  omega = hz/obs.rate*2*!pi                                              ;; from -pi to pi
  zinv = complexmp(1., -omega)

  ;; read in the Fmodes
  sig = readfits(obs.processed_path+'_fmodes.fits', h1) 
  fourier_modes = complex(sig[*,*,*,0],sig[*,*,*,1]) 



  dims = size(fourier_modes)
  n = dims[1]
  len = dims[3]

  start_i = 0
  end_i = len-1

  starttime = start_i/obs.rate
  endtime = end_i/obs.rate

  modal_psds = make_array(n,n,per_len)

  ;;;;; this is how we create them

  for k=0, n-1 do $
     for l=0, n-1 do $
        modal_psds[k,l,*] = gen_periodogram(/mean, /half, fourier_modes[k,l,*], per_len)
  
  ;;; now handle the Influence Function response of DM
  for k=0, n-1 do $
     for l=0, n-1 do $
        modal_psds[k,l,*] = modal_psds[k,l,*]*obs.dmtrans_mulfac[k,l]


  ;; now deal with the data type and the temporal response of the
  ;; control loop.



    ;;; calculate everything
  s = complex(0., 2*!pi*hz)
  bigT = 1./obs.rate
  wfs_cont = (1 - exp(-bigt*s))/(bigt*s)
  wfs_cont[0] = 1.
  dm_cont = wfs_cont
  delay_cont = exp(-obs.tau*s)
  zinv = exp(-bigT*s)

  cofz = obs.gain/(1 - obs.integrator_c*zinv) ;; actually 1*zinv, but must prevent division by zero!
  delay_term = wfs_cont*dm_cont*delay_cont

  tf_to_convert_to_phase = omega*0 + 1.

  if strcmp(obs.datatype, 'closed-loop-residual') then $
     tf_to_convert_to_phase = abs(1 + delay_term*cofz)^2

  if strcmp(obs.datatype, 'closed-loop-slopes') then $
     tf_to_convert_to_phase = abs(1 + delay_term*cofz)^2

  ;; should this be 
                                ;tf_to_convert_to_phase = abs((1 + delay_term*cofz)/(dm_cont*delay_cont*cofz))^2
  if strcmp(obs.datatype, 'closed-loop-dm-commands') then $
     tf_to_convert_to_phase = abs((1 + delay_term*cofz)/(cofz))^2

  ;;; if open loop, don't do anything!
;  if strcmp(obs.datatype, 'open-loop-residual') then $
;     tf_to_convert_to_phase = omega*0 + 1.


  for k=0, n-1 do $
     for l=0, n-1 do $
        modal_psds[k,l,*] = modal_psds[k,l,*]*tf_to_convert_to_phase
  
  ;;; modal_psds are now the estimate joint OL psd of the atmosphere +
  ;;; WFS noise, with no impact of the control system or the
  ;;; deformable mirror!

  if 0 then begin
     k = 3
     l = 3
     make_plot_psd, hz, modal_psds, k, l
     stop
  endif

  ;; what do we do now?

  ;;; first thing we can do is split this into noise and signl terms
  ;;; with a straightforward fitting procedure.

  split_psds_into_atm_and_noise, modal_psds, atm_psds, noise_psds

  if 0 then begin
     k = 3
     l = 3
     make_plot_psd, hz, atm_psds, k, l
     stop
  endif

  power_atm = total(atm_psds, 3)
  power_noise = total(noise_psds, 3)

  if 0 then begin
     ;; estimate r0 - code not working yet!
     r0 = estimate_r0(power_atm, obs.d)
  endif

  ;;; now move on to finding the peaks!

  if obs.rate LT 250. then relaxalpha = 1
  if keyword_set(relaxflag) then relaxalpha = 1
  if keyword_set(relaxrmsflag) then relaxrms = 1
  fit_data = find_and_fit_peaks_nodc(atm_psds, verbose=vflag, display=dflag, $
                                     relaxalpha=relaxalpha, $
                                     relaxrms=relaxrms)

  if 0 then begin
     k = 3
     l = 3
     make_plot_compare_psd, hz, atm_psds, fit_data, obs, k, l
     stop
  endif


  wind_data = find_and_fit_layers(fit_data.est_omegas_peaks/(2*!pi)*obs.rate, obs, lax=laxflag)

  
  ;; display nicely!
  print, 'Ok - look at stuff'
  print, '  '
  
  make_wind_map, wind_data, obs, /old, lax=laxflag
  if keyword_set(sflag) then $
     make_wind_map, wind_data, obs, /old, lax=laxflag, png=sflag

  if keyword_set(reteflag) then return

  stop
  make_layer_freq_image, fit_data, wind_data, obs
  if keyword_set(sflag) then $
     make_layer_freq_image, fit_data, wind_data, obs, png=sflag

  if 0 then begin
     k = 0
     l = 8
     make_plot_compare_psd, hz, atm_psds, fit_data, obs, k, l, /fully
     
     foo = find_and_fit_peaks_nodc(atm_psds, k=k, l=l)

     stop
  endif



  print, 'Next routines require ImageMagick, etc.'
  print, ' '
  stop

  ;;;; these require ImageMagick!
  make_wind_map, wind_data, obs, /old, /png
  make_layer_freq_image, fit_data, wind_data, obs, /png

  stop

  wset, 3 & make_layer_freq_image, fit_data.est_omegas_peaks/(2*!pi)*obs.rate, wind_data.layer_list, obs, maxv=10.

  make_movie_psds, atm_psds, fit_data.fit_atm_psds, wind_data.layer_list, obs



  alpha_dc = fit_data.alpha_dc
  variance_dc = fit_data.variance_dc
  rms_dc = fit_data.rms_dc
  alphas_peaks = fit_data.alphas_peaks
  variance_peaks = fit_data.variance_peaks
  rms_peaks = fit_data.rms_peaks
  fit_atm_psds = fit_data.fit_atm_psds
;;;; do this myself
  peaks_hz = fit_data.est_omegas_peaks/(2*!pi)*obs.rate
  

  ;; k = obs.n-5
  ;; l = 5

  ;; make_plot_psd, hz, atm_psds, k, l & make_plot_psd, hz, fit_data.fit_atm_psds, k, l, over=250

  make_plot_compare_psd, hz, atm_psds, fit_data, obs, k, l
  make_plot_psd, hz, atm_psds, k, l

end
