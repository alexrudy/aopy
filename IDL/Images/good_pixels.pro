	FUNCTION GOOD_PIXELS,ARRAY,MISSING=MISSING
;+
; Project     : SOHO - CDS
;
; Name        : 
;	GOOD_PIXELS()
; Purpose     : 
;	Returns all the good (not missing) pixels in an image.
; Explanation : 
;	Returns a vector array containing only those pixels that are not equal
;	to the missing pixel flag value.  Mainly used for statistical purposes,
;	e.g. PLOT_HISTO,GOOD_PIXELS(A).  The missing pixel flag can be set
;	either with the MISSING keyword, or with the SETFLAG,MISSING=...
;	command.
; Use         : 
;	Result = GOOD_PIXELS( ARRAY, <keywords> )
; Inputs      : 
;	ARRAY	= Array to be scaled.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	Result of function is a linear array containing the values of all
;	pixels that do not correspond to the missing pixel flag value.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	MISSING = Value flagging missing pixels.
; Calls       : 
;	GET_IM_KEYWORD
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
;	If no missing pixel flag is set, then the original undisturbed array is
;	returned.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, July 1991.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
; Written     : 
;	William Thompson, GSFC, July 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 13 May 1993.
;-
;
	GET_IM_KEYWORD, MISSING, !IMAGE.MISSING
;
	IF N_ELEMENTS(MISSING) EQ 1 THEN	$
		RETURN, ARRAY(WHERE(ARRAY NE MISSING)) ELSE	$
		RETURN, ARRAY
;
	END
