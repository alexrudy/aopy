;; Written by Lisa A. Poyneer
;;; This is where you hardcode the details of all of the data 
;;; that you hav received.

;;; Identifier is a long that tells us which to select
;;; function returns a struct which has all of the relevant details

function get_case_altair, identifier, bytag=bflag

  ;; The following are always the same for Altair (I think)
  ;;; set them once

  telescope = 'altair'

  read_method = 'fits'  ;;; sometimes not - set as appropriate
  data_suffix = '.fits' ;;; sometimes not - set as appropriate
  problems = 0          ;;; sometimes not:  set to 1 if problems

  data_dim='2D'
  pupil_remap = 'locations'

  ;; how to do the pupil remapping!
  n = 16
  mask = readfits('data/altair/altairMaskValidSubap.fits',/sil)
  bsub = reform(mask, 19, 19)
  subapmask = bsub[1:16, 1:16]
  pingrid = (subapmask + shift(subapmask,1,0) $
             + shift(subapmask,0,1) + shift(subapmask,1,1) ) GE 1.0
  pingrid[n/2, n/2] = 1

  rows =    [5,9,11,11,13,13,13,13,13,11,11,9,5]
  padding = [7,3, 2, 2, 2, 2, 2, 2, 2, 2, 2,2,3]
  locations = make_array(total(rows))
  start_loc = 0.
  num_start_loc = 0.
  for j=0, n_elements(rows)-1 do begin
     num_start_loc = num_start_loc + padding[j]
     locations[start_loc:start_loc+rows[j]-1] = findgen(rows[j]) + num_start_loc
     start_loc = start_loc + rows[j]
     num_start_loc = num_start_loc + rows[j]
  endfor

  indices = locations*0.
  cntr = 0.
  for k=0, n-1 do begin
     for j=0, n-1 do begin
        if pingrid[j,k] EQ 1.0 then begin
           indices[cntr] = j + k*n
           cntr = cntr + 1
        endif
     endfor
  endfor


  ;;; what files to look at
;  datatype = 'closed-loop-residual'
  datatype = 'closed-loop-dm-commands'
