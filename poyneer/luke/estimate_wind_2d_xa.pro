;=========================Wind Estimation: 2D Binary Search Method========================================================
;This is a modification of the 2D Binary method that only searches the two x direction points in order to improve speed
;
;function call:
;wind_est = estimate_wind_2d(curr,prev,wind_prior,n,apa,actlocs,[maxit],[/linear],[/maskedge])
;curr = current wavefront (used as reference)
;prev = wavefront from previous timestep
;wind_prior = a priori wind estimate
;n = # of actuators across aperture
;apa = actuator mask
;actlocs = actveclocs if /maskedge not set, actinnerlocs if /maskedge keyword set
;maxit = maximum # of iterations to run (default = 1)
;/linear = keyword set to use linear interpolation instead of cubic convolution interpolation (faster but less accurate)
;/nomask = don't ignore edge of aperture

function estimate_wind_2d_xa,pCurr,pPrev,wind_prior,search_size,n,pactlocs,maxit,LINEAR = linear,NOMASK = nomask
	if n_elements(maxit) eq 0 then maxit=1
	if keyword_set(linear) then cubic_interp = 0 else cubic_interp = 1
	if keyword_set(nomask) then mask_edges = 0 else mask_edges = 1

	shift_points = fltarr(n,n,2)
	u_x = wind_prior
	if mask_edges then begin
		ref = twod((*pCurr)[*pactlocs],n,*pactlocs)
	endif

;	set up shift vectors to use for interpolation
	ix_pls = findgen(n) - u_x[0] - search_size
	iy_cen = findgen(n) - u_x[1]
	ix_min = findgen(n) - u_x[0] + search_size

	;create shifted images using cubic interpolation (using /grid here, not sure if that is faster than using ix, iy as matrices)
	if cubic_interp then begin
		shift_points[*,*,0] = interpolate(*pPrev,ix_min,iy_cen,/grid,cubic = -0.5)
		shift_points[*,*,1] = interpolate(*pPrev,ix_pls,iy_cen,/grid,cubic = -0.5)
	endif else begin
	;create shifted images using linear interpolation
		shift_points[*,*,0] = interpolate(*pPrev,ix_min,iy_cen,/grid)
		shift_points[*,*,1] = interpolate(*pPrev,ix_pls,iy_cen,/grid)
	endelse

	for j=0,maxit-1 do begin
		;mask out edges of shifted images
		shift_points[*,*,0] = twod((shift_points[*,*,0])[*pactlocs],n,*pactlocs)
		shift_points[*,*,1] = twod((shift_points[*,*,1])[*pactlocs],n,*pactlocs)

		;find min abs error
		err0 = total(abs(shift_points[*,*,0] - ref))
		err1 = total(abs(shift_points[*,*,1] - ref))

;		;find min ssd error
;		err0 = total((shift_points[*,*,0] - ref)^2)
;		err1 = total((shift_points[*,*,1] - ref)^2)

		if err0 le err1 then begin
			u_x[0] -= search_size
		endif else begin
			u_x[0] += search_size
		endelse
		if (j ge maxit-1) then break
		search_size *= 0.5
		if (search_size lt 0.001) then break

		;set up new shift vectors, iy_cen stays the same
		ix_pls = findgen(n) - u_x[0] - search_size
		ix_min = findgen(n) - u_x[0] + search_size

		;create shifted images using interpolation
		if cubic_interp then begin
			shift_points[*,*,0] = interpolate(*pPrev,ix_min,iy_cen,/grid,cubic = -0.5)
			shift_points[*,*,1] = interpolate(*pPrev,ix_pls,iy_cen,/grid,cubic = -0.5)
		endif else begin
			shift_points[*,*,0] = interpolate(*pPrev,ix_min,iy_cen,/grid)
			shift_points[*,*,1] = interpolate(*pPrev,ix_pls,iy_cen,/grid)
		endelse
	endfor
	return,u_x
end
