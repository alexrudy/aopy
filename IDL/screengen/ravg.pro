;
; ravg2.pro - radial average
;
function ravg,a
  n = (size(a))[1]
  pa = topolar(a)
  ra = total(pa,2)/float((size(pa))[2])
return, ra
end
