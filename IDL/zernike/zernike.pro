;+
;  zernike.pro - zernike modes
;       result = zernike(nx,ny,r,n,m)  - generate the zernike mode
;                                       on a 2-D (nx X ny) image
;       result = zernike(x,y,r,n,m)  - generate the zernike mode values
;                                      at positions given by vectors x and y
;          tab = ztable(nmax)  - generate a table of allowed n,m pairs
;
;   INPUTS
;         nx,ny - dimensions of image -or-
;          x,y  - arrays of x and y coordinates
;           r   - radius of aperture in pixels
;         n,m   - zernike indices, n-radial, m-angular`
;   OUTPUT
;         res - returned as a complex pair
;              real part = z(n,m) cos(m theta)
;             imaginary part = z(n,m) sin(m theta)
;
;   UNITS
;         the result of zernike is unintless, and normalized according to Noll normalization formula
;           Noll, R J., Zernike polynomials and atmospheric turbulence.Journal of the Optical Society of America 66, no. 3 (1976): 207-211.
;         The Noll Zernike polynomials are orthogonal over the unit radius circle and square-integrate to pi (the area of a unit radius circle)
;         
;         The zernike slope is in units of (circle radius)^-1
;-

function zernikeFourier,kxa,kya,r,n,m
; k units are (circle radius)^-1
; first two arguments can be array dimension of result
; r units are pixels
  i = complex(0.,1.)
  fuzz = 1.e-8
  
  kx = kxa
  ky = kya
  if (n_elements(kx) eq 1) then begin
    nx = kx
    ny = ky
    kx = (ones(ny) ## findgen(nx)-nx/2)*float(r)/float(nx)
    ky = (findgen(ny) ## ones(nx)-ny/2)*float(r)/float(ny)
  endif
  k = sqrt(kx^2+ky^2)
  k[nx/2,ny/2] = fuzz
  phi = atan(ky,kx)
  q = sqrt(n+1)*(beselj(2*!pi*k,n+1,/double)/(!pi*k))*(-1)^((n-m)/2)*i^m
  if (m gt 0) then q *= sqrt(2.)*cos(m*phi)
  if (m lt 0) then q *= sqrt(2.)*sin(m*phi)
  return,q    
end

function calcSample,n,m,a,crit=crit,sm=sm,pc=pc
; This function recommends a setting for the grid sameple, given the Zernike index and aberration strength
; The sample is set so that the maximum differential pixel to pixel would be less than 1 radian (option to set this with keyword crit)
; The return value is the number of pixels across the unit circle
  forward_function zernikeslope
  if (n_elements(crit) eq 0) then crit = 1. 
  if (n_elements(pc) eq 0) then pc = 1.
  nn = min([4*n,100])
  r = nn/2
  ap = circle(nn,nn,nn/2,nn/2,r,1.)
  s = real(zernikeslope(nn,nn,r,n,m))
  sm = (abs(s[0:nn-1,*]*ap) > abs(s[nn:2*nn-1,*]*ap))*2*2*!pi*a/crit
  sma = sm[where(ap eq 1.)]
  h = histogram(sma,locations=hx)
  hi = integral(h)
  hi /= max(hi)
  index = value_locate(hi,pc)
  rn = hx[index]
  return,rn
end

function zernikeslope,xa,ya,r,n,m,center=c
; x, y, r units are pixels
  x = xa
  y = ya
  if (n_elements(x) eq 1) then begin
    nx = x
    ny = y
    if (n_elements(c) eq 0) then begin
      c = [nx/2.,ny/2.]
    endif
    x = make_array(1,ny,/float,value=1) ## (real(indgen(nx)-c[0]))
    y = transpose(real(indgen(ny)-c[1])) ## make_array(nx,1,/float,value=1)
  endif
  u = double(sqrt(x^2 + y^2)/r)
  pr = 0*u
  prtheta = 0*u
  for s = 0,(n-m)/2 do begin
    if (n ne 2*s) then begin
      pr = pr + (-1)^s * (factorial(n-s) / factorial(s) ) / $
       (factorial((n+m)/2-s) * factorial((n-m)/2-s)) * $
            (n-2*s)*u^(n-2*s-1)
      prtheta = prtheta + (-1)^s * (factorial(n-s) / factorial(s) ) / $
       (factorial((n+m)/2-s) * factorial((n-m)/2-s)) * $
            u^(n-2*s-1)
    endif
  endfor
  th = atan(y,x)
  i = complex(0,1)
  retx = sqrt(n+1)*pr*cos(th)*(cos(m*th)+i*sin(m*th)) - $
        prtheta*sin(th)*(-m*sin(m*th)+i*m*cos(m*th))
  rety = sqrt(n+1)*pr*sin(th)*(cos(m*th)+i*sin(m*th)) + $
        prtheta*cos(th)*(-m*sin(m*th)+i*m*cos(m*th))
  ret = [retx,rety]
  if (m ne 0) then ret *= sqrt(2.)
  return,[retx,rety]
end

function ztable,kmax,noll=noll
  if (keyword_set(noll)) then begin
    tab = intarr(2,kmax)
  endif else begin
    tab = intarr(3,kmax+1)
  endelse
  klimit = (size(tab))[2]-1
  n = 0
  m = 0
  s = 0
  for k = 0, klimit do begin ; k+1 is Noll's index
    tab(0,k) = n
    tab(1,k) = m
    if (keyword_set(noll)) then begin
      if (m ne 0) then s = fix(odd(k+1))
      if (s) then tab(1,k) = -m
    endif else begin
      tab(2,k) = s
    endelse
    if (keyword_set(noll)) then begin
      if (n ne 0) and (m ne 0) then begin
        if (tab[1,k] eq -tab[1,k-1]) then m = m+2 ; update the m number if both cos and sin modes are done
      endif else begin
        m = m+2
      endelse
      if (m gt n) then begin
        n = n+1
        m = fix(odd(n))
      endif
    endif else begin
      if ((m ne 0) and (s eq 0)) then begin ; there is a sine part
        s = 1
      endif else begin
        m = m+2
        s = 0
      endelse
      if (m gt n) then begin ; cycle to the next n
        n = n+1
        if ((n/2)*2 eq n) then m = 0 else m = 1
        s = 0
      endif
    endelse
  endfor
  return,tab
end

function zernike,xa,ya,r,n,marg,center=c,l=l,table=nmax,noll=noll
; x, y, r units are pixels
  if (n_elements(nmax) ne 0) then begin
    return,ztable(nmax,noll=noll)
  endif

  m = marg
  if ((even(n) and odd(m)) or (odd(n) and even(m))) then begin
    print,'<zernike> invalid n,m pair'
    return,0
  endif
  if (keyword_set(noll)) then begin
    if (marg lt 0) then begin
      m = -marg
      l = 1
    endif else l = 0
  endif
  
  if (n_elements(l) ne 0) then begin
    if (l lt 0) then l = 0
    if (l gt 1) then l = 1
  endif
    
	x = xa
	y = ya
	if (n_elements(x) eq 1) then begin
	nx = x
	ny = y
	if (n_elements(c) eq 0) then begin
	  c = [nx/2.,ny/2.]
	endif
	x = make_array(1,ny,/float,value=1) ## (real(indgen(nx)-c[0]))
	y = transpose(real(indgen(ny)-c[1])) ## make_array(nx,1,/float,value=1)
	endif
	u = double(sqrt(x^2 + y^2)/r)
	th = atan(y,x)
	p = 0*u
	for s = 0,(n-m)/2 do $
	p = p + (-1)^s * (factorial(n-s) / factorial(s) ) / $
	   (factorial((n+m)/2-s) * factorial((n-m)/2-s)) * $
	        u^(n-2*s)
	fuzz = 1e-8

	if (n_elements(l) eq 0) then begin
		i = complex(0,1)
		ret = sqrt(n+1) * p * ( cos(m*th) + i*sin(m*th) )
	endif else begin
		if (l eq 0) then ret = sqrt(n+1)*p*cos(m*th)
		if (l eq 1) then ret = sqrt(n+1)*p*sin(m*th)
	endelse
	if (m ne 0) then ret *= sqrt(2.)
	return,ret
end

; draw a Zernike "Pascal triangle" graphic
nmax = 9 ; go up to this order
npix = 100 ; number of pixels across a circle in the graphic
nbuf = npix/5
nn = (nmax+1)*(npix+nbuf)
g = fltarr(nn,nn)
dx = (npix+nbuf)/2.
dy = npix+nbuf
kmax = ((nmax+1)*(nmax+2))/2
ztab = ztable(kmax,/noll)
ap = circle(npix,npix,npix/2,npix/2,npix/2,1.)
for k = 0,kmax-1 do begin
  n = ztab[0,k]
  m = ztab[1,k]
  x = m*dx + nn/2
  y = nn - (n*dy + npix/2)
  z = ap*zernike(npix,npix,npix/2,n,m,/noll)
  g[x-npix/2:x+npix/2-1,y-npix/2:y+npix/2-1] = z
endfor
disp,g,dx = [(1./dx),-(1./dy)], x0 = [-float(nmax)-1,float(nmax)+.6]
end

