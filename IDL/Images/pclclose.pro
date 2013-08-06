	PRO PCLCLOSE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	PCLCLOSE
; Purpose     : 
;	Close an HP LaserJet PCL plot file, reset graphics device.
; Explanation : 
;	The currently opened HP LaserJet PCL plot file is closed, and the
;	graphics device is reset to what was used previously.
; Use         : 
;	PCLCLOSE
;
;	PCL				;Open PCL plot file
;	   ... plotting commands ...	;Create plot
;	PCLPLOT				;Close & plot file, reset to prev. dev.
;	   or
;	PCLCLOSE			;Close w/o printing,  "    "   "    "
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
;	PCL_FILE which contains PCL_FILENAME, the name of the plotting file,
;	and LAST_DEVICE, which is the name of the previous graphics device.
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
;	None.
; Written     : 
;	William Thompson, GSFC, 15 June 1993.
; Modified    : 
;	Version 1, William Thompson, GSFC, 15 June 1993.
;		Based on QMCLOSE.PRO.
; Version     : 
;	Version 1, 15 June 1993.
;-
;
	COMMON PCL_FILE, PCL_FILENAME, LAST_DEVICE
;
;  Close any PCL files.
;
	DEVICE = !D.NAME
	IF !D.NAME NE 'PCL' THEN SETPLOT,'PCL'
	DEVICE,/CLOSE_FILE
	PCL_FILENAME = ""
;
;  Reset the plotting device.
;
	IF DEVICE  NE 'PCL' THEN SETPLOT,DEVICE ELSE SETPLOT,LAST_DEVICE
	PRINT,'The plotting device is now set to '+TRIM(LAST_DEVICE)+'.'
;
	RETURN
	END
