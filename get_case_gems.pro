;; Written by Lisa A. Poyneer
;;; This is where you hardcode the details of all of the data 
;;; that you have received.

;;; Identifier is a long that tells us which to select
;;; function returns a struct which has all of the relevant details


;; NOTe - the GEMS data are saved in .mat files.
;; IDL can't read these in. Instead, use the free GNU Octave
;; to read these in and save them.

;; see octave script in read_gems_data.m

function get_case_gems, identifier

  ;; The following are always the same for Keck (I think)
  ;;; set them once

  telescope = 'gems'

  read_method = 'fits'        ;;; sometimes not - set as appropriate
  problems = 0                ;;; sometimes not:  set to 1 if problems

  data_dim='2D'

  ;;; what files to look at
;  datatype = 'closed-loop-residual'
;  datatype = 'open-loop-residual'

  if 0 then begin
     tau = 0.89e-3
     gain = 0.5
     integrator_c = 0.99
  endif else begin
     ;; unknown - my guesses here.
     tau = 2./250.
     gain = 0.5
     integrator_c = 0.99
  endelse


;; inherent units!
;; from the app opp paper, the surface of the mirror movies 0.409518
;; microns per volt for a single actuator


  ;;; **************************
  ;;; **************************
  ;;; **************************
  ;;; **************************

  ;;; now for each identifier, specify the exact details

  dm_number = -1
  wfs_number = -1

  case identifier of
     10: begin
        datatype = 'closed-loop-dm-commands'
        pupil_remap = 'gems-custom-dm'
        archive_location = 'phf11109092452'
        filename = '11109092452_dm0'
        rate = 400. ;;; should really do this automatically from the files....
        dm_number = 0
     end
     11: begin
        datatype = 'closed-loop-dm-commands'
        pupil_remap = 'gems-custom-dm'
        archive_location = 'phf11109092452'
        filename = '11109092452_dm1'
        rate = 400. ;;; should really do this automatically from the files....
        dm_number = 1
     end
     12: begin
        datatype = 'closed-loop-dm-commands'
        pupil_remap = 'gems-custom-dm'
        archive_location = 'phf11109092452'
        filename = '11109092452_dm2'
        rate = 400. ;;; should really do this automatically from the files....
        dm_number = 2
     end

     15: begin
        datatype = 'closed-loop-slopes'
        pupil_remap = 'gems-custom-wfs'
        archive_location = 'slp11109092452'
        filename = '11109092452_wfs0'
        rate = 400. ;;; should really do this automatically from the files....
        wfs_number = 0
     end
     16: begin
        datatype = 'closed-loop-slopes'
        pupil_remap = 'gems-custom-wfs'
        archive_location = 'slp11109092452'
        filename = '11109092452_wfs1'
        rate = 400. ;;; should really do this automatically from the files....
        wfs_number = 1
     end
     17: begin
        datatype = 'closed-loop-slopes'
        pupil_remap = 'gems-custom-wfs'
        archive_location = 'slp11109092452'
        filename = '11109092452_wfs2'
        rate = 400. ;;; should really do this automatically from the files....
        wfs_number = 2
     end
     18: begin
        datatype = 'closed-loop-slopes'
        pupil_remap = 'gems-custom-wfs'
        archive_location = 'slp11109092452'
        filename = '11109092452_wfs3'
        rate = 400. ;;; should really do this automatically from the files....
        wfs_number = 3
     end
     19: begin
        datatype = 'closed-loop-slopes'
        pupil_remap = 'gems-custom-wfs'
        archive_location = 'slp11109092452'
        filename = '11109092452_wfs4'
        rate = 400. ;;; should really do this automatically from the files....
        wfs_number = 4
     end


     20: begin
        datatype = 'closed-loop-dm-commands'
        pupil_remap = 'gems-custom-dm'
        archive_location = 'phf11106030531'
        filename = '11106030531_dm0'
        rate = 400. ;;; should really do this automatically from the files....
        dm_number = 0
     end
     21: begin
        datatype = 'closed-loop-dm-commands'
        pupil_remap = 'gems-custom-dm'
        archive_location = 'phf11106030531'
        filename = '11106030531_dm1'
        rate = 400. ;;; should really do this automatically from the files....
        dm_number = 1
     end
     22: begin
        datatype = 'closed-loop-dm-commands'
        pupil_remap = 'gems-custom-dm'
        archive_location = 'phf11106030531'
        filename = '11106030531_dm2'
        rate = 400. ;;; should really do this automatically from the files....
        dm_number = 2
     end

     25: begin
        datatype = 'closed-loop-slopes'
        pupil_remap = 'gems-custom-wfs'
        archive_location = 'slp11106030531'
        filename = '11106030531_wfs0'
        rate = 400. ;;; should really do this automatically from the files....
        wfs_number = 0
     end
     26: begin
        datatype = 'closed-loop-slopes'
        pupil_remap = 'gems-custom-wfs'
        archive_location = 'slp11106030531'
        filename = '11106030531_wfs1'
        rate = 400. ;;; should really do this automatically from the files....
        wfs_number = 1
     end
     27: begin
        datatype = 'closed-loop-slopes'
        pupil_remap = 'gems-custom-wfs'
        archive_location = 'slp11106030531'
        filename = '11106030531_wfs2'
        rate = 400. ;;; should really do this automatically from the files....
        wfs_number = 2
     end
     28: begin
        datatype = 'closed-loop-slopes'
        pupil_remap = 'gems-custom-wfs'
        archive_location = 'slp11106030531'
        filename = '11106030531_wfs3'
        rate = 400. ;;; should really do this automatically from the files....
        wfs_number = 3
     end
     29: begin
        datatype = 'closed-loop-slopes'
        pupil_remap = 'gems-custom-wfs'
        archive_location = 'slp11106030531'
        filename = '11106030531_wfs4'
        rate = 400. ;;; should really do this automatically from the files....
        wfs_number = 4
     end


  endcase

  if strcmp(datatype, 'closed-loop-dm-commands') then begin
     data_suffix = '_phase.fits' ;;; sometimes not - set as appropriate
     scaling_for_nm_phase = 1e3  ;;; are in microns to begin with
  endif

  if strcmp(datatype, 'closed-loop-slopes') then begin
     data_suffix = '_slopes.fits' ;;; sometimes not - set as appropriate

     ;;;; this is totally made up - get from arcsec to nm
     scaling_for_nm_phase = 1e-2
  endif
  ;;;; AO system


  ;;;; basic system info - grid size and how to put in grid
  if dm_number eq 0 then begin
     d = 7.9/16. ;; from dm0.png
     n = 22.
     n_dm = 19.
     l_dm = 1
  endif

  if dm_number eq 1 then begin
     d = 7.9/15.  ;; best guess from dm4.5.png
     n = 24.
     n_dm = 22.
     l_dm = 1
  endif

  if dm_number eq 2 then begin
     d = 7.9/7.  ;; best guess from dm9.png
     n = 16.
     n_dm = 16.
     l_dm = 0
  endif

  if wfs_number GE 0 then begin
     d = 7.9/16. ;;; my guess
     n = 20.
     n_dm = 20.
     l_dm = 0.
  endif


  h_dm = l_dm + n_dm-1

  if 0 then begin
  ;;; This is the influence function filter of keck's DM.
  ;;; taken from telemetry_analysis_07/get_dm_transfer_function.pro
     w1 = 2
     w2 = -1
     sig1 = 0.54
     sig2 = 0.85
;    kfac = 0.47
     kfac = 1. ;;; already folded in the get_processed_data_keck
     m = 8.
     myx = rebin(findgen(n*m) - n*m/2, n*m, n*m)*1./m
     myy = transpose(myx)
     influence_function = kfac*(w1/(2*!pi*sig1^2)*exp(-0.5*(myx^2 + myy^2)/sig1^2) + $
                                w2/(2*!pi*sig2^2)*exp(-0.5*(myx^2 + myy^2)/sig2^2))
     
     bigtf = shift(real_part(fft(shift(influence_function, n*M/2, n*m/2)))*n^2, n*M/2, n*m/2)
     tf = shift(bigtf[n*m/2-n/2: n*m/2+n/2-1, n*m/2-n/2: n*m/2+n/2-1], n/2, n/2)
     dmtrans_mulfac = abs(tf)^2
  endif else begin
     ;; unknown
     dmtrans_mulfac = make_array(n,n) + 1.
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
               l_dm:l_dm, $
               h_dm:h_dm, $
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
               dm_number:dm_number, $
               wfs_number:wfs_number}


  return, this_case


end
