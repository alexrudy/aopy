;; Lisa's version, based on Documentation from GEMS.
@mk_aperture
function gems_phase_mapping, data, dm_number

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
     res[*,*,t] = thisframe
  endfor

  return, res

end
