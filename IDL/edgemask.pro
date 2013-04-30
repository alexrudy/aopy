
function edgemask,apa,actinnerlocs
	na = (size(apa))[1]
	a = fltarr(na,na)
	for i=1,na-2 do begin
		for j=1,na-2 do begin
			if (apa[i-1,j] and apa[i,j-1] and apa[i+1,j] and apa[i,j+1] and apa[i,j] and apa[i+1,j+1] $
				and apa[i+1,j-1] and apa[i-1,j+1] and apa[i-1,j-1]) then a[i,j] = 1
		endfor
	endfor
	a[0,*] = fltarr(1,na)
	a[*,0] = fltarr(na,1)
	a[na-1,*] = fltarr(1,na)
	a[*,na-1] = fltarr(na,1)
	actinnerlocs = where(a eq 1)
	return,a
end

function twoD,data,n,locs
  a = fltarr(n,n)
  a[locs] = data
  return,a
end

function fillmatrix,actveclocs,fillactveclocs,fillveclocs,n
	na = (size(actveclocs))[1]
	a = fltarr(na)
	for i=0,na-2 do begin
		if (actveclocs[i+1] ne (actveclocs[i]+1)) then a[i] = 1 else a[i] = 0
	endfor
	a[na-1] = 1
	fillactveclocs = where(a eq 1)
	a = twod(a,n,actveclocs)
	fillveclocs = where(a eq 1)
	return,a
end

function hMatrix,ap,actVecLocs,sensVecLocs
  m = (size(ap))[1] ; number of sensor across square grid
  n = m+1 ; sensors are inside actuators
  H = fltarr(n,n,m,m,2)
  for i=0,m-1 do begin
    for j=0,m-1 do begin
      H[i,j,i,j,0] = -0.5;     --- x ----
      H[i+1,j,i,j,0] = 0.5
      H[i,j+1,i,j,0] = -0.5
      H[i+1,j+1,i,j,0] = 0.5
      H[i,j,i,j,1] = -0.5;    ---- y ----
      H[i+1,j,i,j,1] = -0.5
      H[i,j+1,i,j,1] = 0.5
      H[i+1,j+1,i,j,1] = 0.5
    endfor
  endfor
  H2 = reform(H,n^2,2*m^2)
	H=0
  sensVecLocs = where(ap eq 1)
  ns = (size(sensVecLocs))[1]
  sensVecLocs = [sensVecLocs,sensVecLocs+m^2]
  H3 = H2[*,sensVecLocs]
  H2=0
  actFinder = total(abs(H3),2)
  actVecLocs = where(actFinder gt 0)
  H3 = H3[actVecLocs,*]
  H3=0;don't really need the H matrix here for this code
  return,double(H3)
end