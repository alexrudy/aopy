	FUNCTION IM_KEYWORD_SET, KEYWORD, IMAGE_KEYWORD
;+
; Project     : SOHO - CDS
;
; Name        : 
;	IM_KEYWORD_SET()
; Purpose     : 
;	Checks whether an image display keyword/flag is set.
; Explanation : 
;	Decides whether a particular SERTS image display keyword is set, or
;	whether the equivalent element in the !IMAGE structure is set.  Use
;	this in place of KEYWORD_SET.
; Use         : 
;	Result = IM_KEYWORD_SET( Keyword, !IMAGE.Keyword )
; Inputs      : 
;	KEYWORD		= Keyword to be checked.
;	IMAGE_KEYWORD	= Associated element in the !IMAGE structure variable.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	None.
; Calls       : 
;	None.
; Common      : 
;	None.
; Restrictions: 
;	Should only be used internally to the SERTS image display routines.
;
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
	IF N_PARAMS(0) NE 2 THEN BEGIN
		PRINT,'*** IM_KEYWORD_SET must be called with two parameters:'
		PRINT,'                Keyword, !IMAGE.Keyword'
		RETURN, 0
	ENDIF
;
	IF N_ELEMENTS(KEYWORD) EQ 0 THEN BEGIN
		RETURN, IMAGE_KEYWORD
	END ELSE BEGIN
		RETURN, KEYWORD_SET(KEYWORD)
	ENDELSE
;
	END
