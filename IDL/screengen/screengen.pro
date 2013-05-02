;+
;  screengen.pro - generate Kolmogorov screens
;
;  USAGE:
;    screengen,f,seed,s
;    f = screengen(n,m,r0,du,[nsh,shf])  ; generates filter for subsequent calls
;    s = screengen(f,seed,[shf,du])    ; generates random screen
;
;  INPUTS:
;    n, m - screen size
;    r0 - Fried's parameter
;         "r0" can be a 2-element vector, in which case it is [r0,L0],
;         where L0 is the outer scale in the von Karman spectrum
;    du - pixel dimension
;    nsh (optional) - number of "sub-harmonic" levels.
;        This is a logarithmic sub-sampling of the spatial frequency
;        domain close to k = 0.  Since the spectrum goes as k^-11/6
;        there is considerable spectral power there.
;        Use up to nsh = 8, after that, output gets numerically poor.
;
;  OUTPUT:
;    f - Kolmogorov spectral "filter", used in screengen
;        (output from filtergen, input to screengen)
;    shf - "subharmonic" coefficients (optional)
;        (output from filtergen, input to screengen)
;    s - screen
;
;  CHANGE HISTORY
;    Dec 04 - fixed sqrt(2) over-scaling problem; added checks of structure function performance in test code section
;    Jan 05 - added outer scale (L0) argument
;    Aug 05 - fixed 2*pi scale error in k0
;-
function screengen_f,f,seed,shf,du
  n = (size(f))(1)
  m = (size(f))(2)
  i = complex(0,1)
  nn = float(n)*float(m)
  rn = randomn(seed,n,m)
  frn = ft(rn)*sqrt(nn)
  s = ft(frn*f,/inverse)
  if (n_elements(shf) ne 0) then begin
    dkx = 2*!pi/(n*du)
    dky = 2*!pi/(m*du)
    x = (findgen(n)*du) # (fltarr(m)+1)
    y = (fltarr(n)+1) # (findgen(m)*du)
    rn = complexarr(8)
    if (size(shf))(0) eq 1 then nsh = 1 else nsh = (size(shf))(2)
    for j=0,nsh-1 do begin
      rn[0:3] = (randomn(seed,4) + i*randomn(seed,4))/sqrt(2.)
      rn[7] = conj(rn[0])
      rn[6] = conj(rn[1])
      rn[5] = conj(rn[2])
      rn[4] = conj(rn[3])
      dkx = dkx/3.
      dky = dky/3.
      s = s + rn[0]*shf[0,j]*exp(i*(-dkx*x-dky*y))
      s = s + rn[1]*shf[1,j]*exp(i*(-dky*y))
      s = s + rn[2]*shf[2,j]*exp(i*(dkx*x-dky*y))
      s = s + rn[3]*shf[3,j]*exp(i*(-dkx*y))
      s = s + rn[4]*shf[4,j]*exp(i*(dkx*y))
      s = s + rn[5]*shf[5,j]*exp(i*(-dkx*x+dky*y))
      s = s + rn[6]*shf[6,j]*exp(i*(dky*y))
      s = s + rn[7]*shf[7,j]*exp(i*(dkx*x+dky*y))
    endfor
  endif
  return,real(s)
end

function screengen_fn,f,seed,shf,du,shn
  n = (size(f))(1)
  m = (size(f))(2)
  i = complex(0,1)
  nn = float(n)*float(m)
  rn = randomn(seed,n,m)
  frn = ft(rn)*sqrt(nn)
  s = ft(frn*f,/inverse)
  if (n_elements(shf) ne 0) then begin
    dkx = 2*!pi/(n*du)
    dky = 2*!pi/(m*du)
    x = (findgen(n)*du) # (fltarr(m)+1)
    y = (fltarr(n)+1) # (findgen(m)*du)
    rn = complexarr(8)
    if (size(shf))(0) eq 1 then nsh = 1 else nsh = (size(shf))(2)
    for j=0,nsh-1 do begin
      rn[0:3] = shn
      rn[7] = conj(rn[0])
      rn[6] = conj(rn[1])
      rn[5] = conj(rn[2])
      rn[4] = conj(rn[3])
      dkx = dkx/3.
      dky = dky/3.
      s = s + rn[0]*shf[0,j]*exp(i*(-dkx*x-dky*y))
      s = s + rn[1]*shf[1,j]*exp(i*(-dky*y))
      s = s + rn[2]*shf[2,j]*exp(i*(dkx*x-dky*y))
      s = s + rn[3]*shf[3,j]*exp(i*(-dkx*y))
      s = s + rn[4]*shf[4,j]*exp(i*(dkx*y))
      s = s + rn[5]*shf[5,j]*exp(i*(-dkx*x+dky*y))
      s = s + rn[6]*shf[6,j]*exp(i*(dky*y))
      s = s + rn[7]*shf[7,j]*exp(i*(dkx*x+dky*y))
    endfor
  endif
  return,real(s)
