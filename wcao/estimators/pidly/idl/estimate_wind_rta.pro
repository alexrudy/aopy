;===============================Wind Estimation: Radon Transform method=========================================================
;This method uses the Radon transform to look at the x and y "profiles" of the image and use Gauss-Newton curve-fitting
;to try to match them up.  It is not expected to work very well because it needs an image with more defined features
;and Kolmogorov turbulence does not have these.  It is, however, a vey fast and efficient way to do wind estimation.
;Note that it is important that the images passed to this function not contain any pixels that are outside the aperture
;of the telescope as this will cause misestimation of the wind velocity.
;Function call:
;u_x = estimate_wind_rt(curr,prev,wind_prior,maxit)
;curr: current wavefront estimate (reference)
;prev: wavefront estimate from previous timestep
;wind_prior: a priori wind estimate
;maxit: maximum # of iterations to run (default = 1)
function estimate_wind_rt,pCurr,pPrev,wind_prior,maxit

	n = (size(*pCurr,/dimensions))[0]
	m = (size(*pCurr,/dimensions))[1]
;	ref_x = fltarr(n)
;	ref_y = fltarr(m)
;	bestguess_x = fltarr(n)
;	bestguess_y = fltarr(m)
;	GradI_x = fltarr(n)
;	GradI_y = fltarr(m)
;	DeltaI_x = fltarr(n)
;	DeltaI_y = fltarr(m)
	du_x = fltarr(2)

	u_x = wind_prior

	ref_x = total(*pCurr,2)
	ref_y = total(*pCurr,1)

	;Maybe try doing 2D interp BEFORE Radon transform instead of after to improve accuracy?
	;it will still probably be faster than the other methods

	bestguess_x = total(*pPrev,2)
	bestguess_y = total(*pPrev,1)

	ix_cen = findgen(n) - u_x[0]
	iy_cen = findgen(m) - u_x[1]

	bestguess_x_shift = interpolate(bestguess_x,ix_cen,cubic = cubic)
	bestguess_y_shift = interpolate(bestguess_y,iy_cen,cubic = cubic)

	;This attempts to do interpolation first to try and improve accuracy, it doesn't seem to work
;	ix_cen = findgen(n) - u_x[0]
;	iy_cen = findgen(n) - u_x[1]
;
;	bestguess = interpolate(prev,ix_cen,iy_cen,/grid,cubic = cubic)
;	bestguess_x_shift = total(bestguess,2)
;	bestguess_y_shift = total(bestguess,1)

	;create GradI from reference image (t)
	GradI_x = convol(ref_x,[-.5,0,.5])
	GradI_y = convol(ref_y,[-.5,0,.5])

	for k = 1,maxit do begin
		;iterative solving for wind_est (u(x))
		;update DeltaI
		DeltaI_x = ref_x - bestguess_x_shift
		DeltaI_y = ref_y - bestguess_y_shift
		;calculate du_x and du_y

		du_x[0] = -total(GradI_x*DeltaI_x)/total(GradI_x*GradI_x)
		du_x[1] = -total(GradI_y*DeltaI_y)/total(GradI_y*GradI_y)
		u_x = u_x + du_x
		if k ne maxit then begin
			if (du_x/u_x lt 0.001) and (du_y/u_y lt 0.001) then break else begin
				ix_cen = findgen(n) - u_x[0]
				iy_cen = findgen(m) - u_x[1]
				bestguess_x_shift = interpolate(bestguess_x,ix_cen,cubic = cubic)
				bestguess_y_shift = interpolate(bestguess_y,iy_cen,cubic = cubic)
			endelse
		endif else break
	endfor
	return,u_x
end