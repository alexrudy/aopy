function twoD,data,n,locs
  a = fltarr(n,n)
  a[locs] = data
  return,a
end

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
;Run multiple iterations of code:
Runs = 1


for q=0,Runs-1 do begin
print,'Run #'+strcompress(string(q+1),/remove_all)+'...'
;============================================================================
; basic constants
cm = 1.e-2
mm = 1.e-3
microns = 1.e-6
nm = 1.e-9
km = 1.e4
i = complex(0.,1.)
;============================================================================

D =10.0				;aperture diameter, in meters
du = 0.56			;actuator spacing, in meters
dp = 1				;# of pixels across to break each subap into
r0 = 0.10			;Fried's parameter, in meters
lambda0 = 0.1*microns ;wavelength at which Fried's parameter is specified
real_wind = 25		;true wind in m/s (x direction only)
controller_speed = 1054;speed of AO controller in Hz
Tf = 29999				;# of timesteps
fixRandomSeed = 1 	;always use the same screen each time the code is run
verbose = 1
do_plots = 0
add_noise = 0
SNR = 2				;Signal to noise at WFS
use_test_image = 0	;use test image instead of Kolmogorov screen
use_real_data = 0	;use actual WFS data instead of randomly generated data
data_file = 'wf_tt.sav'

radon_method = 0		;use radon transform method with G-N curve matching
	min_act_x = 11		;for D/42, set to 14,15,45,44
	min_act_y = 10		;for D/17, set to 5,5,18,18
	max_act_x = 32		;for D/58, set to 19,20,62,61
	max_act_y = 33		;for D/31, set to 11,10,32,33
	;mask_edges_rt = 0	;mask out edge actuators (currently not available)
	maxit_rt = 1		;maximum iterations per timestep

bin_method = 0			;use 2D binary search method
	use_sub = 0			;use subregion of aperture instead of full aperture
		sub_xmin =33	;dimensions of subregion
		sub_xmax =47 	;for D/58 use 36,45 for 10x10
	search_size =  .01	;search distance between timesteps (subapertures)
	maxit_2D = 1		;maximum iterations per timestep
	cubic_interp = 0	;use cubic convolution interpolation instead of linear
;	mask_edges_2d = 1	;mask out edge actuators (always on, does not seem to slow down)

split_bin_method = 0	;use split 2d binary search method

intensity_method = 1	;use 2D Gauss-Newton method
	maxit_gn = 1		;maximum iterations per timestep
	use_sub_gn = 0			;use subregion of aperture instead of full aperture
		sub_xmin_gn =13	;dimensions of subregion
		sub_xmax_gn =29	;for D/58 use 36,45 for 10x10

wind0 = [0./controller_speed/du,0]		;initial wind estimate (x,y)
use_filt = 0			;do use 2x2 averaging
use_gauss_filt = 0		;use gaussian filtering on image before doing wind estimation
sig_filt = float(1)			;sigma to use
past_frames = 0			;average wind over how many previous frames at each step
start_frame = 100		;only compiles data from this frame onward to ignore transient effects

;============================================================================
if q eq 0 then begin
	if radon_method then results_rt = fltarr(2,2,Runs)
	if bin_method then results_2db = fltarr(2,2,Runs)
	if split_bin_method then results_s2d = fltarr(2,2,Runs)
	if intensity_method then results_gn = fltarr(2,2,Runs)
endif

;.blowingScreen
forward_function blowingScreen_init,blowingScreen_get
wind_avg = fltarr(2)

real_wind = double(real_wind)/double(controller_speed)*double(1)/double(du) ;convert wind to subap/timestep

if do_plots then begin
	num_plots = radon_method + bin_method + intensity_method + split_bin_method
	!P.MULTI = [0,1,2*num_plots]
endif

if not use_real_data then begin
	n = round(1.4*(D/du)+0.5)
	if ((n/2)*2 ne n) then n=n+1
	m = n-1; number of sensors (subapertures) across
	ap = circle(m,m,m/2,m/2,(D/du)/2,1.) ; aperture mask for subapertures
	;ap = ones(m,m);use full screen instead of circular aperture
	apa = fltarr(n,n) ; aperture mask for actuators


	;sets up the aperture pixel dimensions
	npix = n*dp
	mpix = m*dp
	ap_pix = fltarr(mpix,mpix)
	for j=0,mpix-1 do begin
		for k=0,mpix-1 do begin
			ap_pix[j,k] = ap[floor(j/dp),floor(k/dp)]
		endfor
	endfor

	H = hMatrix(ap,actVecLocs,sensVecLocs) ; Sensitivity matrix
	apa[actVecLocs] = 1
	pApa = ptr_new(apa)
	apa_pix = fltarr(npix,npix)
	for j=0,npix-1 do begin
		for k=0,npix-1 do begin
			apa_pix[j,k] = apa[floor(j/dp),floor(k/dp)]
		endfor
	endfor
	na = (size(H))[1]
	ns = (size(H))[2]
	if (fixRandomSeed) then begin
		seed0 = 0
	endif else begin
		if (n_elements(seed0) eq 0) then seed0 = 5 else seed0 = seed0+1
	endelse

	seedin = seed0
	apfill = fillmatrix(actveclocs,fillactveclocs,fillveclocs,n)

	phi_fine = fltarr(npix,npix)
	phi_fine_t = fltarr(npix,npix,Tf+1)
	phi_coarse_t = fltarr(n,n,Tf+1)
	phi_coarse_t_exp = fltarr(npix,npix,Tf+1)
	phi_coarse_t_noptt = fltarr(n,n,Tf+1)
endif

wf_rms_t = fltarr(Tf+1)
wf_rms_t_nopiston = fltarr(Tf+1)
wf_rms_t_notiptilt = fltarr(Tf+1)
wf_rms_t_deltatt = fltarr(Tf+1)

if verbose then print,'Generating fine screen t=0 to',Tf
wait,0.001
if use_real_data then begin
	RESTORE,data_file
	n=24
	;Tf = Tf-1
	apfill = fillmatrix(actveclocs,fillactveclocs,fillveclocs,n)
	phi_coarse_t = fltarr(n,n,Tf+1)
	phi_coarse_t = phi_coarse_ptt_t
