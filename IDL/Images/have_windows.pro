	FUNCTION HAVE_WINDOWS
;+
; Project     : SOHO - CDS
;
; Name        : 
;	HAVE_WINDOWS
; Purpose     : 
;	Tests whether current graphics device supports windows.
; Explanation : 
;	The system variable !D.FLAGS is examined to see if the current graphics
;	device supports windows.
; Use         : 
;	Result = HAVE_WINDOWS()
;
;	IF HAVE_WINDOWS() THEN ...
;
; Inputs      : 
;	None.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	The result of the function is either 0 (false) or 1 (true) depending on
;	whether or not the current graphics device supports windows.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	None.
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
;	Utilities, Devices.
; Prev. Hist. : 
;	William Thompson, April 1992.
; Written     : 
;	William Thompson, GSFC, April 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 27 April 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 27 April 1993.
;-
;
	RETURN,(!D.FLAGS AND 256) NE 0
	END
