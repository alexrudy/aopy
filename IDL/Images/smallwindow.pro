	PRO SMALLWINDOW,WINDOW,XSIZE=XSIZE,YSIZE=YSIZE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	SMALLWINDOW
; Purpose     : 
;	Creates a small window.
; Explanation : 
;	This procedure creates or recreates a window which is smaller than the
;	average size.
; Use         : 
;	SMALLWINDOW  [, WINDOW ]
; Inputs      : 
;	None required.
; Opt. Inputs : 
;	WINDOW	- Window number.  Default is 0.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	XSIZE	- Window size in X direction.  Default is 512 or 256, depending
;		  on the size of the display.
;	YSIZE	- Window size in Y direction.  Default is XSIZE.
; Calls       : 
;	None.
; Common      : 
;	None.
; Restrictions: 
;	In general, the SERTS graphics devices routines use the special system
;	variables !BCOLOR and !ASPECT.  These system variables are defined in
;	the procedure DEVICELIB.  It is suggested that the command DEVICELIB be
;	placed in the user's IDL_STARTUP file.
;
; Side effects: 
;	None.
; Category    : 
;	Utilities, Graphics_devices.
; Prev. Hist. : 
;	W.T.T., Oct 1991, added test for X-display size.
; Written     : 
;	William Thompson, GSFC, October 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 11 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 11 May 1993.
;-
;
	ON_ERROR, 2
;
;  Select the default window size based on the size of the screen.
;
	WSIZE = 512
	IF !D.NAME EQ 'X' THEN BEGIN
		DEVICE,GET_SCREEN_SIZE=SZ
		IF (SZ(0) LT 1024) OR (SZ(1) LT 600) THEN WSIZE = 256
	ENDIF
;
;  Parse the input parameters and create the window.
;
	IF N_PARAMS(0) EQ 0 THEN WINDOW = 0
	IF N_ELEMENTS(XSIZE) EQ 0 THEN XSIZE = WSIZE
	IF N_ELEMENTS(YSIZE) EQ 0 THEN YSIZE = XSIZE
	WINDOW,WINDOW,XSIZE=XSIZE,YSIZE=YSIZE
;
	RETURN
	END
