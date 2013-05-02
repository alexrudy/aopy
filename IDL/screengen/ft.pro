function ft,a,inverse=inverse
  p = (size(a))[0]
  n = (size(a))[1]
;
;   one dimensional
  if (p eq 1) then begin
    if keyword_set(inverse) then begin
      r = shift(fft(shift(a,n/2),/inverse),n/2)
    endif else begin
      r = shift(fft(shift(a,n/2)),n/2)
    endelse
    return,r
  endif
;
;   two dimensional
  m = (size(a))[2]
  if keyword_set(inverse) then begin
    r = shift(fft(shift(a,n/2,m/2),/inverse),n/2,m/2) 
  endif else begin
    r = shift(fft(shift(a,n/2,m/2)),n/2,m/2)
  endelse
  return,r
end
