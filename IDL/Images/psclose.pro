	PRO PSCLOSE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	PSCLOSE
; Purpose     : 
;	Close a PostScript plot file, reset graphics device.
; Explanation : 
;	The currently opened PostScript plot file is closed, and the graphics
;	device is reset to what was used previously.
; Use         : 
;	PSCLOSE
;
;	PS				;Open PostScript plot file
;	   ... plotting commands ...	;Create plot
;	PSPLOT				;Close & plot file, reset to prev. dev.
;	   or
;	PSCLOSE				;Close w/o printing,  "    "   "    "
;
; Inputs      : 
;	None.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	A message is printed to the screen.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	None.
; Calls       : 
;	SETPLOT
; Common      : 
;	PS_FILE which contains PS_FILENAME, the name of the plotting file,
;	LAST_DEVICE, which is the name of the previous graphics device, and
;	various parameters used to keep track of which configuration is being
;	used.
; Restrictions: 
;	In general, the SERTS graphics devices routines use the special system
;	variables !BCOLOR and !ASPECT.  These system variables are defined in
;	the procedure DEVICELIB.  It is suggested that the command DEVICELIB be
;	placed in the user's IDL_STARTUP file.
;
; Side effects: 
;	The previous plotting device is reset.
; Category    : 
;	Utilities, Devices.
; Prev. Hist. : 
;	William Thompson, August 1990.
;	W.T.T., Feb. 1991, modified to reflect change in common block PS_FILE.
; Written     : 
;	William Thompson, GSFC, August 1990.
; Modified    : 
;	Version 1, William Thompson, GSFC, 27 April 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 2 January 1994.
;		Added save into common plot of current configuration.
; Version     : 
;	Version 2, 2 January 1994.
;-
;
	COMMON PS_FILE, PS_FILENAME, LAST_DEVICE, CONFIGS, CUR_CONFIG,  $
		SAVE_CONFIG
;
;  Close any PostScript files.
;
	DEVICE = !D.NAME
	IF N_ELEMENTS(LAST_DEVICE) EQ 0 THEN LAST_DEVICE = !D.NAME
	IF !D.NAME NE 'PS' THEN SETPLOT,'PS'
	DEVICE,/CLOSE_FILE
	PS_FILENAME = ""
;
;  Save the parameters for the current configuration.
;
	IF CUR_CONFIG NE '' THEN BEGIN
		NCONFIG = WHERE(CONFIGS EQ CUR_CONFIG)
		SAVE_CONFIG(NCONFIG).POSITION = !P.POSITION
		SAVE_CONFIG(NCONFIG).XMARGIN = !X.MARGIN
		SAVE_CONFIG(NCONFIG).XWINDOW = !X.WINDOW
		SAVE_CONFIG(NCONFIG).YMARGIN = !Y.MARGIN
		SAVE_CONFIG(NCONFIG).YWINDOW = !Y.WINDOW
		SAVE_CONFIG(NCONFIG).ZMARGIN = !Z.MARGIN
		SAVE_CONFIG(NCONFIG).ZWINDOW = !Z.WINDOW
		SAVE_CONFIG(NCONFIG).THICK   = !P.THICK
		SAVE_CONFIG(NCONFIG).CHARTHICK = !P.CHARTHICK
		SAVE_CONFIG(NCONFIG).XTHICK  = !X.THICK
		SAVE_CONFIG(NCONFIG).YTHICK  = !Y.THICK
	ENDIF
;
;  Reset the plotting device.
;
	IF DEVICE NE 'PS' THEN SETPLOT,DEVICE ELSE SETPLOT,LAST_DEVICE
	PRINT, 'The plotting device is now set to ' + TRIM(LAST_DEVICE) + '.'
;
	RETURN
	END
