	PRO COMBINE_COLORS, UPPER=UPPER, LOWER=LOWER, DISABLE=DISABLE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	COMBINE_COLORS
; Purpose     : 
;	Combines two color tables into one.
; Explanation : 
;	Combines two color tables into the lower and upper parts of a combined
;	color table.  To use this color table, scale intensities using
;	FORM_INT.  Alternately, use the /COMBINED and /LOWER keywords with
;	EXPTV and PUT, which then call FORM_INT and FORM_VEL automatically.
; Use         : 
;	COMBINE_COLORS
;
;	The following example shows how to put one intensity image I1 using
;	color table #3 next to another image I2 using color table #5.
; 
;	LOADCT,3				;Select first color table
;	COMBINE_COLORS,/LOWER			;Save lower color table
;	LOADCT,5				;Select second color table
;	COMBINE_COLORS				;Combine the color tables
;	PUT,I1,1,2,/COMBINED,/LOWER		;Display first image on left
;	PUT,I2,2,2,/COMBINED			;And second image on right
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
;	UPPER	= Save the current color table in a common block, to be the
;		  upper part of the combined table.  If neither the UPPER nor
;		  LOWER keyword is set, then UPPER is assumed.
;	LOWER	= Save the current color table in a common block, to be
;		  the lower part of the combined table.
;	DISABLE	= If set, then TVSELECT is not used.
; Calls       : 
;	TVSELECT, TVUNSELECT
; Common      : 
;	COLORS:	The IDL color common block.
;	COMBINE_COL: Used internally to save the two color tables between
;	calls.
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
;	device range (typically 0-127) use the first color table, and values in
;	the upper half (typically 128-255) use the second color table.  Each
;	part of the color table has only half the resolution of the original
;	color tables.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	W.T.T., Feb. 1992, from COMBINE_VEL.
;	William Thompson, April 1992, changed to use TVLCT,/GET instead of
;		common block, and added DISABLE keyword.
;	W.T.T., Sep. 1992.  Returned COLORS common block.
;	William Thompson, Oct 1992, added UPPER keyword, and rewrote to allow
;		loading the upper and lower common blocks in any order, and to
;		allow each to be independently reloaded.
; Written     : 
;	William Thompson, GSFC, February 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 14 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 14 May 1993.
;-
;
	COMMON COLORS, RED, GREEN, BLUE, R_CURR, G_CURR, B_CURR
	COMMON COMBINE_COL,LOWER_SET,LOWER_RED,LOWER_GREEN,LOWER_BLUE,	$
			   UPPER_SET,UPPER_RED,UPPER_GREEN,UPPER_BLUE
	ON_ERROR,2
;
;  Get the current color table.
;
	TVSELECT, DISABLE=DISABLE
	TVLCT,RED,GREEN,BLUE,/GET
;
;  Make sure LOWER_SET and UPPER_SET are defined.
;
	IF N_ELEMENTS(LOWER_SET) EQ 0 THEN LOWER_SET = 0
	IF N_ELEMENTS(UPPER_SET) EQ 0 THEN UPPER_SET = 0
;
;  If the LOWER keyword was set, then save the color tables in the lower part
;  of the COMBINE_COL common block.
;
	IF KEYWORD_SET(LOWER) THEN BEGIN
		LOWER_SET   = 1
		LOWER_RED   = RED
		LOWER_GREEN = GREEN
		LOWER_BLUE  = BLUE
	ENDIF
;
;  If the UPPER keyword was set, then save the color tables in the upper part
;  of the COMBINE_COL common block.  UPPER is the default.
;
	IF KEYWORD_SET(UPPER) OR ((NOT KEYWORD_SET(LOWER)) AND	$
			(N_ELEMENTS(UPPER) EQ 0)) THEN BEGIN
		UPPER_SET   = 1
		UPPER_RED   = RED
		UPPER_GREEN = GREEN
		UPPER_BLUE  = BLUE
	ENDIF
;
;  If both the upper and lower color tables have been set, then combine the two
;  color tables.
;
	IF UPPER_SET AND LOWER_SET THEN BEGIN
		X = BYTE(INDGEN(!D.N_COLORS/2)*2)
		RED   = [LOWER_RED(X),  UPPER_RED(X)  ]
		GREEN = [LOWER_GREEN(X),UPPER_GREEN(X)]
		BLUE  = [LOWER_BLUE(X), UPPER_BLUE(X) ]
		TVLCT,RED,GREEN,BLUE
		R_CURR = RED
		G_CURR = GREEN
		B_CURR = BLUE
	ENDIF
;
	TVUNSELECT, DISABLE=DISABLE
	RETURN
	END
