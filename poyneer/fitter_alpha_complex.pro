pro fitter_alpha_complex, x, a, f, pder

  f =             a[2]/(1 - 2*a[0]*cos(x-a[1]) + a[0]^2)
  
  if n_params() GE 4 then begin
     pder0 = a[2]*(-1)/(1 - 2*a[0]*cos(x-a[1]) + a[0]^2)^2*(-2*cos(x-a[1]) + 2*a[0])
     pder1 = a[2]*(-1)/(1 - 2*a[0]*cos(x-a[1]) + a[0]^2)^2*(-2*a[0]*sin(x-a[1]))
     pder2 =        1./(1 - 2*a[0]*cos(x-a[1]) + a[0]^2)
     
     pder = [[pder0], [pder1], [pder2]]
  endif
end
