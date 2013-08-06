pro fitter_alpha_real, x, a, f, pder

  f = a[1]/(1 - 2*a[0]*cos(x) + a[0]^2)
  
  if n_params() GE 4 then begin
     pder0 = a[1]*(-1)/(1 - 2*a[0]*cos(x) + a[0]^2)^2*(-2*cos(x) + 2*a[0])
     pder1 =        1./(1 - 2*a[0]*cos(x) + a[0]^2)
     
     pder = [[pder0], [pder1]]
  endif
end
