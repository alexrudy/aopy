pro fitter_all_together, x, a, f, pder
  
;; does up to five peaks
  foo = n_elements(a)
  max_n_lay = (foo-2)/3.

  f =            a[1]/(1 - 2*a[0]*cos(x) + a[0]^2)
  for n=0, max_n_lay-1 do $
     f = f + a[2+2+3*n]/(1 - 2*a[2+0+3*n]*cos(x-a[2+1+3*n]) + a[2+0+3*n]^2)
  
  if n_params() GE 4 then begin
     pder0 = a[1]*(-1)/(1 - 2*a[0]*cos(x) + a[0]^2)^2*(-2*cos(x) + 2*a[0])
     pder1 =        1./(1 - 2*a[0]*cos(x) + a[0]^2)

     pder = [[pder0], [pder1]]
     for n=0, max_n_lay-1 do begin
        pder2 = a[2+2+3*n]*(-1)/(1 - 2*a[2+0+3*n]*cos(x-a[2+1+3*n]) + a[2+0+3*n]^2)^2*(-2*cos(x-a[2+1+3*n]) + 2*a[2+0+3*n])
        pder3 = a[2+2+3*n]*(-1)/(1 - 2*a[2+0+3*n]*cos(x-a[2+1+3*n]) + a[2+0+3*n]^2)^2*(-2*a[2+0+3*n]*sin(x-a[2+1+3*n]))
        pder4 =        1./(1 - 2*a[2+0+3*n]*cos(x-a[2+1+3*n]) + a[2+0+3*n]^2)
        pder = [[pder], [pder2], [pder3], [pder4]]
     endfor     
  endif
end