end

function filtergen,n,m,r0_arg,du,nsh,shf
  if (n_elements(nsh) eq 0) then nsh = 0
  dkx =2*!pi/(n*du)
  dky =2*!pi/(m*du)
  kx = (findgen(n)-n/2)*dkx # (fltarr(m)+1)
  ky = (fltarr(n)+1) # (findgen(m)-m/2)*dky
  s = size(r0_arg)
  if (s[0] eq 1) then begin
    r0 = r0_arg[0]
    L0 = r0_arg[1]
    k0 = 2*!pi/L0
  endif else begin
    r0 = r0_arg
    k0 = 0
  endelse
  k2 = kx^2 + ky^2 + k0^2
  k2[n/2,m/2] = 1.
;
     f = sqrt(0.023)*(2*!pi)^(5./6.)*r0^(-5./6.)*k2^(-11./12.)*sqrt(dkx*dky)
;
  f[n/2,m/2] = 0.
  if (nsh gt 0) then begin
    shf = fltarr(8,nsh)
    for i=0,nsh-1 do begin
      dkx = dkx/3.
      dky = dky/3.
      k2 = dkx^2 + dky^2 + k0^2
      shf[0,i] = k2^(-11./12.)*sqrt(dkx*dky)
      shf[1,i] = (dky^2+k0^2)^(-11./12.)*sqrt(dkx*dky)
      shf[2,i] = k2^(-11./12.)*sqrt(dkx*dky)
      shf[3,i] = (dkx^2+k0^2)^(-11./12.)*sqrt(dkx*dky)
      shf[4,i] = (dkx^2+k0^2)^(-11./12.)*sqrt(dkx*dky)
      shf[5,i] = k2^(-11./12.)*sqrt(dkx*dky)
      shf[6,i] = (dky^2+k0^2)^(-11./12.)*sqrt(dkx*dky)
      shf[7,i] = k2^(-11./12.)*sqrt(dkx*dky)
    endfor
    shf = shf*sqrt(0.023)*(2*!pi)^(5./6.)*r0^(-5./6.)
  endif
  return,f
end

; MAKESCREENS
;  this function makes a set of random phase screens
;  for use at altitude h[0], h[1], h[2], ...
;  with winds v[0], v[1], v[2], ...
;  with Fried parameter r0[0], r0[1], ...
;
;  Usage:
;    screenset = makescreens(n,m,r0,du,seed)
;
;  Inputs:
;    n,m - screen size
;    r0 - vector of r0's, one for each turbulent layer
;    du - pixel size, meters
;    seed - random seed
;
;  Output:
;    screenset - an [n,m,nlayers]
;
function makescreens,n,m,r0,du,seed,verbose=verbose
  if keyword_set(verbose) then print,'<makescreens>'
  nlayers = (size(r0))(1)
  s = fltarr(n,m,nlayers)
  for i=0,nlayers-1 do begin
    f = filtergen(n,m,r0[i],du)
    s[*,*,i] = screengen_f(f,seed)
    if keyword_set(verbose) then begin
    	print,format='($,I0," ")',i
    	wait,0.01
    endif
  endfor
  if keyword_set(verbose) then print,'<makescreens> done'
  return,s
end

