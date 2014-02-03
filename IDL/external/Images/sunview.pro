	PRO SUNVIEW
;+
; Project     : SOHO - CDS
;
; Name        : SUNVIEW
;
; Purpose     : Switch to SunView mode.
;
; Explanation : SETPLOT is called to save and set the system variables.
;
; Use         : SUNVIEW
;
; Inputs      : None.
;
; Opt. Inputs : None.
;
; Outputs     : A message is printed to the screen.
;
; Opt. Outputs: None.
;
; Keywords    : None.
;
; Calls       : SETPLOT
;
; Common      : None.  But calls SETPLOT, which uses common block PLOTFILE.
;
; Restrictions: It is best if the routines TEK, REGIS, etc. (i.e.  those
;		routines that use SETPLOT) are used to change the plotting
;		device.
;
;		In general, the SERTS graphics devices routines use the special
;		system variables !BCOLOR and !ASPECT.  These system variables
;		are defined in the procedure DEVICELIB.  It is suggested that
;		the command DEVICELIB be placed in the user's IDL_STARTUP file.
;
; Side effects: If not the first time this routine is called, then system
;		variables that affect plotting are reset to previous values.
;
; Category    : Utilities, Devices.
;
; Prev. Hist. : William Thompson
;
; Written     : William Thompson, GSFC.
;
; Modified    : Version 1, William Thompson, GSFC, 27 April 1993.
;			Incorporated into CDS library.
;		Version 2, William Thompson, GSFC, 21 October 1993.
;			Renamed to SUNVIEW.
;
; Version     : Version 2, 21 October 1993.
;-
;
	SETPLOT,'SUN'
	PRINT,'Plots will now be written to the SUN console.'
;
	RETURN
	END
