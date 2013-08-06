;; Written by Lisa A. Poyneer
;;; This is where you hardcode the details of all of the data 
;;; that you have received.

;;; Identifier is a long that tells us which to select
;;; function returns a struct which has all of the relevant details

function get_case_keck, identifier

  ;; The following are always the same for Keck (I think)
  ;;; set them once

  telescope = 'keck'

  read_method = 'restore-trs' ;;; sometimes not - set as appropriate
  data_suffix = '.dat'        ;;; sometimes not - set as appropriate
  problems = 0                ;;; sometimes not:  set to 1 if problems

  data_dim='2D'
  pupil_remap = 'disp2d'


  ;;; what files to look at
;  datatype = 'closed-loop-residual'
  datatype = 'closed-loop-dm-commands'
;  datatype = 'open-loop-residual'


  ;;;; AO system
  rate = 1054.
  d = 0.56 ;; 56 cm subaps

  tau = 0.89e-3
  gain = 0.5
  integrator_c = 0.99

  ;;;; basic system info - grid size and how to put in grid
  n = 26
  n_dm = 21
  l_dm = 2
  h_dm = l_dm + n_dm-1

;; inherent units!
;; from the app opp paper, the surface of the mirror movies 0.409518
;; microns per volt for a single actuator
  scaling_for_nm_phase = 0.47*1e3 ;;; actuator commands in volt - > nm of phase


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


  ;;; **************************
  ;;; **************************
  ;;; **************************
  ;;; **************************

  ;;; now for each identifier, specify the exact details

  case identifier of
     0: begin
        archive_location = 'data_30jul07/dataset2'
        filename = '20070730_2'
     end
  endcase



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
               tau:tau}


  return, this_case


end
