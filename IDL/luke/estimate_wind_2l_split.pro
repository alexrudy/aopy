;===============================Wind Estimation: Intensity method================================================
;this method uses the same assumptions as the one-layer Gauss-Newton method but with two layers
;everything else is the same except the wind_prior is now a 2x2 matrix [[v_x1,v_x2],[v_y1,v_y2]]
;function call:
;wind_estimate = estimate_wind_GN(curr,prev,apa,actinnerlocs,wind_est,[maxit],[/linear])
;curr = current wavefront (used as reference)
;prev = previous wavefront
;apa = actuator mask, this should have the edge actuators masked out
;wind_prior = a priori wind estimate in units of subapertures/timestep [[vx1,vx2],[vy1,vy2]]
;maxit = maximum number of iterations to run (default = 1)
;interp = the interpolation method to use, cubic, shannon, or linear

;Should I be passing pointers instead of arrays in order to speed things up?  Probably
;
function estimate_wind_2L_split,pCurr,pPrev,pPrev2,pApa,wind_prior,maxit,interp,do_v1=DO_V1,do_v2=DO_V2
  if keyword_set(do_v1) then doing_v1 = 1
  if keyword_set(do_v2) then doing_v2 = 1
  if ~keyword_set(do_v1) and ~keyword_set(do_v2) then begin
    doing_v1=1
    doing_v2=1
  endif
	if ~n_elements(interp) then interp='shannon'
  if total(interp eq ['linear','cubic','shannon']) eq 0 then begin
    print,'Error in estimate_wind_gn: invalid interpolation method'
    return,0
  endif
  damp_c = 0.8 ;damping coefficient for Gauss-Newton step
  actlocs = where((*pApa) eq 1)
	GradI = dblarr([2,size((*pApa),/dimensions)])
	DeltaI = dblarr([size((*pApa),/dimensions)])
	du_int = dblarr(2)
	prev2 = *pPrev2
  prev = *pPrev
  curr = *pCurr
  v1 = [wind_prior[0],wind_prior[2]]
  v2 = [wind_prior[1],wind_prior[3]]
  ;fc = ft(curr)
  ;fc[0,*]=0
  ;fc[*,0]=0
   ;    fc[1,*]=0
   ;   fc[*,1]=0
   ;   fc[39,*]=0
   ;   fc[0,39]=0
  ;curr = real(ft(fc,/inverse))
  ;try removing common piston?
  ;prev = depiston(prev)
  ;curr = depiston(curr)
	;create GradI from reference image (t)
	grad_kernel = [-0.5,0,0.5];1./8.*[[-1,0,1],[-2,0,2],[-1,0,1]];[-1,1];
	
  ;GradI[0,*,*] = 0.5*(shift(curr,-1,0)-shift(curr,1,0))*(*papa)
  ;GradI[1,*,*] = 0.5*(shift(curr,0,-1)-shift(curr,0,1))*(*papa)
	ref = (Curr);*(*pApa)
	;ref = depiston(ref,*pApa)

	for k = 1,maxit do begin
		;iterative solving for wind_est (u(x))
		;solve for v1 first then v2
		if doing_v1 then begin
  		;update DeltaI
      case interp of 
        'shannon':  begin
                      phi_shift_1 = fshift(Prev,v1[0],v1[1])
                      phi_shift_2 = fshift(Prev,v2[0],v2[1])
                      phi_shift_3 = fshift(Prev2,v1[0]+v2[0],v1[1]+v2[1])         
                    end
                     
        'cubic':    begin
                      ix = findgen((size((*pApa),/dimensions))[0])-v1[0]
                      iy = findgen((size((*pApa),/dimensions))[1])-v1[1]
                      phi_shift_1 = interpolate(Prev,ix,iy,/grid,cubic=-0.5)
                      ix = findgen((size((*pApa),/dimensions))[0])-v2[0]
                      iy = findgen((size((*pApa),/dimensions))[1])-v2[1]
                      phi_shift_2 = interpolate(Prev,ix,iy,/grid,cubic=-0.5)
                      ix = findgen((size((*pApa),/dimensions))[0])-v1[0]-v2[0]
                      iy = findgen((size((*pApa),/dimensions))[1])-v1[1]-v2[1]
                      phi_shift_3 = interpolate(Prev2,ix,iy,/grid,cubic=-0.5)
                    end
                      
        'linear':   begin
                      ix = findgen((size((*pApa),/dimensions))[0])-v1[0]
                      iy = findgen((size((*pApa),/dimensions))[1])-v1[1]
                      phi_shift_1 = interpolate(Prev,ix,iy,/grid)
                      ix = findgen((size((*pApa),/dimensions))[0])-v2[0]
                      iy = findgen((size((*pApa),/dimensions))[1])-v2[1]
                      phi_shift_2 = interpolate(Prev,ix,iy,/grid)
                      ix = findgen((size((*pApa),/dimensions))[0])-v1[0]-v2[0]
                      iy = findgen((size((*pApa),/dimensions))[1])-v1[1]-v2[1]
                      phi_shift_3 = interpolate(Prev2,ix,iy,/grid)
                    end
      endcase
  		;newwf *= *pApa
  		DeltaI = (ref - phi_shift_1 - phi_shift_2 + phi_shift_3)*(*pApa)
  		GradI[0,*,*] = convol(phi_shift_1,grad_kernel)*(*papa)
      GradI[1,*,*] = convol(phi_shift_1,transpose(grad_kernel))*(*papa)
      GradI[0,*,*] -= convol(phi_shift_3,grad_kernel)*(*papa)
      GradI[1,*,*] -= convol(phi_shift_3,transpose(grad_kernel))*(*papa)
  		;print,'residual =',rms(deltaI,*pApa)
   ;   DeltaI = depiston(DeltaI,*pApa)
  ;    if k eq maxit then begin
  ;      ;window,0,title='wavefronts'
  ;      ;plot,ref[*,0.5*(size(*papa,/dimensions))[1]]
  ;      ;oplot,newwf[*,0.5*(size(*papa,/dimensions))[1]],linestyle=2
  ;      window,0,title='unshifted ft difference'
  ;      plot,(abs(ft(curr))-abs(ft(prev)))[*,0.5*(size(*papa,/dimensions))[1]]
  ;      window,1,title='shifted wf difference' 
  ;      ;plot,(abs(ft(ref))-abs(ft(newwf)))[*,20]
  ;      plot,DeltaI[*,0.5*(size(*papa,/dimensions))[1]]
  ;      print,'ft residual (pre-shift)=',rms(abs(ft(curr))-abs(ft(prev)))
  ;      print,'residual =',rms(deltaI,*pApa)
  ;      ;disp,abs(ft(prev))-abs(ft(curr)),'diff FT'
  ;    endif
      
  		;calculate du_int
  		num = dblarr(1,2)
  		den = dblarr(2,2)
  ;		for i=0,n-1 do begin ;old for loop, sped up by using matrix operations instead
  ;			for j=0,n-1 do begin
  ;				num = num + GradI[*,i,j] ## DeltaI(i,j)
  ;				den = den + GradI[*,i,j] ## transpose(GradI[*,i,j])
  ;			endfor
  ;		endfor
  		num = [[total(GradI[0,*,*]*DeltaI)],[total(GradI[1,*,*]*DeltaI)]]	;matrix ops that replace for loop
  		;den = total(GradI[0,*,*]*GradI[0,*,*]+GradI[1,*,*]*GradI[1,*,*]);
  		den[0,0] = total(GradI[0,*,*]*GradI[0,*,*])
  		den[0,1] = total(GradI[0,*,*]*GradI[1,*,*])
  		den[1,0] = total(GradI[1,*,*]*GradI[0,*,*])
  		den[1,1] = total(GradI[1,*,*]*GradI[1,*,*])
  		;du_int[0] = -num[0]/den
  		;du_int[1] = -num[1]/den
  		d_v1 = -(invert(den,status))##num;
  		if status ne 0 then print,'error in estimate_wind_2l: singular matrix solving for v1' else $
  		v1 = v1 + damp_c*d_v1
		endif
		if doing_v2 then begin
		  ;update DeltaI
      case interp of 
        'shannon':  begin
                      phi_shift_1 = fshift(Prev,v1[0],v1[1])
                      phi_shift_2 = fshift(Prev,v2[0],v2[1])
                      phi_shift_3 = fshift(Prev2,v1[0]+v2[0],v1[1]+v2[1])         
                    end
                     
        'cubic':    begin
                      ix = findgen((size((*pApa),/dimensions))[0])-v1[0]
                      iy = findgen((size((*pApa),/dimensions))[1])-v1[1]
                      phi_shift_1 = interpolate(Prev,ix,iy,/grid,cubic=-0.5)
                      ix = findgen((size((*pApa),/dimensions))[0])-v2[0]
                      iy = findgen((size((*pApa),/dimensions))[1])-v2[1]
                      phi_shift_2 = interpolate(Prev,ix,iy,/grid,cubic=-0.5)
                      ix = findgen((size((*pApa),/dimensions))[0])-v1[0]-v2[0]
                      iy = findgen((size((*pApa),/dimensions))[1])-v1[1]-v2[1]
                      phi_shift_3 = interpolate(Prev2,ix,iy,/grid,cubic=-0.5)
                    end
                      
        'linear':   begin
                      ix = findgen((size((*pApa),/dimensions))[0])-v1[0]
                      iy = findgen((size((*pApa),/dimensions))[1])-v1[1]
                      phi_shift_1 = interpolate(Prev,ix,iy,/grid)
                      ix = findgen((size((*pApa),/dimensions))[0])-v2[0]
                      iy = findgen((size((*pApa),/dimensions))[1])-v2[1]
                      phi_shift_2 = interpolate(Prev,ix,iy,/grid)
                      ix = findgen((size((*pApa),/dimensions))[0])-v1[0]-v2[0]
                      iy = findgen((size((*pApa),/dimensions))[1])-v1[1]-v2[1]
                      phi_shift_3 = interpolate(Prev2,ix,iy,/grid)
                    end
      endcase
      ;newwf *= *pApa
      DeltaI = (ref - phi_shift_1 - phi_shift_2 + phi_shift_3)*(*pApa)
      GradI[0,*,*] = convol(phi_shift_2,grad_kernel)*(*papa)
      GradI[1,*,*] = convol(phi_shift_2,transpose(grad_kernel))*(*papa)
      GradI[0,*,*] -= convol(phi_shift_3,grad_kernel)*(*papa)
      GradI[1,*,*] -= convol(phi_shift_3,transpose(grad_kernel))*(*papa)
      ;print,'residual =',rms(deltaI,*pApa)
   ;   DeltaI = depiston(DeltaI,*pApa)
  ;    if k eq maxit then begin
  ;      ;window,0,title='wavefronts'
  ;      ;plot,ref[*,0.5*(size(*papa,/dimensions))[1]]
  ;      ;oplot,newwf[*,0.5*(size(*papa,/dimensions))[1]],linestyle=2
  ;      window,0,title='unshifted ft difference'
  ;      plot,(abs(ft(curr))-abs(ft(prev)))[*,0.5*(size(*papa,/dimensions))[1]]
  ;      window,1,title='shifted wf difference' 
  ;      ;plot,(abs(ft(ref))-abs(ft(newwf)))[*,20]
  ;      plot,DeltaI[*,0.5*(size(*papa,/dimensions))[1]]
  ;      print,'ft residual (pre-shift)=',rms(abs(ft(curr))-abs(ft(prev)))
  ;      print,'residual =',rms(deltaI,*pApa)
  ;      ;disp,abs(ft(prev))-abs(ft(curr)),'diff FT'
  ;    endif
      
      ;calculate du_int
      num = dblarr(1,2)
      den = dblarr(2,2)
  ;   for i=0,n-1 do begin ;old for loop, sped up by using matrix operations instead
  ;     for j=0,n-1 do begin
  ;       num = num + GradI[*,i,j] ## DeltaI(i,j)
  ;       den = den + GradI[*,i,j] ## transpose(GradI[*,i,j])
  ;     endfor
  ;   endfor
      num = [[total(GradI[0,*,*]*DeltaI)],[total(GradI[1,*,*]*DeltaI)]] ;matrix ops that replace for loop
      ;den = total(GradI[0,*,*]*GradI[0,*,*]+GradI[1,*,*]*GradI[1,*,*]);
      den[0,0] = total(GradI[0,*,*]*GradI[0,*,*])
      den[0,1] = total(GradI[0,*,*]*GradI[1,*,*])
      den[1,0] = total(GradI[1,*,*]*GradI[0,*,*])
      den[1,1] = total(GradI[1,*,*]*GradI[1,*,*])
      ;du_int[0] = -num[0]/den
      ;du_int[1] = -num[1]/den
      d_v2 = -(invert(den,status))##num;
      if status ne 0 then print,'error in estimate_wind_2l: singular matrix solving for v2' else $
      v2 = v2 + damp_c*d_v2
    endif
	endfor
	print,'2layer residual = ',total(DeltaI^2)
	return,[v1[0],v2[0],v1[1],v2[1]]
end
