;=========================Wind Estimation: 2D Binary Search Method========================================================
;This is a modification of the search and zoom method to make it more like the binary search method
;in an attempt to speed it up.  The center point is eliminated and the search distance is halved
;after each iteration no matter what.
;Diamond search pattern
;
;										0
;
;									1		2
;
;										3
;
;function call:
;wind_est = estimate_wind_2d(curr,prev,wind_prior,n,actlocs,[maxit],[/linear],[/maskedge])
;curr = current wavefront (used as reference)
;prev = wavefront from previous timestep
;wind_prior = a priori wind estimate
;n = # of actuators across aperture
;actlocs = actveclocs if /maskedge not set, actinnerlocs if /maskedge keyword set
;maxit = maximum # of iterations to run (default = 1)
;/linear = keyword set to use linear interpolation instead of cubic convolution interpolation (faster but less accurate)
;/nomask = Edges of aperture are generally masked out, set this to not mask edges.  Pass actveclocs instead of actinnerlocs if this keyword is set

function estimate_wind_2da,pCurr,pPrev,wind_prior,search_size,n,pactlocs,maxit,LINEAR = linear,NOMASK = nomask
	if n_elements(maxit) eq 0 then maxit=1
	if keyword_set(linear) then cubic_interp = 0 else cubic_interp = 1
	if keyword_set(nomask) then mask_edges = 0 else mask_edges = 1

	shift_points = fltarr(n,n,4)
	u_x = wind_prior
	converged = 0
	if mask_edges then begin
		ref = twod((*pCurr)[*pactlocs],n,*pactlocs)
	endif

;	;try to set up shift matrices instead of vectors so not using /grid.  Is this faster? no
;	ix_cen = fltarr(n,n)
;	iy_cen = fltarr(n,n)
;	ix_cen[*,0] = findgen(n) - u_x[0]
;	iy_cen[0,*] = findgen(n) - u_x[1]
;	for i=1,n-1 do begin
;		ix_cen[*,i] = ix_cen[*,0]
;		iy_cen[i,*] = iy_cen[0,*]
;	endfor
;
;	ix_pls = ix_cen - search_size
;	iy_pls = iy_cen - search_size
;	ix_min = ix_cen + search_size
;	iy_min = iy_cen + search_size

;	set up shift vectors to use for interpolation
	ix_cen = findgen(n) - u_x[0]
	iy_cen = findgen(n) - u_x[1]
	ix_pls = ix_cen - search_size
	iy_pls = iy_cen - search_size
	ix_min = ix_cen + search_size
	iy_min = iy_cen + search_size



	;create shifted images using cubic interpolation (using /grid here, not sure if that is faster than using ix, iy as matrices)
	if cubic_interp then begin
		shift_points[*,*,0] = interpolate(*pPrev,ix_cen,iy_pls,cubic = -0.5,/grid)
		shift_points[*,*,1] = interpolate(*pPrev,ix_min,iy_cen,cubic = -0.5,/grid)
		shift_points[*,*,2] = interpolate(*pPrev,ix_pls,iy_cen,cubic = -0.5,/grid)
		shift_points[*,*,3] = interpolate(*pPrev,ix_cen,iy_min,cubic = -0.5,/grid)
	endif else begin
	;create shifted images using linear interpolation
		shift_points[*,*,0] = interpolate(*pPrev,ix_cen,iy_pls,/grid)
		shift_points[*,*,1] = interpolate(*pPrev,ix_min,iy_cen,/grid)
		shift_points[*,*,2] = interpolate(*pPrev,ix_pls,iy_cen,/grid)
		shift_points[*,*,3] = interpolate(*pPrev,ix_cen,iy_min,/grid)
	endelse

	for j=0,maxit-1 do begin
		;mask out edges of shifted images
		shift_points[*,*,0] = twod((shift_points[*,*,0])[*pactlocs],n,*pactlocs)
		shift_points[*,*,1] = twod((shift_points[*,*,1])[*pactlocs],n,*pactlocs)
		shift_points[*,*,2] = twod((shift_points[*,*,2])[*pactlocs],n,*pactlocs)
		shift_points[*,*,3] = twod((shift_points[*,*,3])[*pactlocs],n,*pactlocs)


		;find min abs error
		err0 = total(abs(shift_points[*,*,0] - ref))
		err1 = total(abs(shift_points[*,*,1] - ref))
		err2 = total(abs(shift_points[*,*,2] - ref))
		err3 = total(abs(shift_points[*,*,3] - ref))