endif
if use_test_image then begin
	Tf = n-4
	crop_outliers = 0
	phi_fine = fltarr(npix,npix)
	phi_fine_t = fltarr(npix,npix,Tf+1)
	phi_coarse_t = fltarr(n,n,Tf+1)
	phi_coarse_t_exp = fltarr(npix,npix,Tf+1)
	mask_edges = 0
	for t=0,n-4 do begin
		phi_coarse_t[t+2,n/2,t] = 10
		phi_coarse_t[t+3,n/2,t] = 10
		phi_coarse_t[t+1,n/2,t] = 10
		phi_coarse_t[t+2,n/2+1,t] = 10
		phi_coarse_t[t+2,n/2-1,t] = 10
		phi_coarse_t[t+3,n/2+1,t] = 10
		phi_coarse_t[t+3,n/2-1,t] = 10
		phi_coarse_t[t+1,n/2+1,t] = 10
		phi_coarse_t[t+1,n/2-1,t] = 10
	endfor
endif
if (not use_real_data and not use_test_image) then begin
	if (r0 ge du) then sd_noise = !DPI^2/2/sqrt(2)/SNR*sqrt(2.25+(du/r0)^2) else sd_noise = !DPI^2/2/sqrt(2)/SNR*sqrt(3.25*(du/r0)^2)
    m = npix + Tf*real_wind*dp
	screen = blowingScreen_init(npix,m,r0,du/dp,seed=seedin)
	for t=0,Tf do begin
  		wait,.001
   		phi_fine = blowingScreen_get(screen,real_wind*t*dp)*apa_pix
   		;phi_fine = detilt(depiston(phi_fine,apa_pix),apa_pix)*apa_pix
   		phi_fine_t[*,*,t] = phi_fine
	endfor
	if verbose then print,'done'
	if verbose then print,'Generating coarse screen t=0 to',Tf
	wait,0.001
;	for j=0,n-1 do begin
;		for k=0,n-1 do begin
;			for t=0,Tf do begin
;				phi_coarse_t[j,k,t] = mean(phi_fine_t[j*dp:j*dp+dp-1,k*dp:k*dp+dp-1,t])
;			endfor
;		endfor
;	endfor
    phi_coarse_t = readfits('data/keck_simulated/proc/sim_1_phase.fits',tmphead)
    apa = phi_coarse_t[*,*,0] ne 0
    pApa = ptr_new(apa)
    ; phi_coarse_t = rebin(phi_fine_t,n,n,Tf+1,/sample)
	if add_noise then begin
		for t=0,Tf do begin
			noise = sd_noise*randomn(seed,[n,n])
			phi_coarse_t[*,*,t] = phi_coarse_t[*,*,t] + twod(noise[actveclocs],n,actveclocs)
		endfor
	endif
;	for j=0,npix-1 do begin
;		for k=0,npix-1 do begin
;			for t=0,Tf do begin
;				phi_coarse_t_exp[j,k,t] = Phi_coarse_t[floor(j/dp),floor(k/dp),t]
;			endfor
;		endfor
;	endfor
	phi_coarse_t_exp = rebin(phi_coarse_t,npix,npix,Tf+1,/sample)
endif

phi_coarse_t_ptt = phi_coarse_t
for t=0,Tf do begin
	wf_rms_t[t] = rms(phi_coarse_t[*,*,t],apa)
	phi_coarse_t_noptt[*,*,t] = depiston(phi_coarse_t[*,*,t],apa)*apa
	wf_rms_t_nopiston[t] = rms(phi_coarse_t_noptt[*,*,t],apa)


	phi_coarse_t_noptt[*,*,t] = detilt(phi_coarse_t_noptt[*,*,t],apa)*apa
	wf_rms_t_notiptilt[t] = rms(phi_coarse_t_noptt[*,*,t],apa)
	if (t gt 0) then wf_rms_t_deltatt[t] = abs((wf_rms_t_nopiston[t]-wf_rms_t_notiptilt[t])-(wf_rms_t_nopiston[t-1]-wf_rms_t_notiptilt[t-1]))
endfor

if use_filt then begin
	for t=0,Tf do begin
		phi_coarse_t_ptt[*,*,t] = smooth(phi_coarse_t_ptt[*,*,t],2)
		phi_coarse_t_noptt[*,*,t] = smooth(phi_coarse_t_noptt[*,*,t],2)
	endfor
endif
if use_gauss_filt then begin
	Gauss_kernel = fltarr(3)
	Gauss_kernel = 1/sqrt(2*!dpi*sig_filt^2)*[exp(-1/(2*sig_filt^2)),1,exp(-1/(2*sig_filt^2))]
	Gauss_kernel = 1/total(Gauss_kernel)*Gauss_kernel
	for t=0,Tf do begin
		phi_coarse_t_ptt[*,*,t] = convol(convol(phi_coarse_t_ptt[*,*,t],Gauss_kernel),transpose(Gauss_kernel))
		phi_coarse_t_noptt[*,*,t] = convol(convol(phi_coarse_t_noptt[*,*,t],Gauss_kernel),transpose(Gauss_kernel))
	endfor
endif

