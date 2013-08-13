;+
;  even.pro - check whether or not an integer is even
;-
function even,k
	kk = fix(k)
	if ((size(kk))[0] eq 0) then begin
	  return,((kk/2)*2 eq k)
	endif else begin
	  n = (size(kk))[1]
	  r = kk
	  for j=0,n-1 do begin
	  	r[j] = ((kk[j]/2)*2 eq kk[j])
	  endfor
	  return,r
	endelse
end
