	PRO SCREEN
;+
; NAME:
;	SCREEN
; PURPOSE:
;	Resets to Tektronix 4010 mode.
; CALLING SEQUENCE:
;	SCREEN
; PARAMETERS:
;	None.
; COMMON BLOCKS:
;	None.  But calls SETPLOT, which uses common block PLOTFILE.
; SIDE EFFECTS:
;	If not the first time this routine is called, then system variables
;	that affect plotting are reset to previous values.
; RESTRICTIONS:
;	None, but it is best if the routines SCREEN, REGIS, etc. are used to
;	change the plotting device.
; PROCEDURE:
;	SETPLOT is called to save and set the system variables.
; MODIFICATION HISTORY:
;	W.T.T., Nov. 1987.
;-
;
	SETPLOT,'TEK'
	PRINT,'Plots will now be written to the terminal screen.'
;
	RETURN
	END