if verbose then print,'done'
for iter =0,1 do begin
	if iter then phi_coarse_t = phi_coarse_t_noptt else phi_coarse_t = phi_coarse_t_ptt
	;===============================Wind Estimation: Gauss-Newton method================================================
	;this method makes the assumption that the intensity of each point in the turbulence doesn't change
	;appreciably from frame to frame.  hence: I(x,t) = I(x-u(x),t-1) where u(x) is the motion vector field
	;between consecutive images (wind velocity).  If the only motion assumed is simple translation then u(x) = (u,v)
	;The error metric we want to minimize is E(du)=SUM((DeltaI+GradI*du)^2) using Gauss-Newton leads to:
	;SUM(GradI*GradI')du = -SUM(GradI*DeltaI) here du is the incremental update to u(x) and DeltaI is calculated using
	;the current estimate of u(x).  DeltaI = I(x,t)-I(x-u(x),t-1)
	;Hierarchical Model-Based Motion Estimation - Bergen, et.at.
	;updated to use the new function estimate_wind_GN
	If intensity_method then  begin
		if verbose then print,'Calculating wind speed using intensity method...'
		wait,0.001
		wind_est = fltarr(2,Tf+1)
		wind_est_avg = fltarr(2)
		wind_est_stddev = fltarr(2)
		wind_err = fltarr(2,Tf+1)
		wind_err_mag = fltarr(Tf+1)
		wind_est[*,0] = -wind0
		;track_hist = fltarr(maxit+1,Tf+1)
		u_x = -wind0
		du_int = fltarr(2)
		comp_time = 0
		wind_avg = -wind0

		if use_sub_gn then begin ;set up parameters for square subregion of aperture to be used
			n_sub = sub_xmax_gn-sub_xmin_gn+1
			apa_sub = replicate(1,n_sub,n_sub)
			pApa_sub = ptr_new(apa_sub)
			actveclocs_sub = indgen(n_sub,n_sub)
			ap_mask_sub = edgemask(apa_sub,actinnerlocs_sub)
			pActinnerlocs_sub = ptr_new(actinnerlocs_sub)
	;		GradI = fltarr(2,n_sub,n_sub)
	;		DeltaI = fltarr(n_sub,n_sub)
		endif else begin
			ap_mask = edgemask(apa,actinnerlocs)
			pActinnerlocs = ptr_new(actinnerlocs)
	;		GradI = fltarr(2,n,n)
	;		DeltaI = fltarr(n,n)
		endelse

		start_time = systime(1)
		if use_sub_gn then begin
			for t=1,Tf do begin
				;wait,0.001
				pCurr = ptr_new(phi_coarse_t[sub_xmin_gn:sub_xmax_gn,sub_xmin_gn:sub_xmax_gn,t])
				pPrev = ptr_new(phi_coarse_t[sub_xmin_gn:sub_xmax_gn,sub_xmin_gn:sub_xmax_gn,t-1])
				u_x = estimate_wind_GN(pCurr,pPrev,n_sub,pApa_sub,pActinnerlocs_sub,u_x,maxit_gn)
				ptr_free,pPrev
				ptr_free,pCurr
				if (t lt past_frames) then begin
					wind_avg = (float(t)/float(t+1))*wind_avg + (float(1)/float(t+1))*u_x
					wind_est[*,t] = wind_avg
				endif else begin
					wind_avg = (float(past_frames)/float(past_frames+1))*wind_avg + (float(1)/float(past_frames+1))*u_x
					wind_est[*,t] = wind_avg
				endelse
			endfor
		endif else begin
			for t=1,Tf do begin
				;wait,0.001
				pCurr = ptr_new(phi_coarse_t[*,*,t])
				pPrev = ptr_new(phi_coarse_t[*,*,t-1])
				;start_time = systime(1)
				u_x = estimate_wind_GN(pCurr,pPrev,n,pApa,pActinnerlocs,u_x,maxit_gn)
				ptr_free,pPrev
				ptr_free,pCurr
				;comp_time += systime(1) - start_time
				if (t lt past_frames) then begin
					wind_avg = (float(t)/float(t+1))*wind_avg + (float(1)/float(t+1))*u_x
					wind_est[*,t] = wind_avg
				endif else begin
					wind_avg = (float(past_frames)/float(past_frames+1))*wind_avg + (float(1)/float(past_frames+1))*u_x
					wind_est[*,t] = wind_avg
				endelse
			endfor
		endelse
		comp_time = (systime(1) - start_time); - Tf*0.001)

		;convert to m/s and flip x-axis since blowingscreen has flipped x-axis
		wind_est = [-wind_est(0,*)*du*controller_speed,wind_est(1,*)*du*controller_speed]

		wind_est_avg[0] = mean(wind_est[0,start_frame:Tf])
		wind_est_stddev[0] = stddev(wind_est[0,start_frame:Tf])
		wind_est_avg[1] = mean(wind_est[1,start_frame:Tf])
		wind_est_stddev[1] = stddev(wind_est[1,start_frame:Tf])

		for t=0,Tf do begin
			wind_err[*,t] = abs([wind_est[0,t] - real_wind,wind_est[1,t]])
			wind_err_mag[t] = sqrt(wind_err[0,t]^2 + wind_err[1,t]^2)
		endfor
	;	wind_err_avg = mean(wind_err_mag[1:Tf])


		if verbose then print,['Intensity method average wind estimate - x = '+string(wind_est_avg[0])+'+/-'+string(wind_est_stddev[0])]
		if verbose then print,['Intensity method average wind estimate - y = '+string(wind_est_avg[1])+'+/-'+string(wind_est_stddev[1])]
		;print,'Average wind error =',wind_err_avg
		if verbose then print,['Computation time = '+string(comp_time/Tf*1000)+' millisec per timestep']
		if not iter then begin
			if do_plots then begin
				;window,0,title='wind estimates at each timestep'
				piston_rms = wf_rms_t[start_frame:Tf]-wf_rms_t_nopiston[start_frame:Tf]
				tt_rms = wf_rms_t_nopiston[start_frame:Tf]-wf_rms_t_notiptilt[start_frame:Tf]
				iplot,wind_est[0,start_frame:Tf],TITLE = 'Gauss-Newton Method', YTITLE = 'Wind Velocity - X (m/s)'
				;oplot,(tt_rms)*max(wind_est[0,start_frame:Tf])/max(tt_rms),linestyle=2
				iplot,(wf_rms_t_deltatt[start_frame:Tf])*0.5*max(wind_est[0,start_frame:Tf])/max(wf_rms_t_deltatt[start_frame:Tf]),linestyle=2,overplot=1
				;oplot,(piston_rms)*max(wind_est[0,start_frame:Tf])/max(piston_rms),linestyle=3
                iplot,wind_est_nott[0,start_frame:Tf],linestyle=1,overplot=1
				;oplot,wind_est_nott[0,start_frame:Tf],linestyle=5
				iplot,wind_est[1,start_frame:Tf],TITLE = 'Gauss-Newton Method',XTITLE = 'Timestep',YTITLE ='Wind Velocity - Y (m/s)'
				;oplot,wind_est_nott[1,start_frame:Tf],linestyle=5
				iplot,wind_est_nott[1,start_frame:Tf],linestyle=1,overplot=1
				;window,1,title='delta tt vs error'
				;plot,wind_err[0,start_frame:Tf],wf_rms_t_deltatt[start_frame:Tf],psym=2
			endif
            mkhdr, h1, wind_est
            writefits, 'data/keck_simulated/proc/sim_1_luke_wind.fits', wind_est, h1
		endif else wind_est_nott = wind_est

		wind_est_gn = fltarr(size(wind_est,/dimensions))
		wait,0.001
		wind_est_gn = wind_est
		wind_est_avg_gn = wind_est_avg
		wind_est_stddev_gn = wind_est_stddev
		if use_sub then begin
			ptr_free,pactinnerlocs_sub
			ptr_free,papa_sub
		endif else begin
			ptr_free,pactinnerlocs
		endelse
	endif
