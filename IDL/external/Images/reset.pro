	PRO RESET
;+
; Project     : SOHO - CDS
;
; Name        : 
;	RESET
; Purpose     : 
;	Resets system variables to their default values.
; Explanation : 
;	Resets the system variables for the currently selected device, and
;	sets the following system variables to their default settings:
;
;		!LINETYPE	!PSYM		!NOERAS
;		!X.TITLE	!Y.TITLE	!P.TITLE
;		!XTICKS		!YTICKS
;
;	The routine SETPLOT is called to reinitialize the relevant system 
;	parameters for the selected device.  Then the above mentioned system
;	variables are set to their defaults.
;
; Use         : 
;	RESET
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
;	SETPLOT
; Common      : 
;	None, but this routine calls SETPLOT which uses the PLOTFILE common 
;	block.
; Restrictions: 
;	In general, the SERTS graphics devices routines use the special system
;	variables !BCOLOR and !ASPECT.  These system variables are defined in
;	the procedure DEVICELIB.  It is suggested that the command DEVICELIB be
;	placed in the user's IDL_STARTUP file.
;
; Side effects: 
;	None.
; Category    : 
;	Utilities, Devices.
; Prev. Hist. : 
;	William Thompson, January 23, 1989.
;	William Thompson, January 1993, changed to use current system variable
;		names.
; Written     : 
;	William Thompson, GSFC, 23 January 1989.
; Modified    : 
;	Version 1, William Thompson, GSFC, 27 April 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 27 April 1993.
;-
;
	ON_ERROR,2
	SETPLOT,!D.NAME
;
	IF !LINETYPE NE 0  THEN PRINT,'Resetting !LINETYPE'	& !LINETYPE = 0
	IF !PSYM     NE 0  THEN PRINT,'Resetting !PSYM'		& !PSYM     = 0
	IF !NOERAS   NE 0  THEN PRINT,'Resetting !NOERAS'	& !NOERAS   = 0
	IF !XTICKS   NE 0  THEN PRINT,'Resetting !XTICKS'	& !XTICKS   = 0
	IF !YTICKS   NE 0  THEN PRINT,'Resetting !YTICKS'	& !YTICKS   = 0
;
	IF !X.TITLE  NE '' THEN PRINT,'Resetting !X.TITLE'	& !X.TITLE = ''
	IF !Y.TITLE  NE '' THEN PRINT,'Resetting !Y.TITLE'	& !Y.TITLE = ''
	IF !P.TITLE  NE '' THEN PRINT,'Resetting !P.TITLE'	& !P.TITLE = ''
;
	RETURN
	END
