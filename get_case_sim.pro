; 
;  get_case_sim.pro
;  telem_analysis_13
;  
;  Created by Jaberwocky on 2013-03-11.
;  Copyright 2013 Jaberwocky. All rights reserved.
; 


;+
;            This function will generate a blowingScreen for the given input observation set.
;            
;-
function get_case_sim, identifier, obs=obs
    ; setup Don's blowingScreen functions
    ; blowingsrceen,
    
    if ~keyword_set(obs) then begin
        n = 30
        telescope = 'simulated'
        read_method = 'fits'
        data_suffix = '.fits'
        problems = 0

        data_dim='3D-timelast'
        pupil_remap = 'data'

        
        ;;; what files to look at
      ;  datatype = 'closed-loop-residual'
        datatype = 'closed-loop-dm-commands'
      ;  datatype = 'open-loop-residual'


        ;;;; AO system
        rate = 2000.0
        d = 3.0/30.0 ;; 56 cm subaps

        tau = 0.8e-3
        gain = 0.6
        integrator_c = 0.998

        ;;;; basic system info - grid size and how to put in grid
        n_dm = n
        l_dm = 0
        h_dm = n

      ;; inherent units!
      ;; from the app opp paper, the surface of the mirror movies 0.409518
      ;; microns per volt for a single actuator
        scaling_for_nm_phase = 1.0 ;;; actuator commands in volt - > nm of phase
        dmtrans_mulfac = ones(n,n)


        ;;; **************************
        ;;; **************************
        ;;; **************************
        ;;; **************************

        ;;; now for each identifier, specify the exact details
        if identifier lt 10 then begin
            archive_location = "test_phase"
        endif else if identifier lt 20 then begin
            archive_location = "test_phase_2l"
        endif else if identifier lt 30 then begin
            archive_location = "test_phase_2l_2"
        endif else if identifier eq 40 then begin
            archive_location = 'test_phase_2l_2v'
        endif else begin
            archive_location = "test_phase_" + strc(identifier)
        endelse
        filename = "sim_"+strc(identifier)
    
        seed = identifier
        path = 'data/' + telescope + '/'
        raw_path = path + 'raw/'
        processed_path = path + 'proc/'
        ;;; Get length of observation form data
        sig = readfits(raw_path+archive_location+data_suffix, h1) 
        dims = size(sig)
        len = dims[3]
        pingrid = sig[*,*,0] NE 0
    endif else begin
    
        telescope = obs.telescope + '_simulated'

        read_method = 'fits' ;;; sometimes not - set as appropriate
        data_suffix = '.fits'        ;;; sometimes not - set as appropriate
        problems = 0                ;;; sometimes not:  set to 1 if problems

        data_dim='3D-timelast'
        pupil_remap = 'data'


        ;;; what files to look at
      ;  datatype = 'closed-loop-residual'
        datatype = 'closed-loop-dm-commands'
      ;  datatype = 'open-loop-residual'


        ;;;; AO system
        rate = obs.rate
        d = obs.d ;; 56 cm subaps

        tau = obs.tau
        gain = obs.gain
        integrator_c = obs.integrator_c

        ;;;; basic system info - grid size and how to put in grid
        n = obs.n
        n_dm = obs.n_dm
        l_dm = obs.l_dm
        h_dm = obs.h_dm

      ;; inherent units!
      ;; from the app opp paper, the surface of the mirror movies 0.409518
      ;; microns per volt for a single actuator
        scaling_for_nm_phase = obs.scaling_for_nm_phase ;;; actuator commands in volt - > nm of phase
        dmtrans_mulfac = obs.dmtrans_mulfac


        ;;; **************************
        ;;; **************************
        ;;; **************************
        ;;; **************************

        ;;; now for each identifier, specify the exact details

        archive_location = "sim_"+strc(identifier)
        filename = "sim_"+strc(identifier)
    
        seed = identifier
    
        ;;; Get length of observation form data
        sig = readfits(obs.processed_path+'_phase.fits', h1) 
        dims = size(sig)
        len = dims[3]
        pingrid = sig[*,*,0] NE 0
    
    endelse
    
    ;;; **************************
    ;;; **************************
    ;;; **************************
    ;;; **************************

    ;;;; now put in the structure and return

    ;;; where the data are/will be
    path = 'data/' + telescope + '/'
    raw_path = path + 'raw/'
    processed_path = path + 'proc/'

    this_case = {telescope:telescope, $
                 raw_path:raw_path+archive_location+data_suffix, $
                 processed_path:processed_path+filename, $
                 filename:filename, $
                 n:n, $
                 n_dm:n_dm, $
                 l_dm:0, $
                 h_dm:n - 1, $
                 datatype:datatype, $
                 rate:rate, $
                 d:d, $
                 problems:problems, $
                 pupil_remap:pupil_remap, $
                 read_method:read_method, $
                 data_suffix:data_suffix, $
                 data_dim:data_dim, $
                 scaling_for_nm_phase:scaling_for_nm_phase, $
                 dmtrans_mulfac:dmtrans_mulfac, $
                 gain:gain, $
                 integrator_c:integrator_c, $
                 tau:tau, $
                 seed:seed, $
                 len:len, $
                 pingrid:pingrid  }
    
    if not FILE_TEST(path,/directory) then begin
        FILE_MKDIR, path
    endif
    if not FILE_TEST(raw_path,/directory) then begin
        FILE_MKDIR, raw_path
    endif
    if not FILE_TEST(processed_path,/directory) then begin
        FILE_MKDIR, processed_path
    endif
    
    return, this_case
    
end