;  datatype = 'open-loop-residual'


  ;;;; AO system
  rate = 1000.
  d = 7.963/12.

  ;;; from the specification
  tau = 0.8e-3
  gain = 0.6
  integrator_c = 0.998


  ;;;; basic system info - grid size and how to put in grid
  n = 16
  n_dm = 12
  l_dm = 2
  h_dm = l_dm + n_dm-1

  scaling_for_nm_phase = 1e3 ;;; actuator commands in microns -> phase in nm



  ;;; This is the influence function filter of Altair's DM.
  ;;; taken from telemetry_analysis_07/get_dm_transfer_function.pro

  m = 8
  ;; in units of meters!
  myx = rebin(findgen(n*m) - n*m/2, n*m, n*m)*d/m
  myy = transpose(myx)

  thisx = myx/d*15.82/45
  thisy = myy/d*15.82/45

  p0 = 2.1888
  p1 = -0.1766
  p2 =  2.3127
  p3 = 14.698
  p4 = -7.6907

  thisr = sqrt(thisx^2 + thisy^2)
  expo_poly = p0 + p1*thisr + p2*thisr^2
  new_term = abs(thisx)^expo_poly + abs(thisy)^expo_poly
  influence_function = (1 + p4*new_term)*exp(-p3*new_term)

  bigtf = shift(real_part(fft(shift(influence_function, n*M/2, n*m/2)))*n^2, n*M/2, n*m/2)
  tf = shift(bigtf[n*m/2-n/2: n*m/2+n/2-1, n*m/2-n/2: n*m/2+n/2-1], n/2, n/2)
  dmtrans_mulfac = abs(tf)^2



  ;;; **************************
  ;;; **************************
  ;;; **************************
  ;;; **************************

  ;;; now for each identifier, specify the exact details


  als = [$
        '2007nov02', $
        'M1tuning_0625', $
        'M1tuning_0627', $
        'M1tuning_0628', $
        'm1_tuning03Apr08', $
        'm1_tuning04Apr08', $
        'm1_tuning0530', $
        'm1_tuning0531', $
        'm1_tuning05Apr08', $
        'm1_tuning05Mar08', $
        'm1_tuning0601', $
        'm1_tuning0603', $
        'm1_tuning0604', $
        'm1_tuning0620', $
        'm1_tuning0621', $
        'm1_tuning0622', $
        'm1_tuning0623', $
        'm1_tuning0624', $
        'm1_tuning06Apr08', $
        'm1_tuning06Mar08', $
        'm1_tuning07Apr08', $
        'm1_tuning07Mar08', $
        'm1_tuning08Mar08', $
        'm1_tuning0925', $
        'm1_tuning0926', $
        'm1_tuning0927', $
        'm1_tuning0928', $
        'm1_tuning0929', $
        'm1_tuning09Mar08', $
        'm1_tuning11Jan08', $
        'm1_tuning12Jan08', $
        'm1_tuning13Jan08', $
        'm1_tuning14Jan08', $
        'm1_tuning19Feb08', $
        'm1_tuning2007nov05', $
        'm1_tuning20Feb08', $
        'm1_tuning21Feb08', $
        'm1_tuning21Mar08', $
        'm1_tuning22Feb08', $
        'm1_tuning22Mar08', $
        'm1_tuning23Feb08', $
        'm1_tuning23Mar08', $
        'm1_tuning23Nov07', $
        'm1_tuning24Feb08', $
        'm1_tuning24Mar08', $
        'm1_tuning24Nov07', $
        'm1_tuning25Nov07', $
        'm1_tuning26Feb08', $
        'm1_tuning30Jan08', $
        'm1_tuningAug0107', $
        'm1_tuningAug0207', $
        'm1_tuningAug0307', $
        'm1_tuningAug0407', $
        'm1_tuningAug0507', $
        'm1_tuningAug0607', $
        'm1_tuningAug0707', $
        'm1_tuningAug1607', $
        'm1_tuningDec26_2007', $
        'm1_tuningDec28_2007', $
        'm1_tuningNov08', $
        'm1_tuningSep0107', $
        'm1_tuningSep0107_nextnight', $
        'm1_tuningSep0207', $
        'm1_tuningSep0307', $
        'm1_tuningSep0407', $
        'm1_tuningSep0507', $
        'm1_tuning_20080326', $
        'm1_tuning_20080327', $
        'm1_tuning_2008jan18', $
        'm1_tuning_2008jan19', $
        'm1_tuning_2008jan20', $
        'm1_tuning_2008jan21', $
        'm1_tuning_aug10', $
        'm1_tuning_dec21', $
        'm1_tuning_dec22', $
        'm1_tuning_jan22', $
        'm1_tuning_oct01', $
        'm1_tuning_oct02', $
        'm1_tuning_oct03', $
        'm1_tuning_oct04', $
        'm1_tuning_oct05', $
        'm1_tuning_oct06', $
        'm1_tuning_oct07', $
        'm1_tuning_oct08', $
        'm1_tuning_oct09', $
        'm1_tuning_oct10', $
        'm1_tuning_oct15', $
        'm1_tuning_oct16', $
        'm1_tuning_oct17', $
        'm1_tuning_oct17el52', $
        'm1_tuning_oct17pt2', $
        'm1_tuning_oct18', $
        'm1_tuning_oct19', $
        'm1_tuning_sept30', $
        'm1_tuningdec25', $
        'm1_tuningfeb10', $
        'm1_tuningfeb11', $
        'm1_tuningfeb12', $
        'm1_tuningfeb13', $
        'm1_tuningfeb29', $
        'm1_tuningmar01', $
        'm1_tuningmar02', $
        'm1_tuningmar04', $
        'm1_tuningmar15', $
        'm1_tuningmar16', $
        'm1_tuningmar18', $
        'm1_tuningmar19', $
        'm1_tuningnov14', $
        'm1_tuningnov16', $
        'm1_tuningnov17', $
        'm1_tuningsept06', $
        'm1_tuningsept09', $
        'm1_tuningsept10', $
        'm1_tuningsept15', $
        'm1tuing_20080329', $
        'm1tuning_27Feb2008', $
        'm1tuning_apr17']


  fns = [$
        '20071102', $
        '20070625', $
        '20070627', $
        '20070628', $
        '20080403', $
        '20080404', $
        '20070530', $
        '20070531', $
        '20080405', $
        '20080305', $
        '20070601', $
        '20070603', $
        '20070604', $
        '20070620', $
        '20070621', $
        '20070622', $
        '20070623', $
        '20070624', $
        '20080406', $
        '20080306', $
        '20080407', $
        '20080307', $
        '20080308', $
        '20070925', $
        '20070926', $
        '20070927', $
        '20070928', $
        '20070929', $
        '20080309', $
        '20080111', $
        '20080112', $
        '20080113', $
        '20080114', $
        '20080219', $
        '20071105', $
        '20080220', $
        '20080221', $
        '20080321', $
        '20080222', $
        '20080322', $
        '20080223', $
        '20080323', $
        '20071123', $
        '20080224', $
        '20080324', $
        '20071124', $
        '20071125', $
        '20080226', $
        '20080130', $
        '20070801', $
        '20070802', $
        '20070803', $
        '20070804', $
        '20070805', $
        '20070806', $
        '20070807', $
        '20070816', $
        '20071226', $
        '20071228', $
        '20071108', $
        '20070901', $
        '20070901_nextnight', $
        '20070902', $
        '20070903', $
        '20070904', $
        '20070905', $
        '20080326', $
        '20080327', $
        '20080118', $
        '20080119', $
        '20080120', $
        '20080121', $
        '20070810', $
        '20071221', $
        '20071222', $
        '20080122', $
        '20071001', $
        '20071002', $
        '20071003', $
        '20071004', $
        '20071005', $
        '20071006', $
        '20071007', $
        '20071008', $
        '20071009', $
        '20071010', $
        '20071015', $
        '20071016', $
        '20071017', $
        '20071017el52', $
        '20071017pt2', $
        '20071018', $
        '20071019', $
        '20070930', $
        '20071225', $
        '20080210', $
        '20080211', $
        '20080212', $
        '20080213', $
        '20080229', $
        '20080301', $
        '20080302', $
        '20080304', $
        '20080315', $
        '20080316', $
        '20080318', $
        '20080319', $
        '20071114', $
        '20071116', $
        '20071117', $
        '20070906', $
        '20070909', $
        '20070910', $
        '20070915', $
        '20080329', $
        '20080227', $
        '20070417']


  ord = sort(fns)
  fns = fns[ord]
  als = als[ord]

  if keyword_set(bflag) then begin
     matches = strcmp(bflag, fns)
     if total(matches) EQ 1 then begin
        identifier = where(matches EQ 1)
        print, 'Using identifier ', identifier
     endif else begin
        print, 'PROBLEM! No identified matches your tag'
        print, bflag
        stop
     endelse
  endif


  if identifier LT 0 then begin
     print, 'invalid identifier!'
     stop
  endif
  if identifier GE n_elements(als) then begin
     print, 'invalid identifier!'
     stop
  endif

  archive_location = als[identifier]+'_actV'
  filename = fns[identifier]




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
               indices:indices, $
               locations:locations, $
               dmtrans_mulfac:dmtrans_mulfac, $
               gain:gain, $
               integrator_c:integrator_c, $
               tau:tau}


  return, this_case


end
