	PRO TEK4211
;+
; Project     : SOHO - CDS
;
; Name        : TEK4211
;
; Purpose     : Sets graphics device for Tektronix 4211 color terminal.
;
; Explanation : SETPLOT is called to save and set the system variables.  Then
;		DEVICE is called to enable TEK4100 mode with 64 colors.
;
; Use         : TEK4211
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
; Category    : Utilities, Device.
;
; Prev. Hist. : W.T.T., Nov. 1987.
;		W.T.T., Mar. 1991, split TEK into TEK4105 and TEK4211.
;
; Written     : William Thompson, GSFC, November 1987.
;
; Modified    : Version 1, William Thompson, GSFC, 27 April 1993.
;			Incorporated into CDS library.
;
; Version     : Version 1, 27 April 1993.
;-
;
	SETPLOT,'TEK'
	DEVICE,/TEK4100,COLORS=64
	!P.FONT = -1
	PRINT,'Plots will now be written to the Tektronix 4211 terminal screen.'
;
	RETURN
	END
