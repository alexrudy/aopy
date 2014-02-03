	PRO TVUNSELECT, DISABLE=DISABLE, SAFE=SAFE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	TVUNSELECT
; Purpose     : 
;	Inverse to the TVSELECT routine.
; Explanation : 
;	Reset to the graphics device and/or window that was current when
;	TVSELECT was called.
; Use         : 
;	TVUNSELECT
; Inputs      : 
;	None.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None, but various parameters in common block TV_WINDOW are modified.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	DISABLE	= If set, then no action is taken.
;	SAFE	= If set, then SETPLOT is used instead of SET_PLOT, and
;		  SETWINDOW instead of WSET.  Generally used when called from
;		  SETIMAGE.
; Calls       : 
;	HAVE_WINDOWS, SETWINDOW, SETPLOT
; Common      : 
;	TV_DEVICE contains various parameters used to communicate with the
;	routines TVDEVICE and TVSELECT.
; Restrictions: 
;	Only works if TVDEVICE, TVSELECT and TVUNSELECT are used exclusively to
;	change between the image display and graphics device/window.
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
;	William Thompson, GSFC, Feb. 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 5 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 1 September 1993.
;		Changed WSET to SETWINDOW, SET_PLOT to SETPLOT.
;		Added SAFE keyword.
; Version     : 
;	Version 2, 1 September 1993.
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
;  If DISABLE keyword has been set, then take no action.
;
	IF KEYWORD_SET(DISABLE) THEN RETURN
;
;  First check that the special TV display is enabled, and has been set.
;
	IF (NOT TV_ENABLED) OR (NOT TV_SET) THEN RETURN
;
;  If a particular window was selected for the image display, and the current
;  graphics device supports windows, then reset to the previous window.
;
	IF WINDOW_SET AND HAVE_WINDOWS() THEN BEGIN
		IF GRAPHICS_WINDOW NE -1 THEN BEGIN
			IF KEYWORD_SET(SAFE) THEN SETWINDOW, GRAPHICS_WINDOW $
				ELSE WSET, GRAPHICS_WINDOW
		ENDIF
		TV_SET = 0
	ENDIF
;
;  If a particular device was selected for the image display, then reset to the
;  previous device.
;
	IF DEVICE_SET THEN BEGIN
		IF KEYWORD_SET(SAFE) THEN SETPLOT, GRAPHICS_DEVICE ELSE	$
			SET_PLOT, GRAPHICS_DEVICE
		TV_SET = 0
	ENDIF
;
	RETURN
	END
