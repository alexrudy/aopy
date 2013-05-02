;+
;  depiston - remove piston over an aperture
;
;  USAGE:
;    phdp = depiston(ph,ap)
;
;  INPUTS:
;    ph - phase
;    ap - aperture
;
;  OUTPUTS:
;    phdp - phase with piston removed
;
;-
function depiston,ph,ap,piston=piston
  n = (size(ph))(1)
  m = (size(ph))(2)
  if (n_elements(ap) eq 0) then ap = ones(n,m)
  piston = total(ph*ap)/total(ap)
  phdp = ph - piston
  return,phdp
end
