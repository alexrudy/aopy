;shift wavefront:
;this will take an input wavefront, shift it by shift_vec using the method specified
;then replace the edge pixels with their unshifted values and return the shifted image
;cubic is the cubic interpolation parameter to use
function shift_wavefront_sub,wf,shift_vec,method,cubic,NOMASK=NOMASK
  if method eq 'cubic' and n_elements(cubic) eq 0 then cubic = -0.5
  n = (size(wf,/dimensions))[0]
  m = (size(wf,/dimensions))[1]
  aplocs = where(wf ne 0)
  ap = fltarr(n,m)
  if total(aplocs ne -1) gt 0 then ap[aplocs]=1
  case method of
    'linear': begin
      ix = findgen(n)-shift_vec[0]
      iy = findgen(m)-shift_vec[1]
      wf_shift = interpolate(wf,ix,iy,/grid)
    end
    
    'cubic': begin
      ix = findgen(n)-shift_vec[0]
      iy = findgen(m)-shift_vec[1]
      wf_shift = interpolate(wf,ix,iy,/grid,cubic=cubic)
    end
    
    'shannon': begin
      wf_shift = fshift(wf,shift_vec[0],shift_vec[1])
    end
    
    else: print,'SHIFT_WAVEFRONT ERROR: invalid shift method'
  endcase
  if ~keyword_set(NOMASK) then begin
    if method eq 'shannon' then begin
      ix = findgen(n)-shift_vec[0]
      iy = findgen(m)-shift_vec[1]
    endif
    ap_shift = interpolate(ap,ix,iy,/grid,missing=0)
    fill_locs = where((ap_shift-ap) lt 0)
    if total(fill_locs ne -1) gt 0 then wf_shift[fill_locs] = wf[fill_locs]
  endif 
  wf_shift *= ap
  return,wf_shift
end

function shift_wavefront,wf,shift_vec,method,cubic,NOMASK=NOMASK
  n = (size(wf,/dimensions))[0]
  m = (size(wf,/dimensions))[1]
  if n eq m and keyword_set(nomask) then wf_shift = shift_wavefront_sub(wf,shift_vec,method,cubic,/NOMASK)
  if n eq m and ~keyword_set(nomask) then wf_shift = shift_wavefront_sub(wf,shift_vec,method,cubic)
  if 2*n eq m and keyword_set(NOMASK) then begin
    wf1 = wf[*,0:n-1]
    wf2 = wf[*,n:2*n-1]
    wf1_shift = shift_wavefront_sub(wf1,shift_vec,method,cubic,/NOMASK)
    wf2_shift = shift_wavefront_sub(wf2,shift_vec,method,cubic,/NOMASK)
    wf_shift = [[wf1_shift],[wf2_shift]]
  endif
  if 2*n eq m and ~keyword_set(NOMASK) then begin
    wf1 = wf[*,0:n-1]
    wf2 = wf[*,n:2*n-1]
    wf1_shift = shift_wavefront_sub(wf1,shift_vec,method,cubic)
    wf2_shift = shift_wavefront_sub(wf2,shift_vec,method,cubic)
    wf_shift = [[wf1_shift],[wf2_shift]]
  endif
  return,wf_shift
end
    