endfor

if bin_method then begin
	for iter =0,1 do begin
	if iter then phi_coarse_t = phi_coarse_t_noptt else phi_coarse_t = phi_coarse_t_ptt
	;=========================Wind Estimation: 2D Binary Search Method========================================================
	;This is a modification of the search and zoom method to make it more like the binary search method
	;in an attempt to speed it up.  The center point is eliminated and the search distance is halved
	;after each iteration no matter what.  Not sure how well this will work if only 1 iteration per timestep
	;
	;										0
	;
	;									1		2
	;
	;										3
	;

		if verbose then print,'Estimating wind speed using 2D binary search method...'
		wait,0.001
		wind_est = fltarr(2,Tf+1)
		wind_est_avg = fltarr(2)
		wind_est_stddev = fltarr(2)
		;wind_err = fltarr(2,Tf+1)
		;wind_err_mag = fltarr(Tf+1)
		wind_est[*,0] = -wind0
		;track_hist = fltarr(maxit+1,Tf+1)
		u_x = -wind0
		comp_time = 0

		if use_sub then begin ;set up parameters for square subregion of aperture to be used
			n_sub = sub_xmax-sub_xmin+1
			apa_sub = replicate(1,n_sub,n_sub)
			actveclocs_sub = indgen(n_sub,n_sub)
			ap_mask_sub = edgemask(apa_sub,actinnerlocs_sub)
			pActinnerlocs_sub = ptr_new(actinnerlocs_sub)
		endif else begin
			ap_mask = edgemask(apa,actinnerlocs)
			pActinnerlocs = ptr_new(actinnerlocs)
		endelse
		start_time = systime(1)
		if use_sub then begin
			if cubic_interp then begin
				for t=1,Tf do begin
					;wait,0.001
					pCurr = ptr_new(phi_coarse_t[sub_xmin:sub_xmax,sub_xmin:sub_xmax,t])
					pPrev = ptr_new(phi_coarse_t[sub_xmin:sub_xmax,sub_xmin:sub_xmax,t-1])
					u_x = estimate_wind_2d(pCurr,pPrev,u_x,search_size,n_sub,pactinnerlocs_sub,maxit_2d)
					ptr_free,pCurr
					ptr_free,pPrev
					if (t lt past_frames) then begin
						wind_avg = (float(t)/float(t+1))*wind_avg + (float(1)/float(t+1))*u_x
						wind_est[*,t] = wind_avg
					endif else begin
						wind_avg = (float(past_frames)/float(past_frames+1))*wind_avg + (float(1)/float(past_frames+1))*u_x
						wind_est[*,t] = wind_avg
					endelse
				endfor
			endif else begin
				for t=1,Tf do begin
					;wait,0.001
					pCurr = ptr_new(phi_coarse_t[sub_xmin:sub_xmax,sub_xmin:sub_xmax,t])
					pPrev = ptr_new(phi_coarse_t[sub_xmin:sub_xmax,sub_xmin:sub_xmax,t-1])
					u_x = estimate_wind_2d(pCurr,pPrev,u_x,search_size,n_sub,pactinnerlocs_sub,maxit_2d,/linear)
					ptr_free,pCurr
					ptr_free,pPrev
					if (t lt past_frames) then begin
						wind_avg = (float(t)/float(t+1))*wind_avg + (float(1)/float(t+1))*u_x
						wind_est[*,t] = wind_avg
					endif else begin
						wind_avg = (float(past_frames)/float(past_frames+1))*wind_avg + (float(1)/float(past_frames+1))*u_x
						wind_est[*,t] = wind_avg
					endelse
				endfor
			endelse
		endif else begin
			if cubic_interp then begin
				for t=1,Tf do begin
					;wait,0.001
					pCurr = ptr_new(phi_coarse_t[*,*,t])
					pPrev = ptr_new(phi_coarse_t[*,*,t-1])
					u_x = estimate_wind_2d(pCurr,pPrev,u_x,search_size,n,pactinnerlocs,maxit_2d)
					ptr_free,pCurr
					ptr_free,pPrev
					if (t lt past_frames) then begin
						wind_avg = (float(t)/float(t+1))*wind_avg + (float(1)/float(t+1))*u_x
						wind_est[*,t] = wind_avg
					endif else begin
						wind_avg = (float(past_frames)/float(past_frames+1))*wind_avg + (float(1)/float(past_frames+1))*u_x
						wind_est[*,t] = wind_avg
					endelse
				endfor
			endif else begin
				for t=1,Tf do begin
					;start_time = systime(1)
					;wait,0.001
					pCurr = ptr_new(phi_coarse_t[*,*,t])
					pPrev = ptr_new(phi_coarse_t[*,*,t-1])
					u_x = estimate_wind_2d(pCurr,pPrev,u_x,search_size,n,pactinnerlocs,maxit_2d,/linear)
					ptr_free,pCurr
					ptr_free,pPrev
					if (t lt past_frames) then begin
						wind_avg = (float(t)/float(t+1))*wind_avg + (float(1)/float(t+1))*u_x
						wind_est[*,t] = wind_avg
					endif else begin
						wind_avg = (float(past_frames)/float(past_frames+1))*wind_avg + (float(1)/float(past_frames+1))*u_x
						wind_est[*,t] = wind_avg
					endelse
					;comp_time += systime(1) - start_time
				endfor
			endelse
		endelse
		comp_time = (systime(1) - start_time)
	;=======================================================================================================


	   	;convert to m/s and flip x-axis since blowingscreen has flipped x-axis
		wind_est = [-wind_est(0,*)*du*controller_speed,wind_est(1,*)*du*controller_speed]

		wind_est_avg[0] = mean(wind_est[0,start_frame:Tf])
		wind_est_stddev[0] = stddev(wind_est[0,start_frame:Tf])
		wind_est_avg[1] = mean(wind_est[1,start_frame:Tf])
		wind_est_stddev[1] = stddev(wind_est[1,start_frame:Tf])

	;	for t=0,Tf do begin
	;		wind_err[*,t] = [wind_est[0,t] - real_wind,wind_est[1,t]]
	;		wind_err_mag[t] = sqrt(wind_err[0,t]^2 + wind_err[1,t]^2)
	;	endfor
	;	wind_err_avg = mean(wind_err_mag[1:Tf])

		wind_est_avg[1] = mean(wind_est[1,1:Tf])

		if verbose then print,['2D binary average wind estimate - x = '+string(wind_est_avg[0])+'+/-'+string(wind_est_stddev[0])]
		if verbose then print,['2D binary average wind estimate - y = '+string(wind_est_avg[1])+'+/-'+string(wind_est_stddev[1])]
		;print,'Average wind error =',wind_err_avg
		if verbose then print,'Computation time =',comp_time/Tf*1000,'millisec per timestep'
		;if do_plots then plot,wind_est[0,start_frame:Tf],TITLE = '2D binary method',YTITLE = 'Wind Velocity - X (m/s)'
		;if do_plots then plot,wind_est[1,start_frame:Tf],XTITLE = 'Timestep',YTITLE ='Wind Velocity - Y (subapertures/timestep)'
		if iter then begin
			if do_plots then begin
				;window,0,title='wind estimates at each timestep'
				piston_rms = wf_rms_t[start_frame:Tf]-wf_rms_t_nopiston[start_frame:Tf]
				tt_rms = wf_rms_t_nopiston[start_frame:Tf]-wf_rms_t_notiptilt[start_frame:Tf]
				iplot,wind_est[0,start_frame:Tf],TITLE = '2D Binary Method', YTITLE = 'Wind Velocity - X (m/s)'
				;oplot,(tt_rms)*max(wind_est[0,start_frame:Tf])/max(tt_rms),linestyle=2
				iplot,(wf_rms_t_deltatt[start_frame:Tf])*0.5*max(wind_est[0,start_frame:Tf])/max(wf_rms_t_deltatt[start_frame:Tf]),linestyle=2,overplot=1
				;oplot,(piston_rms)*max(wind_est[0,start_frame:Tf])/max(piston_rms),linestyle=3
				iplot,wind_est_nott[0,start_frame:Tf],linestyle=1,overplot=1
				;oplot,wind_est_nott[0,start_frame:Tf],linestyle=5
				iplot,wind_est[1,start_frame:Tf],TITLE = '2D Binary Method',XTITLE = 'Timestep',YTITLE ='Wind Velocity - Y (m/s)'
				;oplot,wind_est_nott[1,start_frame:Tf],linestyle=5
				iplot,wind_est_nott[1,start_frame:Tf],linestyle=1,overplot=1
				;window,1,title='delta tt vs error'
				;plot,wind_err[0,start_frame:Tf],wf_rms_t_deltatt[start_frame:Tf],psym=2
			endif
		endif else wind_est_nott = wind_est
		wind_est_2db = fltarr(size(wind_est,/dimensions))
		wind_est_2db = wind_est
		wind_est_avg_2db = wind_est_avg
		wind_est_stddev_2db = wind_est_stddev
		wait,0.001
		if use_sub then ptr_free,pactinnerlocs_sub else ptr_free,pactinnerlocs
	endfor
