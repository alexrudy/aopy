;===============================Wind Estimation: Intensity method================================================
;this method makes the assumption that the intensity of each point in the turbulence doesn't change
;appreciably from frame to frame.  hence: I(x,t) = I(x-u(x),t-1) where u(x) is the motion vector field
;between consecutive images (wind velocity).  If the only motion assumed is simple translation then u(x) = (u,v)
;The error metric we want to minimize is E(du)=SUM((DeltaI+GradI*du)^2) using Gauss-Newton leads to:
;SUM(GradI*GradI')du = -SUM(GradI*DeltaI) here du is the incremental update to u(x) and DeltaI is calculated using
;the current estimate of u(x).  DeltaI = I(x,t)-I(x-u(x),t-1)
;Hierarchical Model-Based Motion Estimation - Bergen, et.at.
;function call:
;wind_estimate = estimate_wind_GN(curr,prev,apa,actinnerlocs,wind_est,[maxit],[/linear])
;curr = current wavefront (used as reference)
;prev = previous wavefront
;n = # of actuators across aperture
;apa = actuator mask, this is not used anymore
;actinnerlocs = locations of non-edge actuators
;wind_prior = a priori wind estimate in units of subapertures/timestep (vx,vy)
;maxit = maximum number of iterations to run (default = 1)
;/linear = set to use linear interpolation instead of cubic convolution interpolation (faster, less accurate)

;Should I be passing pointers instead of arrays in order to speed things up?  Probably


function estimate_wind_GN,pCurr,pPrev,n,pApa,pActinnerlocs,wind_prior,maxit,LINEAR = linear
	if n_elements(maxit) eq 0 then maxit=1
	if keyword_set(linear) then cubic_interp = 0 else cubic_interp = 1

	GradI = fltarr(2,n,n)
	DeltaI = fltarr(n,n)
	du_int = fltarr(2)
;	ix = fltarr(n,n)
;	iy = fltarr(n,n)

	;create GradI from reference image (t)
	GradI[0,*,*] = convol(depiston(*pCurr,*papa),[-0.5,0,0.5])*(*papa)
	GradI[1,*,*] = convol(depiston(*pCurr,*papa),transpose([-0.5,0,0.5]))*(*papa)
	inner = twod((*papa)[*pactinnerlocs],n,*pactinnerlocs)
	ref = depiston((*pCurr)*inner,inner)
	u_x = wind_prior
	for k = 1,maxit do begin
		;iterative solving for wind_est (u(x))
		;update DeltaI
		if u_x[0] ne 0 or u_x[1] ne 0 then begin
;			for i=0,n-1 do begin ;tried to speed up by using findgen, doesn't seem to make much of a difference
;			ix[i,*] = i - u_x[0]
;			iy[*,i] = i - u_x[1]
;			endfor
			ix = findgen(n)-u_x[0]
			iy = findgen(n)-u_x[1]
			if cubic_interp then begin;way to speed this up?
				DeltaI = ref - depiston(interpolate(*pPrev,ix,iy,/grid,cubic=-0.5)*inner,inner)
			endif else begin
				DeltaI = ref - depiston(interpolate(*pPrev,ix,iy,/grid)*inner,inner)
			endelse
		endif else begin
			DeltaI = ref - depiston((*pPrev)*inner,inner)
		endelse
        ; print,DeltaI
		;calculate du_int
		num = fltarr(1,2)
		den = fltarr(2,2)
;		for i=0,n-1 do begin ;old for loop, sped up by using matrix operations instead
;			for j=0,n-1 do begin
;				num = num + GradI[*,i,j] ## DeltaI(i,j)
;				den = den + GradI[*,i,j] ## transpose(GradI[*,i,j])
;			endfor
;		endfor
		num = [[total(GradI[0,*,*]*DeltaI)],[total(GradI[1,*,*]*DeltaI)]]	;matrix ops that replace for loop
        ; print,num
		;den = total(GradI[0,*,*]*GradI[0,*,*]+GradI[1,*,*]*GradI[1,*,*]);
		den[0,0] = total(GradI[0,*,*]*GradI[0,*,*])
		den[0,1] = total(GradI[0,*,*]*GradI[1,*,*])
		den[1,0] = total(GradI[1,*,*]*GradI[0,*,*])
		den[1,1] = total(GradI[1,*,*]*GradI[1,*,*])
		;du_int[0] = -num[0]/den
		;du_int[1] = -num[1]/den
        du_int = -(invert(den))##num;
        ; print,du_int
		u_x = u_x + du_int
        ; print,num
		;u_x = u_x + du_int
		;if (du_int[0]/u_x[0] lt 0.001) and (du_int[1]/u_x[1] lt 0.001) then break;check for convergence
	endfor
	return,transpose(u_x)
end
