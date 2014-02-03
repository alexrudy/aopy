	PRO GET_IM_KEYWORD, KEYWORD, IMAGE_KEYWORD
;+
; Project     : SOHO - CDS
;
; Name        : 
;	GET_IM_KEYWORD
; Purpose     : 
;	Gets the value of a SERTS keyword/flag.
; Explanation : 
;	Gets the value of KEYWORD.  For use in SERTS image display routines.
;	If IM_KEYWORD is not already set, then !IMAGE.Keyword is checked.
;
;	If KEYWORD is already defined, then no action is taken.  Otherwise, if
;	!IMAGE.Keyword.SET is set, then KEYWORD is set equal to the value of
;	!IMAGE.Keyword.VALUE.
;
; Use         : 
;	GET_IM_KEYWORD, Keyword, !IMAGE.Keyword
; Inputs      : 
;	KEYWORD		= Keyword variable to be checked.
;	IMAGE_KEYWORD	= Associated element in the !IMAGE structure variable.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	KEYWORD		= If not already defined, and !IMAGE.Keyword.SET is
;			  true, then this is output as the value of
;			  !IMAGE.Keyword.VALUE.  Otherwise it retains its
;			  current value.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	None.
; Calls       : 
;	None.
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
;	William Thompson, June 1991.
; Written     : 
;	William Thompson, GSFC, June 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 13 May 1993.
;-
;
	IF N_ELEMENTS(KEYWORD) EQ 0 THEN	$
		IF IMAGE_KEYWORD.SET THEN KEYWORD = IMAGE_KEYWORD.VALUE
;
	RETURN
	END
