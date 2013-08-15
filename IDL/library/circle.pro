;+
;  circle.pro - generate a filled circle
;
;   result = circle(n,m, cx,cy, radius,value,[/grey])
;
;    use the /grey flag to compute the grey pixel values on the circle boundary
;-
function circle, n,m, cx,cy, radius, value, grey=grey
  if n_elements(value) eq 0 then value = 1
  x = extend(indgen(n),0,m)
  y = extend(indgen(m),1,n)
  r = sqrt((x-cx)^2 + (y-cy)^2)
  rbar = r/radius
  a0 = (rbar lt 1.0)*value
  if (keyword_set(grey)) then begin
    set = where((rbar ge 1.-2./radius) and (rbar le 1.+2./radius))
  	if ((size(set))[0] ne 0) then begin
  	
    	nb = (size(set))[1]
    	subsize = 10
    	for k = 0,nb-1 do begin
    	  x0 = x[set[k]]
    	  y0 = y[set[k]]
    	  xs = (ones(subsize) ## findgen(subsize))/float(subsize) + x0 - 0.5
    	  ys = (findgen(subsize) ## ones(subsize))/float(subsize) + y0 - 0.5
    	  rs = sqrt((xs-cx)^2 + (ys-cy)^2)
    	  rsbar = rs/radius
    	  as0 = (rsbar lt 1.0)*value
    	  v = total(as0)/float(subsize)^2
    	  a0[set[k]] = v
    	endfor
  	
  	endif
  endif
  return,a0
end
;
n = 128
a = circle(n,n,n/2,n/2,n/10.,1.0,/grey)
b = circle(n,n,n/2,n/2,n/10.,1.0)
disp,alog10(abs(ft(a))>1.e-6),'grey pixel'
disp,alog10(abs(ft(b))>1.e-6),'on off pixel'
end