endif

if split_bin_method then begin
	for iter =0,1 do begin
	if iter then phi_coarse_t = phi_coarse_t_noptt else phi_coarse_t = phi_coarse_t_ptt

	;=========================Wind Estimation: Split 2D Binary Search Method========================================================
	;This is a modification of the 2D Binary Search Method to speed it up by alternating between only measuring the x and y velocity
	;components at each timestep

		if verbose then print,'Estimating wind speed using split 2D binary search method...'
		wait,0.001
		wind_est = fltarr(2,Tf+1)
		wind_est_avg = fltarr(2)
		wind_est_stddev = fltarr(2)
		;wind_err = fltarr(2,Tf+1)
		;wind_err_mag = fltarr(Tf+1)
		wind_est[*,0] = -wind0
		;track_hist = fltarr(maxit+1,Tf+1)
		u_x = -wind0
		comp_time = 0

		if use_sub then begin ;set up parameters for square subregion of aperture to be used
			n_sub = sub_xmax-sub_xmin+1
			apa_sub = replicate(1,n_sub,n_sub)
			actveclocs_sub = indgen(n_sub,n_sub)
			ap_mask_sub = edgemask(apa_sub,actinnerlocs_sub)
			pactinnerlocs_sub = ptr_new(actinnerlocs_sub)
		endif else begin
			ap_mask = edgemask(apa,actinnerlocs)
			pactinnerlocs = ptr_new(actinnerlocs)
		endelse
		start_time = systime(1)
		if use_sub then begin
			if cubic_interp then begin
				for t=1,Tf do begin
					;wait,0.001
					pPrev = ptr_new(phi_coarse_t[sub_xmin:sub_xmax,sub_xmin:sub_xmax,t])
					pCurr = ptr_new(phi_coarse_t[sub_xmin:sub_xmax,sub_xmin:sub_xmax,t-1])
					if (t mod 2) eq 0 then begin
						u_x = estimate_wind_2d_x(pCurr,pPrev,u_x,search_size,n_sub,pactinnerlocs_sub,maxit_2d)
					endif else begin
						u_x = estimate_wind_2d_y(pCurr,pPrev,u_x,search_size,n_sub,pactinnerlocs_sub,maxit_2d)
					endelse
					ptr_free,pCurr
					ptr_free,pPrev
					if (t lt past_frames) then begin
						wind_avg = (float(t)/float(t+1))*wind_avg + (float(1)/float(t+1))*u_x
						wind_est[*,t] = wind_avg
					endif else begin
						wind_avg = (float(past_frames)/float(past_frames+1))*wind_avg + (float(1)/float(past_frames+1))*u_x
						wind_est[*,t] = wind_avg
					endelse
				endfor
			endif else begin
				for t=1,Tf do begin
					;wait,0.001
					pPrev = ptr_new(phi_coarse_t[sub_xmin:sub_xmax,sub_xmin:sub_xmax,t])
					pCurr = ptr_new(phi_coarse_t[sub_xmin:sub_xmax,sub_xmin:sub_xmax,t-1])
					if (t mod 2) eq 0 then begin
						u_x = estimate_wind_2d_x(pCurr,pPrev,u_x,search_size,n_sub,pactinnerlocs_sub,maxit_2d,/linear)
					endif else begin
						u_x = estimate_wind_2d_y(pCurr,pPrev,u_x,search_size,n_sub,pactinnerlocs_sub,maxit_2d,/linear)
					endelse
					ptr_free,pCurr
					ptr_free,pPrev
					if (t lt past_frames) then begin
						wind_avg = (float(t)/float(t+1))*wind_avg + (float(1)/float(t+1))*u_x
						wind_est[*,t] = wind_avg
					endif else begin
						wind_avg = (float(past_frames)/float(past_frames+1))*wind_avg + (float(1)/float(past_frames+1))*u_x
						wind_est[*,t] = wind_avg
					endelse
				endfor
			endelse
		endif else begin
			if cubic_interp then begin
				for t=1,Tf do begin
					;wait,0.001
					pCurr = ptr_new(phi_coarse_t[*,*,t])
					pPrev = ptr_new(phi_coarse_t[*,*,t-1])
					if (t mod 2) eq 0 then begin
						u_x = estimate_wind_2d_x(pCurr,pPrev,u_x,search_size,n,pactinnerlocs,maxit_2d)
					endif else begin
						u_x = estimate_wind_2d_y(pCurr,pPrev,u_x,search_size,n,pactinnerlocs,maxit_2d)
					endelse
					ptr_free,pCurr
					ptr_free,pPrev
					if (t lt past_frames) then begin
						wind_avg = (float(t)/float(t+1))*wind_avg + (float(1)/float(t+1))*u_x
						wind_est[*,t] = wind_avg
					endif else begin
						wind_avg = (float(past_frames)/float(past_frames+1))*wind_avg + (float(1)/float(past_frames+1))*u_x
						wind_est[*,t] = wind_avg
					endelse
				endfor
			endif else begin
				for t=1,Tf do begin
					;wait,0.001
					pCurr = ptr_new(phi_coarse_t[*,*,t])
					pPrev = ptr_new(phi_coarse_t[*,*,t-1])
					if (t mod 2) eq 0 then begin
						u_x = estimate_wind_2d_x(pCurr,pPrev,u_x,search_size,n,pactinnerlocs,maxit_2d,/linear)
					endif else begin
						u_x = estimate_wind_2d_y(pCurr,pPrev,u_x,search_size,n,pactinnerlocs,maxit_2d,/linear)
					endelse
					ptr_free,pCurr
					ptr_free,pPrev
					if (t lt past_frames) then begin
						wind_avg = (float(t)/float(t+1))*wind_avg + (float(1)/float(t+1))*u_x
						wind_est[*,t] = wind_avg
					endif else begin
						wind_avg = (float(past_frames)/float(past_frames+1))*wind_avg + (float(1)/float(past_frames+1))*u_x
						wind_est[*,t] = wind_avg
					endelse
				endfor
			endelse
		endelse
		comp_time = (systime(1) - start_time)
	;=======================================================================================================


	   	;convert to m/s and flip x-axis since blowingscreen has flipped x-axis
		wind_est = [-wind_est(0,*)*du*controller_speed,wind_est(1,*)*du*controller_speed]

		wind_est_avg[0] = mean(wind_est[0,start_frame:Tf])
		wind_est_stddev[0] = stddev(wind_est[0,start_frame:Tf])
		wind_est_avg[1] = mean(wind_est[1,start_frame:Tf])
		wind_est_stddev[1] = stddev(wind_est[1,start_frame:Tf])

	;	for t=0,Tf do begin
	;		wind_err[*,t] = [wind_est[0,t] - real_wind,wind_est[1,t]]
	;		wind_err_mag[t] = sqrt(wind_err[0,t]^2 + wind_err[1,t]^2)
	;	endfor
	;	wind_err_avg = mean(wind_err_mag[1:Tf])

		wind_est_avg[1] = mean(wind_est[1,1:Tf])

		if verbose then print,['Split 2D binary average wind estimate - x = '+string(wind_est_avg[0])+'+/-'+string(wind_est_stddev[0])]
		if verbose then print,['Split 2D binary average wind estimate - y = '+string(wind_est_avg[1])+'+/-'+string(wind_est_stddev[1])]
		;print,'Average wind error =',wind_err_avg
		if verbose then print,'Computation time =',comp_time/Tf*1000,'millisec per timestep'
	;	if do_plots then begin
	;		tt_rms = wf_rms_t[start_frame:Tf]-wf_rms_t_notiptilt[start_frame:Tf]
	;		plot,wind_est[0,start_frame:TF],TITLE = '2D binary method',YTITLE = 'Wind Velocity - X (m/s)'
	;		oplot,(tt_rms)*max(wind_est[0,start_frame:Tf])/max(tt_rms),linestyle=2
	;		plot,wind_est[1,start_frame:Tf],XTITLE = 'Timestep',YTITLE ='Wind Velocity - Y (subapertures/timestep)'
	;	endif
		if iter then begin
			if do_plots then begin
				;window,0,title='wind estimates at each timestep'
				piston_rms = wf_rms_t[start_frame:Tf]-wf_rms_t_nopiston[start_frame:Tf]
				tt_rms = wf_rms_t_nopiston[start_frame:Tf]-wf_rms_t_notiptilt[start_frame:Tf]
				iplot,wind_est[0,start_frame:Tf],TITLE = '2D Split Binary Method', YTITLE = 'Wind Velocity - X (m/s)'
				;oplot,(tt_rms)*max(wind_est[0,start_frame:Tf])/max(tt_rms),linestyle=2
				iplot,(wf_rms_t_deltatt[start_frame:Tf])*0.5*max(wind_est[0,start_frame:Tf])/max(wf_rms_t_deltatt[start_frame:Tf]),linestyle=2,overplot=1
				;oplot,(piston_rms)*max(wind_est[0,start_frame:Tf])/max(piston_rms),linestyle=3
				iplot,wind_est_nott[0,start_frame:Tf],linestyle=1,overplot=1
				;oplot,wind_est_nott[0,start_frame:Tf],linestyle=5
				iplot,wind_est[1,start_frame:Tf],TITLE = '2D Split Binary Method',XTITLE = 'Timestep',YTITLE ='Wind Velocity - Y (m/s)'
				;oplot,wind_est_nott[1,start_frame:Tf],linestyle=5
				iplot,wind_est_nott[1,start_frame:Tf],linestyle=1,overplot=1
				;window,1,title='delta tt vs error'
				;plot,wind_err[0,start_frame:Tf],wf_rms_t_deltatt[start_frame:Tf],psym=2
			endif
		endif else wind_est_nott = wind_est
		wind_est_s2d = fltarr(size(wind_est,/dimensions))
		wind_est_s2d = wind_est
		wind_est_avg_s2d = wind_est_avg
		wind_est_stddev_s2d = wind_est_stddev
		if use_sub then ptr_free,pactinnerlocs_sub else ptr_free,pactinnerlocs
	endfor
