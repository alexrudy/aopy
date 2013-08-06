;; CVS header information for IDL files
;; $Revision: 1.1 $
;; $Author: poyneer1 $
;; $Date: 2012/11/19 23:29:22 $

;; --------------------------------------------------------
;; This work was performed under the auspices of the U.S. Department of 
;; Energy by the University of California, Lawrence Livermore National 
;; Laboratory under contract No. W-7405-Eng-48.
;; OR 
;; This work performed under the auspices of the U.S. Department of Energy 
;; by Lawrence Livermore National Laboratory under Contract DE-AC52-07NA27344.

;; Developed by Lisa A. Poyneer 2001-2012
;; No warranty is expressed or implied.
;; --------------------------------------------------------

@generate_grids
function apply_ftr_filter, xs, ys, ideal=iflag, print=pflag
;; this generates a filter from a formula and applies it.


  dimsx = size(xs)
  if dimsx[0] NE 2 then begin
     print, 'X slopes must be 2D'
     return, -1
  endif
  if dimsx[1] NE dimsx[2] then begin
     print, 'X slopes must be square'
     return, -1
  endif


  dimsy = size(ys)
  if dimsy[0] NE 2 then begin
     print, 'Y slopes must be 2D'
     return, -1
  endif
  if dimsy[1] NE dimsy[2] then begin
     print, 'Y slopes must be square'
     return, -1
  endif
  if dimsx[1] NE dimsy[1] then begin
     print, 'Y slopes must be same size as X slopes'
     return, -1
  endif

  n = dimsx[1]*1.


  ;; make the filter frequency arrays
  generate_grids, fx, fy, n, /freqs, scale=2*!pi/n


  ;; still trying to sort this out 19-Nov-2012
  ;;; why does Ideal need a conjugate on gx but mod-hud does not?

  if keyword_set(iflag) then begin

     gx = conj(1./fy*((cos(fy) - 1)*sin(fx) + (cos(fx) - 1)*sin(fy)) + $
               complex(0., 1.)*1./fy*((cos(fx) - 1)*(cos(fy) - 1) - sin(fx)*sin(fy)))
     gy = conj(1./fx*((cos(fx) - 1)*sin(fy) + (cos(fy) - 1)*sin(fx)) + $
               complex(0., 1.)*1./fx*((cos(fy) - 1)*(cos(fx) - 1) - sin(fy)*sin(fx)))

     ;;;;; division by zero!
     gx[*,0] = 0.
     gy[0,*] = 0.

     ;;; the filter is anti-Hermitian here. The real_part takes care
     ;;; of it, but simpler to just zero it out.
     gx[*,n/2] = 0.
     gy[n/2,*] = 0.


  endif else begin
;;; the mod-hud filter

     gx = complexmp(1., fy/2.)*(complexmp(1., fx) - 1.)
     gy = complexmp(1., fx/2.)*(complexmp(1., fy) - 1.)

     ;;; the filter is anti-Hermitian here. The real_part takes care
     ;;; of it, but simpler to just zero it out.
     gx[*,n/2] = 0.
     gy[n/2,*] = 0.

  endelse
  denom = abs(gx)^2 + abs(gy)^2
  ;;;;; prevent division by zero
  zl = where(denom EQ 0., numz)
  if numz GT 0 then $
     denom[zl] = 1.

  xs_ft = fft(xs)
  ys_ft = fft(ys)
  est_ft = (conj(gx)*xs_ft + conj(gy)*ys_ft)/denom

  est = real_part(fft(est_ft, 1))
  return, est

end

