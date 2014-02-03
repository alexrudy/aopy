	PRO TVERASE, DISABLE=DISABLE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	TVERASE
; Purpose     : 
;	Erases image display screen.
; Explanation : 
;	If TVDEVICE has been called then erases special image display device or
;	window.  Otherwise erases current window.
; Use         : 
;	TVERASE
; Inputs      : 
;	None.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	DISABLE  = If set, then TVSELECT not used.  Mainly included for
;		   routines (such as EXPTV) which call TVERASE.
; Calls       : 
;	TVSELECT, TVUNSELECT
; Common      : 
;	None.
; Restrictions: 
;	In general, the SERTS image display routines use several non-standard
;	system variables.  These system variables are defined in the procedure
;	IMAGELIB.  It is suggested that the command IMAGELIB be placed in the
;	user's IDL_STARTUP file.
;
;	Some routines also require the SERTS graphics devices software,
;	generally found in a parallel directory at the site where this software
;	was obtained.  Those routines have their own special system variables.
;
; Side effects: 
;	None.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, Feb., 1990.
;	W.T.T., Feb. 1991, modified to use TVSELECT, TVUNSELECT.
; Written     : 
;	William Thompson, GSFC, February 1990.
; Modified    : 
;	Version 1, William Thompson, GSFC, 11 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 11 May 1993.
;-
;
	TVSELECT, DISABLE=DISABLE
	ERASE
	TVUNSELECT, DISABLE=DISABLE
;
	RETURN
	END