endif

if radon_method then begin
	for iter =0,1 do begin
	if iter then phi_coarse_t = phi_coarse_t_noptt else phi_coarse_t = phi_coarse_t_ptt

	;===============================Wind Estimation: Radon Transform method=========================================================
	;This method uses the Radon transform to look at the x and y "profiles" of the image and use a curve-fitting method
	;to try to match them up.  It is not expected to work very well because it needs an image with more defined features
	;and Kolmogorov turbulence does not have these.

		if verbose then print,'Calculating wind speed using Radon transform method (G-N)...'
		wait,0.001
		wind_est = fltarr(2,Tf+1)
		wind_est_avg = fltarr(2)
		wind_avg = fltarr(2)
		wind_est_stddev = fltarr(2)
		xlength = max_act_x-min_act_x+1
		wind_est[*,0] = -wind0
		comp_time = 0
		u_x = -wind0

		start_time = systime(1)
		for t=1,Tf do begin
			;wait,0.001
			pCurr = ptr_new(phi_coarse_t[min_act_x:max_act_x,min_act_y:max_act_y,t])
			pPrev = ptr_new(phi_coarse_t[min_act_x:max_act_x,min_act_y:max_act_y,t-1])
			u_x = estimate_wind_rt(pCurr,pPrev,u_x,maxit_rt)
			ptr_free,pCurr
			ptr_free,pPrev
			if (t lt past_frames) then begin
				wind_avg = (float(t)/float(t+1))*wind_avg + (float(1)/float(t+1))*u_x
				wind_est[*,t] = wind_avg
			endif else begin
				wind_avg = (float(past_frames)/float(past_frames+1))*wind_avg + (float(1)/float(past_frames+1))*u_x
				wind_est[*,t] = wind_avg
			endelse
		endfor
		comp_time = (systime(1) - start_time)
	;=======================================================================================================


	   	;convert to m/s and flip x-axis since blowingscreen has flipped x-axis
		wind_est = [-wind_est(0,*)*du*controller_speed,wind_est(1,*)*du*controller_speed]

		wind_est_avg[0] = mean(wind_est[0,start_frame:Tf])
		wind_est_stddev[0] = stddev(wind_est[0,start_frame:Tf])
		wind_est_avg[1] = mean(wind_est[1,start_frame:Tf])
		wind_est_stddev[1] = stddev(wind_est[1,start_frame:Tf])

		if verbose then print,['Radon Xform(G-N) method average wind estimate - x = '+string(wind_est_avg[0])+'+/-'+string(wind_est_stddev[0])]
		if verbose then print,['Radon Xform(G-N) method average wind estimate - y = '+string(wind_est_avg[1])+'+/-'+string(wind_est_stddev[1])]
		;print,'Average wind error =',wind_err_avg
		if verbose then print,'Computation time =',comp_time/Tf*1000,'millisec per timestep'
	;	if do_plots then begin
	;		tt_rms = wf_rms_t[start_frame:Tf]-wf_rms_t_notiptilt[start_frame:Tf]
	;		plot,wind_est[0,start_frame:Tf],TITLE = 'Radon Transform(G-N) method',YTITLE = 'Wind Velocity - X (m/s)'
	;		oplot,(tt_rms)*max(wind_est[0,start_frame:Tf])/max(tt_rms),linestyle=2
	;		plot,wind_est[1,start_frame:Tf],XTITLE = 'Timestep',YTITLE ='Wind Velocity - Y (m/s)'
	;	endif
		if iter then begin
			if do_plots then begin
				;window,0,title='wind estimates at each timestep'
				piston_rms = wf_rms_t[start_frame:Tf]-wf_rms_t_nopiston[start_frame:Tf]
				tt_rms = wf_rms_t_nopiston[start_frame:Tf]-wf_rms_t_notiptilt[start_frame:Tf]
				iplot,wind_est[0,start_frame:Tf],TITLE = 'Radon Xform Method', YTITLE = 'Wind Velocity - X (m/s)'
				;oplot,(tt_rms)*max(wind_est[0,start_frame:Tf])/max(tt_rms),linestyle=2
				iplot,(wf_rms_t_deltatt[start_frame:Tf])*0.5*max(wind_est[0,start_frame:Tf])/max(wf_rms_t_deltatt[start_frame:Tf]),linestyle=2,overplot=1
				;oplot,(piston_rms)*max(wind_est[0,start_frame:Tf])/max(piston_rms),linestyle=3
				iplot,wind_est_nott[0,start_frame:Tf],linestyle=1,overplot=1
				;oplot,wind_est_nott[0,start_frame:Tf],linestyle=5
				iplot,wind_est[1,start_frame:Tf],TITLE = 'Radon Xform Method',XTITLE = 'Timestep',YTITLE ='Wind Velocity - Y (m/s)'
				;oplot,wind_est_nott[1,start_frame:Tf],linestyle=5
				iplot,wind_est_nott[1,start_frame:Tf],linestyle=1,overplot=1
				;window,1,title='delta tt vs error'
				;plot,wind_err[0,start_frame:Tf],wf_rms_t_deltatt[start_frame:Tf],psym=2
			endif
		endif else wind_est_nott = wind_est
		wait,0.001
	endfor
