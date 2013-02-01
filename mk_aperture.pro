;; CVS header information for IDL files
;; $Revision: 1.6 $
;; $Author: poyneer1 $
;; $Date: 2008/11/11 19:25:23 $


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

;;; latest version: 16 Sept 2003
;;; Lisa Poyneer at LLNL

;;; Part of a family of mk_*.pro functions that
;;; produce maskes for apertures, windowing, etc.
;;; Prodcues a NxN signal.

;;; This one produces a circular  aperture of radius R.


FUNCTION mk_aperture,N,R, whole=wflag, old=oflag, double=doubleflag
  if keyword_set(wflag) then begin
     xind = rebin(findgen(n) - n/2, n, n)
     yind = transpose(xind)
  endif else begin
     xind = rebin(findgen(n) - (n-1)/2, n, n)
     yind = transpose(xind)
  endelse

  rind = sqrt(xind^2 + yind^2)
  pin = rind LE r
  if keyword_set(dflag) then pin = double(pin) else pin = float(pin)
  return, pin

END
