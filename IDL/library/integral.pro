;+
;  integral.pro - compute the running integral of data
;   USAGE:
;    res = integral(data)*dx
;
;-
function integral,data
  n = (size(data))(1)
  res = fltarr(n)
  res[0] = data[0]
  for i=1,n-1 do begin
    res[i] = res[i-1] + data[i]
  endfor
  return,res
end
