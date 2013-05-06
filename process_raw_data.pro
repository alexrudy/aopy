@get_case_altair
@get_case_keck
@get_case_gems
@disp2d
@gems_phase_mapping
@gems_slope_mapping

;; written by Lisa A. Poyneer
;; generalization of methods used in
;; telemetery_analysis/get_processed_X_data.pro

pro prd_add_header_info, obs, h1

  fxaddpar, h1, 'TSCOPE', obs.telescope, 'Telescope of observation'
  fxaddpar, h1, 'RAWPATH', obs.raw_path, 'File path and name of raw telemetry archive'
  fxaddpar, h1, 'PROCPATH', obs.processed_path, 'File path and name of the processes data'
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''
  ;; fxaddpar, h1, '', '', ''

end


pro process_raw_data, obs, stop=stopflag, enforce_frat=eflag

;;;; pass in a structure that has all the relevant information about 
;;;; where the data are saevd on disk, the telescope, etc.
;;;; parse options in that struct and use them to produce the
;;;; standard output, which is a 3D data cube of Fourier modes of the
;;;; wavefront through time.

;;;; This is saved to disk for later use reading in.


  ;;; First things first - read in the raw data

  if strcmp(obs.read_method, 'restore-trs') then begin
     restore, obs.raw_path
     if strcmp(obs.datatype, 'closed-loop-residual') then begin
        sig = trsdata.residualwavefront
     endif
     if strcmp(obs.datatype, 'closed-loop-dm-commands') then begin
        sig = trsdata.dmcommand
     endif
  endif

  if strcmp(obs.read_method, 'restore') then begin
     restore, obs.raw_path
     if strcmp(obs.datatype, 'closed-loop-residual') then begin
        sig = data.residualwavefront
     endif
     if strcmp(obs.datatype, 'closed-loop-dm-commands') then begin
        sig = data.dmcommand
     endif
  endif

  if strcmp(obs.read_method, 'fits') then begin
     sig = readfits(obs.raw_path)
  endif

  if n_elements(sig) LE 0 then begin
     print, 'WARNING! No data has been read in!'
     print, 'Either your read_method:', obs.read_method, ' is not supported'
     print, 'of these was no data when opened'
     print, ' '
     stop
  endif


  if strcmp(obs.pupil_remap, 'gems-custom-wfs') then eflag = 1

  if strcmp(obs.data_dim, '2D') then begin
     ;;;; data are 2D - actuators across, time long)
     ;;; need to populate a pupil

     dims = size(sig)
     wid = dims[1]
     len = dims[2]
     
     if strcmp(obs.pupil_remap, 'gems-fratricide-wfs') then begin
        fratricide_Mask = readfits(strmid(obs.raw_path, 0, strlen(obs.raw_path)-strlen('slopes.fits')) + $
                                   'mask_wfs'+strcompress(/rem, string(round(obs.wfs_number)))+'.fits')
     endif

     if keyword_set(eflag) then begin
        fratricide_Mask = readfits('data/gems/raw/mask_wfs'+strcompress(/rem, string(round(obs.wfs_number)))+'.fits')
     endif

     ;;;; convert the 1D vector to the 2D pupil image correctly
     dm_shape = make_array(obs.n, obs.n, len)

     ;;; for disp2d and locations, we process one time step at a time
     for t=0, len-1 do begin
        this_sig = sig[*,t]

        ;; custom for each one!
        if strcmp(obs.pupil_remap, 'disp2d') then begin
           this_dm = disp2d(this_sig)
           dm_shape[obs.l_dm:obs.h_dm, obs.l_dm:obs.h_dm,t] = this_dm
        endif

        if strcmp(obs.pupil_remap, 'locations') then begin
           this_dm = make_array(obs.n, obs.n)
           this_dm[obs.indices] = this_sig[obs.locations]
           dm_shape[*,*,t] = this_dm
        endif
     endfor
     
     ;;; for GEMS data we process the entire time series at once!
     if strcmp(obs.pupil_remap, 'gems-custom-dm') then begin
        dm_shape[obs.l_dm:obs.h_dm, obs.l_dm:obs.h_dm,*] = gems_phase_mapping(sig, obs.dm_number)
     endif
     if keyword_set(eflag) then begin
        if strcmp(obs.pupil_remap, 'gems-custom-wfs') then begin
           dm_shape[obs.l_dm:obs.h_dm, obs.l_dm:obs.h_dm,*] = gems_slope_mapping(sig, obs.wfs_number, mask=fratricide_Mask)
        endif       
     endif else begin
        if strcmp(obs.pupil_remap, 'gems-custom-wfs') then begin
           dm_shape[obs.l_dm:obs.h_dm, obs.l_dm:obs.h_dm,*] = gems_slope_mapping(sig, obs.wfs_number)
        endif       
     endelse
     if strcmp(obs.pupil_remap, 'gems-fratricide-wfs') then begin
        dm_shape[obs.l_dm:obs.h_dm, obs.l_dm:obs.h_dm,*] = $
           gems_slope_mapping(sig, obs.wfs_number, mask=fratricide_Mask)
     endif


     pingrid = make_array(obs.n, obs.n)
     ;;;; get the mask that defines the valid pupil
     if strcmp(obs.pupil_remap, 'disp2d') then begin
        pingrid[obs.l_dm:obs.h_dm, obs.l_dm:obs.h_dm] = disp2d(make_array(wid) + 1.)
     endif
     
     if strcmp(obs.pupil_remap, 'locations') then begin
        pingrid[obs.indices] = 1.
     endif

     if strcmp(obs.pupil_remap, 'gems-custom-dm') then begin
        pingrid[obs.l_dm:obs.h_dm, obs.l_dm:obs.h_dm] = gems_phase_mapping(sig[*,0]*0 + 1., obs.dm_number)
     endif
     if keyword_set(eflag) then begin
        if strcmp(obs.pupil_remap, 'gems-custom-wfs') then begin
           pingrid[obs.l_dm:obs.h_dm, obs.l_dm:obs.h_dm] = $
              gems_slope_mapping(sig[*,0]*0 + 1., obs.wfs_number, mask=fratricide_Mask, /getmask)
        endif
     endif else begin
        if strcmp(obs.pupil_remap, 'gems-custom-wfs') then begin
           pingrid[obs.l_dm:obs.h_dm, obs.l_dm:obs.h_dm] = gems_slope_mapping(sig[*,0]*0 + 1., obs.wfs_number, /getmask)
        endif
     endelse

     if strcmp(obs.pupil_remap, 'gems-fratricide-wfs') then begin
        pingrid[obs.l_dm:obs.h_dm, obs.l_dm:obs.h_dm] = $
           gems_slope_mapping(sig[*,0]*0 + 1., obs.wfs_number, mask=fratricide_Mask, /getmask)
     endif

  endif


  if strcmp(obs.data_dim, '3D-timefirst') then begin
     dims = size(data)
     len = dims[1]
     thisn = dims[2]

     dm_shape = make_array(obs.n, obs.n, len)
     for t=0, len-1 do $
        dm_shape[obs.l_dm:obs.h_dm, obs.l_dm:obs.h_dm,t] = sig[t,*,*]

     ;;;; get the mask that defines the valid pupil
     if strcmp(obs.pupil_remap, 'data') then begin
        pingrid = (dm_shape[*,*,0] NE 0.)*1.
     endif
  endif
  
  ;;; free up space
  delvar, sig


  if keyword_set(stopflag) then stop
  ;;; now we scale to get units of nm of phase
  dm_shape = dm_shape*obs.scaling_for_nm_phase

  ;; remove piston phase from each frame
  for t=0, len-1 do begin
     this_dm = dm_shape[*,*,t]
     this_dm = this_dm - pingrid*total(this_dm*pingrid)/total(pingrid^2)
     dm_shape[*,*,t] = this_dm
  endfor
  
  if keyword_set(stopflag) then stop

  ;;; this is our data cube in actuator space. 
  ;;; let's save it
  mkhdr, h1, dm_shape
  prd_add_header_info, obs, h1
  fxaddpar, h1, 'DTYPE', 'Spatial signals', 'In spatial domain'
  writefits, obs.processed_path+'_phase.fits', dm_shape, h1



  ;;; now let's make the Fourier modes!
  fourier_modes = make_array(/comp, obs.n, obs.n, len)
  for t=0, len-1 do $
     fourier_modes[*,*,t] = fft(dm_shape[*,*,t])
  freq_dom_scaling = sqrt(obs.n^2/total(pingrid))
  fourier_modes = fourier_modes*freq_dom_scaling
  
  ;; this is our Fmode with time cube
  ;; let's save it
  ;; problem - FITS doesn't save complex data type.
  ;;; we solve by breaking into two file, real and imag.
  fourier_modes_to_save = make_array(obs.n, obs.n, len, 2)
  fourier_modes_to_save[*,*,*,0] = real_part(fourier_modes)
  fourier_modes_to_save[*,*,*,1] = imaginary(fourier_modes)
  mkhdr, h2, fourier_modes_to_save
  prd_add_header_info, obs, h2
  fxaddpar, h2, 'DTYPE', 'Fourier modes', 'In Fourier domain'
  fxaddpar, h2, 'IDLCODE', 'sig = readfits() & data = complex(sig[*,*,*,0],sig[*,*,*,1])', 'Code to reform correctly'
  writefits, obs.processed_path+'_fmodes.fits', fourier_modes_to_save, h2

end
