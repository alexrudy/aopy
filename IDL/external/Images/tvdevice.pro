	PRO TVDEVICE, P1, P2, ENABLE=ENABLE, DISABLE=DISABLE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	TVDEVICE
; Purpose     : 
;	Defines the default image display device or window.
; Explanation : 
;	Defines a given device and/or window as the default for image display.
;	Once this routine is called, the routine TVSELECT selects the image
;	display device/window, and TVUNSELECT returns to the previous
;	device/window.
; Use         : 
;	TVDEVICE, WINDOW
;	TVDEVICE, DEVICE  [, WINDOW ]
; Inputs      : 
;	DEVICE  = Character string containing the name of device to be used for
;		  displaying images.
;	WINDOW  = Index of window (i.e. 0, 1, 2, ...) to be used for displaying
;		  images.  Must refer to an already existing window.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None, but various parameters in common block TV_WINDOW are modified.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	ENABLE  = If set, then selecting the image display device via TVSELECT
;		  and TVUNSELECT in enabled (default).
;	DISABLE = If set, then selecting the image display device via TVSELECT
;		  and TVUNSELECT is disabled.  DISABLE takes precedence over
;		  ENABLE keyword.
; Calls       : 
;	None.
; Common      : 
;	TV_DEVICE contains various parameters used to communicate with the
;	routines TVSELECT and TVUNSELECT.
; Restrictions: 
;	Only works if TVDEVICE, TVSELECT and TVUNSELECT are used exclusively to
;	change between the image display and graphics device/window.  Only
;	existing windows can be used.  Device name must be passed as a
;	character string, and window number must be passed as an integer.
;
;	If only the window number is passed, then TVSELECT will only select
;	this window if the current graphics device is a windowing device.
;
;	If something goes wrong, the easiest way to clear it is to SET_PLOT
;	and/or WSET to the desired graphics device/window, and then call
;	TVDEVICE again.
;
;	In general, the SERTS image display routines use several non-standard
;	system variables.  These system variables are defined in the procedure
;	IMAGELIB.  It is suggested that the command IMAGELIB be placed in the
;	user's IDL_STARTUP file.
;
;	Some routines also require the SERTS graphics devices software,
;	generally found in a parallel directory at the site where this software
;	was obtained.  Those routines have their own special system variables.
;
; Side effects: 
;	None.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, Feb. 1991.
; Written     : 
;	William Thompson, GSFC, February 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 11 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 11 May 1993.
;-
;
	COMMON TV_DEVICE, TV_ENABLED, TV_SET,			$
		DEVICE_SET, DEVICE_NAME, GRAPHICS_DEVICE,	$
		WINDOW_SET, WINDOW_NUMBER, GRAPHICS_WINDOW
;
;  If the common block has not yet been initialized, then initialize it.
;
	IF N_ELEMENTS(TV_ENABLED) NE 1 THEN BEGIN
		TV_ENABLED = 0
		TV_SET     = 0
		DEVICE_SET = 0
		WINDOW_SET = 0
	ENDIF
;
;  Parse the input parameters.  If only one parameter was passed, then check to
;  see if it was a character string (device name) or a number (window).
;
	IF N_PARAMS(0) EQ 1 THEN BEGIN
		IF N_ELEMENTS(P1) NE 1 THEN BEGIN
			PRINT,'*** Only scalars can be passed to TVDEVICE.'
			RETURN
		ENDIF
		SZ1 = SIZE(P1)
		IF SZ1(SZ1(0)+1) EQ 7 THEN BEGIN	;Device name.
			TV_ENABLED = 1
			TV_SET	   = 0
			DEVICE_SET = 1
			WINDOW_SET = 0
			DEVICE_NAME = STRTRIM(P1,2)
;			PRINT,'*** Image display device is now ' + DEVICE_NAME
		END ELSE BEGIN				;Window number.
			TV_ENABLED = 1
			TV_SET	   = 0
			DEVICE_SET = 0
			WINDOW_SET = 1
			WINDOW_NUMBER = FIX(P1)
;			PRINT,'*** Image display window is now ' +	$
;				STRTRIM(WINDOW_NUMBER,2)
		ENDELSE
;
;  If both parameters were set then the first must be the device name and the
;  last must be the window number.  First check the device name.
;
	END ELSE IF N_PARAMS(0) EQ 2 THEN BEGIN
		IF N_ELEMENTS(P1) NE 1 THEN BEGIN
			PRINT,'*** DEVICE must be a scalar, routine TVDEVICE.'
			RETURN
		END ELSE BEGIN
			SZ1 = SIZE(P1)
			IF SZ1(SZ1(0)+1) NE 7 THEN BEGIN
				PRINT,'*** DEVICE must be a character ' + $
					'string, routine TVDEVICE.'
				RETURN
			ENDIF
		ENDELSE
;
;  Next check the window number.
;
		IF N_ELEMENTS(P2) NE 1 THEN BEGIN
			PRINT,'*** WINDOW must be a scalar, routine TVDEVICE.'
			RETURN
		END ELSE BEGIN
			SZ2 = SIZE(P2)
			IF SZ2(SZ2(0)+1) EQ 7 THEN BEGIN
				PRINT,'*** WINDOW must not be a character ' + $
					'string, routine TVDEVICE.'
				RETURN
			ENDIF
		ENDELSE
;
;  Set the device name and window number.
;
		TV_ENABLED = 1
		TV_SET	   = 0
		DEVICE_SET = 1
		WINDOW_SET = 1
		DEVICE_NAME = STRTRIM(P1,2)
		WINDOW_NUMBER = FIX(P2)
;		PRINT,'*** Image display device is now ' + DEVICE_NAME + $
;			', window number ' + STRTRIM(WINDOW_NUMBER,2)
	ENDIF
;
;  Check the keywords ENABLE and DISABLE.
;
	IF KEYWORD_SET(ENABLE)  THEN TV_ENABLED = 1
	IF KEYWORD_SET(DISABLE) THEN TV_ENABLED = 0
;
	RETURN
	END