; STRUCFCN
;  Calculate the sample structure function of an image
;       sf(u,v) =: <[s(u0,v0) - s(u0+u,v0+v)]^2>
;
;  Usage:
;     sf = strucfcn(s)
;
;  Inputs:
;     s - random screen
;
;  Output:
;     sf - sample structure function
;
function strucfcn,s,verbose = verbose
  if keyword_set(verbose) then print,'<strucfcn>'
  n = (size(s))(1)
  m = (size(s))(1)

  sp = fltarr(2*n,2*m)
  sp[0:n-1,0:m-1] = s
  fsp = ft(sp)
  nn2 = (float(n)*float(n))^2

  if keyword_set(verbose) then print,'calculating auto-correlation of data'
  ss = nn2*ft(fsp*conj(fsp),/inverse)

  win = fltarr(2*n,2*m)
  win[0:n-1,0:m-1] = 1
  fwin = ft(win)

  if keyword_set(verbose) then print,'calculating auto-correlation of window'
  ww = real(nn2*ft(fwin*conj(fwin),/inverse))

  if keyword_set(verbose) then print,'calculating cross-correlation window and screen^2
  cc = nn2*ft(fwin*conj(ft(sp^2)),/inverse);
  ccr = shift(reverse(reverse(cc,2)),1,1)

  sf = real( (cc + ccr - 2*ss) / (ww>1) )
  sf[n,m] = 0
  sf[0,*] = 0
  sf[*,0] = 0
  if keyword_set(verbose) then print,'<strucfcn> done'
  return,sf
end

;pro screengen,f,seed,s,compile=compile
;  forward_function filtergen,screengen_f
;  if keyword_set(compile) then return
;  if n_params() eq 0 then begin
;    doc_library,'screengen'
;    return
;  endif
;end

function screengen,arg1,arg2,arg3,arg4,nsh,shf
  forward_function filtergen,screengen_f
;  resolve_all
  argCount = n_params()
  if (n_elements(arg1) ne 1) then begin     ; generate a random screen
    if (argCount eq 2) then return,screengen_f(arg1,arg2)
    if (argCount eq 4) then return,screengen_f(arg1,arg2,arg3,arg4)
    return,0
  endif else begin
    if (argCount eq 4) then return,filtergen(arg1,arg2,arg3,arg4)
    if (argCount eq 6) then return,filtergen(arg1,arg2,arg3,arg4,nsh,shf)
  endelse
  return,0
end

;
; -------------
; example code
; -------------
forward_function filtergen,screengen_f
seed = 1
showAsRatio = 0

du = .3
r0 = 1.0
n = 64
m = 64
nsh = 5
ntrials = 100
dosubs = 1

window,/free
rmax = float(n)*du
r = findgen(n)*du
t = 6.88*(r/r0)^(5./3.)
if (showAsRatio eq 0) then plot,r[1:31],t[1:31],/xlog,/ylog,ticklen=.5,xtitle='r/r0',ytitle='radial average structure function'
f = screengen(n,m,r0,du,nsh,shf)

u = r/max(r)
if (showAsRatio) then plot,u[1:31],ones(32),ticklen=.5,yrange=[0,3],xrange=[1/float(n),1.], $
  xtitle='r/rmax', ytitle='struc fcn / 6.88(r/r0)^(5/3)',/nodata

;  sub-harmonics
if (doSubs) then begin

for j=0,ntrials-1 do begin
    s = screengen(f,seed,shf,du)
    sf = strucfcn(s)
    ra = ravg(sf)
    if (showAsRatio) then oplot,u[1:n-1],ra[1:n-1]/t[1:n-1],linestyle=2,color=220
    if (showAsRatio eq 0) then oplot,r[1:n-1],ra[1:n-1],linestyle=2,color=220
endfor

endif

;  no sub-harmonics
for j=0,ntrials-1 do begin
    s = screengen(f,seed); *.9
    sf = strucfcn(s)
    ra = ravg(sf)
    if (showAsRatio) then oplot,u[1:n-1],ra[1:n-1]/t[1:n-1],color=120; 150
    if (showAsRatio eq 0) then oplot,r[1:n-1],ra[1:n-2],color=120;
endfor

;oplot,u[1:n-1],1.-u^(.3)

end

