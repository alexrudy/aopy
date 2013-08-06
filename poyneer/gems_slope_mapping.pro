;; Lisa's version, based on Documentation from GEMS.
;; This reconstructs slopes to phase
@slope_management
@apply_ftr_filter
@mk_aperture
function gems_slope_mapping, data, wfs_number, mask=mask, getmask=getmaskflag, stop=stopflag

  dims = size(data)
  if dims[0] EQ 1 then begin
     if dims[1] EQ 2040 then begin
        nact = 2040.
        len = 1
     endif else begin
        print, 'Your 1D vector input does not have 2040 elements!'
        print, 'Aborting and returning 0.'
        return, 0.
     endelse
  endif else begin
     if dims[0] eq 2 then begin
        ;;; correct size
        if dims[1] EQ 2040 then begin
           nact = 2040.
           len = dims[2]
        endif else begin
           print, 'Your 2D vector input does not have 2040 x N  elements!'
           print, 'Aborting and returning 0.'
           return, 0.
        endelse
     endif else begin
        print, 'Your data input is not have 2040 x N frames!'
        print, 'Aborting and returning 0.'
        return, 0.
     endelse
  endelse


  ;; now we will reform the data

  n = 20.
  ap = mk_aperture(n, 8)
  ap[9:10,9:10] = 0.
  
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

  nslope = 204
  xl = nslope*wfs_number
  xh = xl + nslope - 1
  yl = nslope*5 + nslope*wfs_Number
  yh = yl + nslope - 1
  
  ;; now reassemble into the grids

  xres = make_array(n,n,len)
  yres = make_array(n,n,len)
  for t=0, len-1 do begin
     thisframe = make_array(n,n)
     thisframe[locs] = data[xl:xh,t]
     xres[*,*,t] = thisframe

     thisframe = make_array(n,n)
     thisframe[locs] = data[yl:yh,t]
     yres[*,*,t] = thisframe
  endfor


  if keyword_set(mask) then begin
     dims = size(mask)
     l = (n-dims[1])/2
     h = l + dims[1] - 1
     fullmask = make_array(n,n)
     fullmask[l:h,l:h] = mask
  endif else begin
     fullmask = make_array(n,n) + 1.
  endelse

  ;; now we have the slopes.
  ;; we need to reconstruct!
  
  subapmask =  make_array(n,n)
  subapmask[locs] = make_array(nslope) + 1.

  subapmask = subapmask*fullmask

  if keyword_set(getmaskflag) then begin
     pingrid = (subapmask + shift(subapmask,1,0) $
                + shift(subapmask,0,1) + shift(subapmask,1,1) ) GE 1.0
     if keyword_set(stopflag) then stop
     return, pingrid
  endif
  if keyword_set(stopflag) then stop

  subsum = total(subapmask)


  res = make_array(n,n,len)
  for t=0, len-1 do begin
     xs = xres[*,*,t]*subapmask
     ys = yres[*,*,t]*subapmask
     
     ;; remove piston
     xs = xs - subapmask*total(xs*subapmask)/subsum
     ys = ys - subapmask*total(ys*subapmask)/subsum

     slope_management, subapmask, xs, ys
     res[*,*,t] = apply_ftr_filter(xs, ys)
  endfor


  return, res

end