;		;find min ssd error
;		err0 = total((shift_points[*,*,0] - curr)^2)
;		err1 = total((shift_points[*,*,1] - curr)^2)
;		err2 = total((shift_points[*,*,2] - curr)^2)
;		err3 = total((shift_points[*,*,3] - curr)^2)

		error = min([err0,err1,err2,err3],aa)
		case aa of
			0:	begin
					u_x[1] += search_size
					if (j ge maxit-1) then break
					search_size *= 0.5
					if (search_size lt 0.001) then begin
						converged = 1
						break
					endif
					;set up new shift vectors, ix_cen stays the same
					iy_cen = findgen(n) - u_x[1]
					ix_pls = ix_cen - search_size
					iy_pls = iy_cen - search_size
					ix_min = ix_cen + search_size
					iy_min = iy_cen + search_size
					;create shifted images using cubic interpolation
					if cubic_interp then begin
						shift_points[*,*,0] = interpolate(*pPrev,ix_cen,iy_pls,/grid,cubic = -0.5)
						shift_points[*,*,1] = interpolate(*pPrev,ix_min,iy_cen,/grid,cubic = -0.5)
						shift_points[*,*,2] = interpolate(*pPrev,ix_pls,iy_cen,/grid,cubic = -0.5)
						shift_points[*,*,3] = interpolate(*pPrev,ix_cen,iy_min,/grid,cubic = -0.5)
					endif else begin
						;create shifted images using linear interpolation
						shift_points[*,*,0] = interpolate(*pPrev,ix_cen,iy_pls,/grid)
						shift_points[*,*,1] = interpolate(*pPrev,ix_min,iy_cen,/grid)
						shift_points[*,*,2] = interpolate(*pPrev,ix_pls,iy_cen,/grid)
						shift_points[*,*,3] = interpolate(*pPrev,ix_cen,iy_min,/grid)
					endelse
				end

			1: 	begin
					u_x[0] -= search_size
					if (j ge maxit-1) then break
					search_size *= 0.5
					if (search_size lt 0.001) then begin
						converged = 1
						break
					endif
					;set up new shift vectors, iy_cen stays the same
					ix_cen = findgen(n) - u_x[0]
					ix_pls = ix_cen - search_size
					iy_pls = iy_cen - search_size
					ix_min = ix_cen + search_size
					iy_min = iy_cen + search_size
					;create shifted images using cubic interpolation
					if cubic_interp then begin
						shift_points[*,*,0] = interpolate(*pPrev,ix_cen,iy_pls,/grid,cubic = -0.5)
						shift_points[*,*,1] = interpolate(*pPrev,ix_min,iy_cen,/grid,cubic = -0.5)
						shift_points[*,*,2] = interpolate(*pPrev,ix_pls,iy_cen,/grid,cubic = -0.5)
						shift_points[*,*,3] = interpolate(*pPrev,ix_cen,iy_min,/grid,cubic = -0.5)
					endif else begin
						;create shifted images using linear interpolation
						shift_points[*,*,0] = interpolate(*pPrev,ix_cen,iy_pls,/grid)
						shift_points[*,*,1] = interpolate(*pPrev,ix_min,iy_cen,/grid)
						shift_points[*,*,2] = interpolate(*pPrev,ix_pls,iy_cen,/grid)
						shift_points[*,*,3] = interpolate(*pPrev,ix_cen,iy_min,/grid)
					endelse
				end


			2:  begin
					u_x[0] += search_size
					if (j ge maxit-1) then break
					search_size *= 0.5
					if (search_size lt 0.001) then begin
						converged = 1
						break
					endif
				 	;set up new shift vectors, iy_cen stays the same
					ix_cen = findgen(n) - u_x[0]
					ix_pls = ix_cen - search_size
					iy_pls = iy_cen - search_size
					ix_min = ix_cen + search_size
					iy_min = iy_cen + search_size
					;create shifted images using cubic interpolation
					if cubic_interp then begin
						shift_points[*,*,0] = interpolate(*pPrev,ix_cen,iy_pls,/grid,cubic = -0.5)
						shift_points[*,*,1] = interpolate(*pPrev,ix_min,iy_cen,/grid,cubic = -0.5)
						shift_points[*,*,2] = interpolate(*pPrev,ix_pls,iy_cen,/grid,cubic = -0.5)
						shift_points[*,*,3] = interpolate(*pPrev,ix_cen,iy_min,/grid,cubic = -0.5)
					endif else begin
						;create shifted images using linear interpolation
						shift_points[*,*,0] = interpolate(*pPrev,ix_cen,iy_pls,/grid)
						shift_points[*,*,1] = interpolate(*pPrev,ix_min,iy_cen,/grid)
						shift_points[*,*,2] = interpolate(*pPrev,ix_pls,iy_cen,/grid)
						shift_points[*,*,3] = interpolate(*pPrev,ix_cen,iy_min,/grid)
					endelse
				end

				3:	begin
					u_x[1] -= search_size
					if (j ge maxit-1) then break
					search_size *= 0.5
					if (search_size lt 0.001) then begin
						converged = 1
						break
					endif
					;set up new shift vectors, ix_cen stays the same
					iy_cen = findgen(n) - u_x[1]
					ix_pls = ix_cen - search_size
					iy_pls = iy_cen - search_size
					ix_min = ix_cen + search_size
					iy_min = iy_cen + search_size
					;create shifted images using cubic interpolation
					if cubic_interp then begin
						shift_points[*,*,0] = interpolate(*pPrev,ix_cen,iy_pls,/grid,cubic = -0.5)
						shift_points[*,*,1] = interpolate(*pPrev,ix_min,iy_cen,/grid,cubic = -0.5)
						shift_points[*,*,2] = interpolate(*pPrev,ix_pls,iy_cen,/grid,cubic = -0.5)
						shift_points[*,*,3] = interpolate(*pPrev,ix_cen,iy_min,/grid,cubic = -0.5)
					endif else begin
						;create shifted images using linear interpolation
						shift_points[*,*,0] = interpolate(*pPrev,ix_cen,iy_pls,/grid)
						shift_points[*,*,1] = interpolate(*pPrev,ix_min,iy_cen,/grid)
						shift_points[*,*,2] = interpolate(*pPrev,ix_pls,iy_cen,/grid)
						shift_points[*,*,3] = interpolate(*pPrev,ix_cen,iy_min,/grid)
					endelse
				end

				else: print,'problem finding point of minimum error in estimate_wind_2D'
		endcase
		if converged then break
	endfor
	return,u_x
end
