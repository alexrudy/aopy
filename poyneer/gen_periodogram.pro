;; CVS header information for IDL files
;; $Revision: 1.4 $
;; $Author: poyneer1 $
;; $Date: 2008/11/11 19:26:00 $


;; ****** OFFICIAL USE ONLY ***************
;; May be exempt from public release under the 
;; Freedom of Information Act (5 U.S.C 552), 
;; exemption and category 4: Commercial.
;; 
;; ****** IMPORTANT RESTRICTIONS **********
;; This code is for strictly limited release 
;; within the Gemini Planet Imager project and 
;; may not be made publicly available. Under EAR99,
;; there are restrictions on the availability of this
;; code to foreign nationals. Please contact 
;; Lisa Poyneer <poyneer1@llnl.gov>.
;; ****************************************


;; --------------------------------------------------------
;; This work was performed under the auspices of the U.S. Department of 
;; Energy by the University of California, Lawrence Livermore National 
;; Laboratory under contract No. W-7405-Eng-48.
;; OR 
;; This work performed under the auspices of the U.S. Department of Energy 
;; by Lawrence Livermore National Laboratory under Contract DE-AC52-07NA27344.

;; Developed by Lisa A. Poyneer 2001-2008
;; No warranty is expressed or implied.
;; --------------------------------------------------------

function gen_periodogram, closedloop_data, interval_length, halfover=halfflag, meanrem=mrflag, $
                          hanning=hflag, hamming = hmflag, nowindow=nwflag

;;;; this uses a blackman window to generate an unbiased
;; (low leakage) periodogram.

;; interval length sets the number of samples per interval
;; halfover flag does half-overlapping

  total_len = n_elements(closedloop_data)
  per_len = interval_length

  if keyword_set(mrflag) then begin
     mydata = closedloop_data - total(closedloop_data)/total_len
  endif else begin
     mydata = closedloop_data
  endelse


;;;;;; now check interval length
  if keyword_set(halfflag) then begin
     num_intervals = floor(total_len/(per_len/2)) - 1
     start_indices = findgen(num_intervals)*per_len/2
  endif else begin
     num_intervals = floor(total_len/(per_len)) 
     start_indices = findgen(num_intervals)*per_len
  endelse

  ind = findgen(per_len)

  if keyword_set(nwflag) then begin
     window = make_array(per_len) + 1.
  endif else begin
     if keyword_set(hflag) then begin
        window = 0.5 - 0.5*cos(2*!pi*ind/(per_Len-1))
     endif else begin
        if keyword_set(hmflag) then begin
           window = 0.54 - 0.46*cos(2*!pi*ind/(per_Len-1))
        endif else begin
           window = 0.42 - 0.5*cos(2*!pi*ind/(per_Len-1)) + 0.08*cos(4*!pi*ind/(per_len-1))
        endelse
     endelse
  endelse


  psd = make_array(per_len)
  for a=0, num_intervals-1 do begin
     this_start = start_indices[a]
     psd = psd + $
           abs(fft(mydata[this_start:this_start+per_Len-1]*window))^2 
  endfor

  psd = psd/num_intervals
  psd = psd*per_len/total(window^2)

  return, psd

end
