;; CVS header information for IDL files
;; $Revision: 1.5 $
;; $Author: poyneer1 $
;; $Date: 2008/11/11 19:26:15 $


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

;;; This function returns the centroid (in pixels) given
;;; the spot image ref. It assumes ref is square. There can
;;; be an even or odd number of pixels across the spot.

function my_centroid, ref, weight=wflag, denomfree=dlevel


;; find center of mass of ref
dims = size(ref)
N = dims[1]

if keyword_set(wflag) then begin
    dims1 = size(wflag)
    if ((dims[0] NE dims1[0]) $
        and (dims[1] NE dims1[1])) and $
      (dims[2] NE dims1[2]) then begin
        print, 'in my_centroid!'
        print, 'Weighting is not the right size'
    endif
    ref2use = ref*wflag
endif else begin
    ref2use = ref
endelse



datatype=size(ref2use, /type)
if datatype eq 5 then usedouble=1

xind = rebin(findgen(N), N, N)
xind = xind - total(xind)/n^2
yind = transpose(xind)

area = total(ref2use)

if keyword_set(dlevel) then begin
    if dlevel LE 0 then begin
        print, 'in my_centroid!'
        print, 'denominator-free threshold must be gretaer than 1'       
    endif
    if area LT dlevel then area = dlevel
endif 
xres = total(ref2use*xind)/area
yres = total(ref2use*yind)/area

return, [xres, yres]

end
