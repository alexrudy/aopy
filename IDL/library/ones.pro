;+
;  ones.pro - return an array of all ones
;
; usage:
;    a = ones(n,m)
;
; input:
;    n = 1st dimension
;    m = 2nd dimension (optional)
;
; output:
;    a = the resulting array
;
;-
function ones,n,m
  if (n_elements(m) eq 0) then begin
    a = (fltarr(n)+1)
    return,a
  endif else begin
    a = (fltarr(n,m)+1)
    return,a
  endelse
end