endif
if radon_method then results_rt[*,*,q] = [wind_est_avg,wind_est_stddev]
if bin_method then results_2db[*,*,q] = [wind_est_avg_2db,wind_est_stddev_2db]
if split_bin_method then results_s2d[*,*,q] = [wind_est_avg_s2d,wind_est_stddev_s2d]
if intensity_method then results_gn[*,*,q] = [wind_est_avg_gn,wind_est_stddev_gn]
ptr_free,papa
ptr_free,pCurr
ptr_free,pPrev
if use_sub then ptr_free,pactinnerlocs_sub else ptr_free,pactinnerlocs

endfor
print,'done'
if Runs gt 1 then begin
	if radon_method then begin
		avg_rt = total(results_rt[*,0,*],3)/Runs
		std_rt = sqrt(total(results_rt[*,1,*]^2,3)/Runs)
		print,['Radon Transform average wind estimate[x,y] = '+string(avg_rt)+'+/-'+string(std_rt)]
	endif
	if bin_method then begin
		avg_2db = total(results_2db[*,0,*],3)/Runs
		std_2db = sqrt(total(results_2db[*,1,*]^2,3)/Runs)
		print,['2D Binary average wind estimate[x,y] = '+string(avg_2db)+'+/-'+string(std_2db)]
	endif
	if split_bin_method then begin
		avg_s2d = total(results_s2d[*,0,*],3)/Runs
		std_s2d = sqrt(total(results_s2d[*,1,*]^2,3)/Runs)
		print,['Split 2D Binary average wind estimate[x,y] = '+string(avg_s2d)+'+/-'+string(std_s2d)]
	endif
	if intensity_method then begin
		avg_gn = total(results_gn[*,0,*],3)/Runs
		std_gn = sqrt(total(results_gn[*,1,*]^2,3)/Runs)
		print,['Gauss-Newton average wind estimate[x,y] = '+string(avg_gn)+'+/-'+string(std_gn)]
	endif
