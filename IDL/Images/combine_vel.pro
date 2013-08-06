	PRO COMBINE_VEL, REVERSE_SWITCH=REVERSE_SWITCH,		$
		GREEN_SWITCH=GREEN_SWITCH, LIGHTEN=LIGHTEN,	$
		TURQUOISE=TURQUOISE,DISABLE=DISABLE,PRELOADED=PRELOADED
;+
; Project     : SOHO - CDS
;
; Name        : 
;	COMBINE_VEL
; Purpose     : 
;	Combines current color table with a velocity color table.
; Explanation : 
;	Combines the current color table with the velocity color table as
;	formed by LOAD_VEL.
;
;	The procedure gets the current color tables using TVLCT,/GET, and then
;	uses LOAD_VEL to get the velocity color table.
; 
;	To use this color table, scale velocities using FORM_VEL with the
;	/COMBINED keyword, and scale intensities using FORM_INT.  Alternately,
;	use the /COMBINED and /VELOCITY keywords with EXPTV and PUT, which then
;	call FORM_INT and FORM_VEL automatically.
; 
; Use         : 
;	COMBINE_VEL
;
;	The following example shows how to put an intensity image I next to its
;	corresponding velocity image V.  Standard color table #3 is used for
;	the intensity image.
; 
;	LOADCT,3			   ;Select color table for int. image
;	COMBINE_VEL			   ;Combine with velocity color table
;	PUT,I,1,2,/COMBINED		   ;Display intensity image on left
;	PUT,V,2,2,/COMBINED,/VELOCITY	   ;And velocity on right
; 
; Inputs      : 
;	None.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	REVERSE_SWITCH	= If passed, and non-zero, then the red and blue color
;			  tables in the velocity color table are switched.
;	TURQUOISE	= If set, then turquoise is used instead of blue.
;	GREEN_SWITCH	= If set, then red and green are used instead of red
;			  and blue.  Ignored if TURQUOISE is set.
;	LIGHTEN		= If set, then some green is added to the blue to
;			  lighten the image.  Ignored if TURQUOISE or
;			  GREEN_SWITCH are set.
;	DISABLE		= If set, then TVSELECT not used.
;	PRELOADED	= If set, then a color table preloaded using
;			  COMBINE_VEL or COMBINE_COLORS is combined with the
;			  velocity color table instead of the current table.
; Calls       : 
;	COMBINE_COLORS, LOAD_VEL, TVSELECT, TVUNSELECT
; Common      : 
;	None, but calls COMBINE_COLORS which uses the COLORS and COMBINE_COL
;	common blocks.
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
;	The color table is changed so that values in the lower half of the
;	device range (typically 0-127) represent velocities as formed by the
;	routine FORM_VEL, and values in the upper half (typically 128-255)
;	represent intensities.  Each part of the color table has only half the
;	resolution of the original color tables.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	W.T.T., Oct. 1987.
;	W.T.T., Nov. 1990.  Modified for version 2 of IDL.
;	W.T.T., Jan. 1991.  Changed REVERSE_SWITCH to keyword.  Added keywords
;		GREEN_SWITCH and LIGHTEN.
;	William Thompson, April 1992, changed to use TVLCT,/GET instead of
;		common block, and added DISABLE keyword.
;	W.T.T., Sep. 1992.  Returned COLORS common block.
;	William Thompson, Oct 1992, changed to use COMBINE_COLORS, and added
;		PRELOADED keyword.
; Written     : 
;	William Thompson, GSFC, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 13 May 1993.
;-
;
	ON_ERROR,2
;
;  Select the proper image display device.
;
	TVSELECT, DISABLE=DISABLE
;
;  Unless the preloaded keyword is set, get the current color table and load it
;  into the upper part of the combined color table.
;
	IF NOT KEYWORD_SET(PRELOADED) THEN COMBINE_COLORS,/UPPER,/DISABLE
;
;  Load the velocity color table, and combine with the color table saved above.
;
	LOAD_VEL,REVERSE_SWITCH=REVERSE_SWITCH,GREEN_SWITCH=GREEN_SWITCH,  $
		LIGHTEN=LIGHTEN,TURQUOISE=TURQUOISE,/DISABLE
	COMBINE_COLORS,/LOWER,/DISABLE
	TVUNSELECT, DISABLE=DISABLE
;
	RETURN
	END
