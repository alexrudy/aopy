;; Lisa's version, based on Documentation from GEMS.
@mk_aperture
function gems_phase_mapping, data, dm_number, ngs=ngs

    if ~keyword_set(ngs) then ngs=0
  dims = size(data)
  if dims[0] EQ 1 then begin
     if dims[1] EQ 684 then begin
        nact = 684.
        len = 1
     endif else begin
        print, 'Your 1D vector input does not have 684 elements!'
        print, 'Aborting and returning 0.'
        return, 0.
     endelse
  endif else begin
     if dims[0] eq 2 then begin
        ;;; correct size
        if dims[1] EQ 684 then begin
           nact = 684.
           len = dims[2]
        endif else begin
           print, 'Your 2D vector input does not have 684 x N  elements!'
           print, 'Aborting and returning 0.'
           return, 0.
        endelse
     endif else begin
        print, 'Your data input is not have 684 x N frames!'
        print, 'Aborting and returning 0.'
        return, 0.
     endelse
  endelse


  ;; now we will reform the data

  if dm_number EQ 0 then begin
     n = 19.
     ap = mk_aperture(n, /whole, 8.7)
     ap[9,9] = 0.
     if ngs NE 0 then begin
         gsap = mk_aperture(n, /whole, 8.7)
         guidestars = [[n/2,n/2],[n/2,n/2],[n/2,n/2],[n/2,n/2],[n/2,n/2]]
         for i=0,(n_elements(guidestars)/2.0)-1.0 do begin
             gnap = mk_cen_aperture(n, 8.7, guidestars[i*2], guidestars[i*2+1])
             gsap = gsap + gnap
         endfor
         gss = where(gsap GE ngs)
         mask = fltarr(n,n)
         mask[gss] = 1.0
     endif else begin
         mask = fltarr(n,n) + 1.0
     endelse
     
     
     
     locs = make_array(total(ap))
     cntr = 0.
     for y=0, n-1 do begin
        for x=0, n-1 do begin
           if ap[x,y] EQ 1 then begin
              locs[cntr] = x + y*n
              cntr = cntr + 1
           endif
        endfor         
     endfor
     l = 0
     h = 238
  endif


  if dm_number EQ 1 then begin
     n = 22.
     ap = mk_aperture(n, 10.12)
     ap[2, 5] = 1.
     ap[2, 16] = 1.
     ap[19, 5] = 1.
     ap[19, 16] = 1.
     ap[5, 2] = 1.
     ap[5, 19] = 1.
     ap[16, 2] = 1.
     ap[16, 19] = 1.
     if ngs NE 0 then begin
         gsap = mk_aperture(n, /whole, 10.12)
         offset = 1.0
         guidestars = [[n/2,n/2],[n/2+offset,n/2+offset],[n/2+offset,n/2-offset],[n/2-offset,n/2+offset],[n/2-offset,n/2-offset]]
         for i=0,(n_elements(guidestars)/2.0)-1.0 do begin
             gnap = mk_cen_aperture(n, 8, guidestars[i*2], guidestars[i*2+1])
             gsap = gsap + gnap
         endfor
         gss = where(gsap GE ngs)
         mask = fltarr(n,n)
         mask[gss] = 1.0
     endif else begin
         mask = fltarr(n,n) + 1.0
     endelse
     
     locs = make_array(total(ap))
     cntr = 0.
     for y=0, n-1 do begin
        for x=n-1,0, -1 do begin
           if ap[x,y] EQ 1 then begin
              locs[cntr] = x + y*n
              cntr = cntr + 1
           endif
        endfor         
     endfor
     l = 240
     h = 563
  endif


  if dm_number EQ 2 then begin
     n = 16.
     ap = mk_aperture(n, 6.3)
     if ngs NE 0 then begin
         gsap = mk_aperture(n, /whole, 10.12)
         offset = 1.1
         guidestars = [[n/2,n/2],[n/2+offset,n/2+offset],[n/2+offset,n/2-offset],[n/2-offset,n/2+offset],[n/2-offset,n/2-offset]]
         for i=0,(n_elements(guidestars)/2.0)-1.0 do begin
             gnap = mk_cen_aperture(n, 4.2, guidestars[i*2], guidestars[(i*2)+1])
             gsap = gsap + gnap
         endfor
         gss = where(gsap GE ngs)
         mask = fltarr(n,n)
         mask[gss] = 1.0
     endif else begin
         mask = fltarr(n,n) + 1.0
     endelse
     locs = make_array(total(ap))
     cntr = 0.
     for y=0, n-1 do begin
        for x=0, n-1 do begin
           if ap[x,y] EQ 1 then begin
              locs[cntr] = x + y*n
              cntr = cntr + 1
           endif
        endfor         
     endfor
     l = 564
     h = 683
  endif


  res = make_array(n,n,len)
  for t=0, len-1 do begin
     thisframe = make_array(n,n)
     thisframe[locs] = data[l:h,t]
     res[*,*,t] = thisframe * mask
  endfor

  return, res

end