endif
;iplot,wind_est_gn[0,100:Tf],YTITLE = 'Wind Velocity - X (m/s)',YRANGE=[5,20];,DIMENSIONS = [400,200],/DISABLE_SPLASH_SCREEN
;iplot,wind_est_2db[0,100:Tf],LINESTYLE = 1,overplot=1
;iplot,wind_est_s2d[0,100:Tf],LINESTYLE = 2,overplot=1
;act = replicate(15,(size(wind_est))[2]-100)
;iplot,act,LINESTYLE = 3,overplot=1
;;
;;iplot,wind_est_gn[1,100:Tf],YTITLE = 'Wind Velocity - Y (m/s)',YRANGE=[-5,5],DIMENSIONS = [575,300],/DISABLE_SPLASH_SCREEN
;iplot,wind_est_2d[1,100:Tf],XTITLE = 'Timestep',YTITLE = 'Wind Velocity - Y (m/s)',YRANGE=[-5,5],DIMENSIONS = [575,300],/DISABLE_SPLASH_SCREEN;LINESTYLE = 0,overplot=1
;iplot,wind_est_rt[1,100:Tf],LINESTYLE = 1,overplot=1
;act = replicate(0,(size(wind_est))[2]-100)
;iplot,act,LINESTYLE = 3,overplot=1

end
;plot dimensions for paper:
;for 40x40:
;iplot_with_margins, Y_GN, xmargin=[0.13,0.05], ymargin=[0.10,0.06],YRANGE=[5,20],XTICKFONT_SIZE=8,YTICKFONT_SIZE=8,XTICKFONT_INDEX=1,YTICKFONT_INDEX=1,YTITLE = 'Wind Velocity - X(m/s)',DIMENSIONS=[500,250]
;iplot, Y_2d,linestyle=1,overplot=1
;iplot, Y_rt,linestyle=2,overplot=1
;iplot, Y_ac,linestyle=3,overplot=1
;;
;;for y plots:
;iplot_with_margins, Y_GN, xmargin=[0.13,0.05], ymargin=[0.17,0.05],YRANGE=[-5,5],XTICKFONT_SIZE=8,YTICKFONT_SIZE=8,XTICKFONT_INDEX=1,YTICKFONT_INDEX=1,YTITLE = 'Wind Velocity - Y(m/s)',XTITLE = 'Timestep',DIMENSIONS=[500,264]
;iplot, Y_2d,linestyle=1,overplot=1
;iplot, Y_rt,linestyle=2,overplot=1
;iplot, Y_ac,linestyle=3,overplot=1
;
;;for 60x60
;iplot_with_margins, Y_2d, xmargin=[0.13,0.05], ymargin=[0.10,0.06],YRANGE=[5,20],XTICKFONT_SIZE=8,YTICKFONT_SIZE=8,XTICKFONT_INDEX=1,YTICKFONT_INDEX=1,YTITLE = 'Wind Velocity - X(m/s)',DIMENSIONS=[500,250]
;iplot, Y_rt,linestyle=1,overplot=1
;iplot, Y_ac,linestyle=2,overplot=1
;;
;;for y plots:
;iplot_with_margins, Y_2d, xmargin=[0.13,0.05], ymargin=[0.17,0.05],YRANGE=[-5,5],XTICKFONT_SIZE=8,YTICKFONT_SIZE=8,XTICKFONT_INDEX=1,YTICKFONT_INDEX=1,YTITLE = 'Wind Velocity - Y(m/s)',XTITLE = 'Timestep',DIMENSIONS=[500,264]
;iplot, Y_rt,linestyle=1,overplot=1
;iplot, Y_ac,linestyle=2,overplot=1
;
;;for palomar data x:
;x=indgen(24001)/200.
;iplot_with_margins,x,Yj,xmargin=[0.10,0.05], ymargin=[0.10,0.06],YRANGE=[0,9],XTICKFONT_SIZE=8,YTICKFONT_SIZE=8,XTICKFONT_INDEX=1,YTICKFONT_INDEX=1,YTITLE = 'Wind Velocity - X(m/s)',DIMENSIONS=[500,250]
;x=indgen(23877)/200.
;iplot,x,Ya,linestyle=1,overplot=1
;;for y:
;x=indgen(24001)/200.
;iplot_with_margins,x,Yj,xmargin=[0.10,0.05], ymargin=[0.17,0.05],YRANGE=[-3,0],XTICKFONT_SIZE=8,YTICKFONT_SIZE=8,XTICKFONT_INDEX=1,YTICKFONT_INDEX=1,YTITLE = 'Wind Velocity - Y(m/s)',XTITLE = 'Time (seconds)',DIMENSIONS=[500,264]
;x=indgen(23877)/200.
;iplot,x,Ya,linestyle=1,overplot=1
