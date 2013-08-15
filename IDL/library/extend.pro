;+
;  extend - general purpose extend dimensions routine
;
;  USAGE:
;    e = extend(vector,dimension,m)
;
;  INPUTS:
;    vector - a 1-D n-vector
;    dimension - dimension to extend
;          1: || the vector is treated as a column, replicated m columns wide
;          2: =  the vector is treated as a row and replicated m rows high
;    m - other dimension (number of replicas)
;          m is optional; if not given, m=n (size of vector)
;
;  OUTPUT:
;    an array of size m x n if dimension = 1
;                size n x m if dimension = 2
;-
function extend,vector,dimension,length
  n = n_elements(vector)
  if n_elements(length) eq 0 then m = n else m = length
  if dimension eq 1 then begin
    result = make_array(m,n)
    for i=0,m-1 do result(i,*) = vector
  endif else begin
    result = make_array(n,m)
    for i=0,m-1 do result(*,i) = vector
  endelse
  return,result
end
