	PRO TVSCREEN
;+
; Project     : SOHO - CDS
;
; Name        : 
;	TVSCREEN
; Purpose     : 
;	Create window 512 (or 256) pixels on a side for images.
; Explanation : 
;	WINDOW is called to open window #2 with XSIZE,YSIZE set to either 512
;	or 256 depending on the screen size.  Then TVDEVICE is called to make
;	this the default for image display, and WSET is called to redirect
;	plots back into the previous window.
; Use         : 
;	TVSCREEN
; Inputs      : 
;	None.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	None.
; Calls       : 
;	HAVE_WINDOWS, TVDEVICE
; Common      : 
;	None.
; Restrictions: 
;	The current graphics device must support windows.
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
;	William Thompson, Feb. 1990.
;	W.T.T., Feb. 1991., modified to use TVDEVICE.
;	W.T.T., Oct 1991, added test for X-display size.
;	William Thompson, December 1992, added support for DOS.
; Written     : 
;	William Thompson, GSFC, February 1990.
; Modified    : 
;	Version 1, William Thompson, GSFC, 11 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 11 May 1993.
;-
;
;  Select the window size based on the size of the screen.
;
	WSIZE = 512
	IF !D.NAME EQ 'X' THEN BEGIN
		DEVICE,GET_SCREEN_SIZE=SZ
		IF (SZ(0) LT 1024) OR (SZ(1) LT 600) THEN WSIZE = 256
	END ELSE IF !D.NAME EQ 'WIN' THEN BEGIN
		WSIZE = 256
	ENDIF
;
;  Create the window, set this as the default for image display, and then reset
;  to the previous window.
;
	IF HAVE_WINDOWS() THEN BEGIN
		GRAPHICS_WINDOW = !D.WINDOW
		WINDOW,2,XSIZE=WSIZE,YSIZE=WSIZE
		TVDEVICE,2
		IF GRAPHICS_WINDOW NE -1 THEN WSET, GRAPHICS_WINDOW
;
;  If not a window device, then print out an error message.
;
	END ELSE BEGIN
		PRINT,'*** Graphics device must support windows, routine TVSCREEN.'
	ENDELSE
;
	RETURN
	END
