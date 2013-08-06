	PRO XTERMINAL,RETAIN=RETAIN,XSIZE=XSIZE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	XTERMINAL
; Purpose     : 
;	Selects X-windows with a particular window size and backstorage mode.
; Explanation : 
;	This procedure sets up a remote X-windows terminal in a somewhat
;	different way from X-windows on the console.  The default for an
;	X-windows terminal is to use RETAIN=2 (backing storage on the remote
;	host), and XSIZE=512 (for window 0).
;
;	This procedure should only be called once.  Subsequents redirections to
;	X-windows output should be done through the routine "XWIN".
;
; Use         : 
;	XTERMINAL
; Inputs      : 
;	None.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	RETAIN	= Backstorage mode (from IDL manual).
;	XSIZE	= Size of first window in X direction.
; Calls       : 
;	SETPLOT
; Common      : 
;	None.
; Restrictions: 
;	This procedure should only be used on X-windows terminals that do not
;	themselves have backing storage capability.  It should be used before
;	other windows are created.
;
;	In general, the SERTS graphics devices routines use the special system
;	variables !BCOLOR and !ASPECT.  These system variables are defined in
;	the procedure DEVICELIB.  It is suggested that the command DEVICELIB be
;	placed in the user's IDL_STARTUP file.
;
; Side effects: 
;	None.
; Category    : 
;	None.
; Prev. Hist. : 
;	William Thompson.
; Written     : 
;	William Thompson, GSFC.
; Modified    : 
;	Version 1, William Thompson, GSFC, 11 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 11 May 1993.
;-
;
	ON_ERROR, 2
;
;  Parse the input parameters.
;
	IF N_ELEMENTS(RETAIN) EQ 0 THEN RETAIN=2
	IF N_ELEMENTS(XSIZE)  EQ 0 THEN XSIZE=WSIZE
	SETPLOT,'X'
	DEVICE,RETAIN=RETAIN
;
;  Select the default window size based on the size of the screen, and recreate
;  window 0.
;
	WSIZE = 512
	DEVICE,GET_SCREEN_SIZE=SZ
	COMMAND = 'WINDOW,0'
	IF (SZ(0) NE 1152) AND (SZ(1) NE 900) THEN BEGIN
		XSIZE = '512'
		YSIZE = '512'
		IF (SZ(0) LT 900) OR (SZ(1) LT 600) THEN BEGIN
			XSIZE = '320'
			YSIZE = '256'
		ENDIF
		COMMAND = COMMAND + ',XSIZE=' + XSIZE + ',YSIZE=' + YSIZE
	ENDIF
	TEST = EXECUTE(COMMAND)
	PRINT,'Plots will now be written to the X terminal.'
;
	RETURN
	END
