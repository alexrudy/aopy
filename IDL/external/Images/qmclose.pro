	PRO QMCLOSE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	QMCLOSE
; Purpose     : 
;	Close a QMS plot file and reset the graphics device.
; Explanation : 
;	The currently opened QMS plot file is closed, and the graphics device
;	is reset to what was used previously.
; Use         : 
;	QMCLOSE
;
;	QMS				;Open QMS plot file
;	   ... plotting commands ...	;Create plot
;	QMPLOT				;Close & plot file, reset to prev. dev.
;	   or
;	QMCLOSE				;Close w/o printing,  "    "   "    "
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
;	QMS_FILE which contains QMS_FILENAME, the name of the plotting file,
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
;	William Thompson, Feb. 1991, from PSCLOSE
; Written     : 
;	William Thompson, GSFC, February 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 27 April 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 27 April 1993.
;-
;
	COMMON QMS_FILE, QMS_FILENAME, LAST_DEVICE
;
;  Close any QMS files.
;
	DEVICE = !D.NAME
	IF !D.NAME NE 'QMS' THEN SETPLOT,'QMS'
	DEVICE,/CLOSE_FILE
	QMS_FILENAME = ""
;
;  Reset the plotting device.
;
	IF DEVICE  NE 'QMS' THEN SETPLOT,DEVICE ELSE SETPLOT,LAST_DEVICE
	PRINT,'The plotting device is now set to '+TRIM(LAST_DEVICE)+'.'
;
	RETURN
	END
