	PRO LOAD_VEL, REVERSE_SWITCH=REVERSE_SWITCH,	$
		GREEN_SWITCH=GREEN_SWITCH, LIGHTEN=LIGHTEN,	$
		TURQUOISE=TURQUOISE, DISABLE=DISABLE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	LOAD_VEL
; Purpose     : 
;	Loads a velocity color table.
; Explanation : 
;	Loads a velocity color table.  Velocity arrays can be scaled for 
;	display for this color table using FORM_VEL.
; Use         : 
;	LOAD_VEL
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
; Calls       : 
;	TVSELECT, TVUNSELECT
; Common      : 
;	COLORS:	The IDL color common block.
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
;	W.T.T., Oct. 1987.
;	W.T.T., Nov. 1990.  Modified for version 2 of IDL.
;	W.T.T., Dec. 1990.  Modified so that normally the positive velocities
;		are blue and the negative velocities are red.  This seems
;		closer to standard usage.
;	W.T.T., Jan. 1991.  Changed REVERSE_SWITCH to keyword.  Added keywords
;			    GREEN_SWITCH and LIGHTEN.
;	William Thompson, April 1992, removed common block COLORS, and added
;				      DISABLE keyword.
;	W.T.T., Jun. 1992.  Changed so that topmost color reserved for
;			    overplotting with white lines.
;	W.T.T., Sep. 1992.  Returned COLORS common block.
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
	COMMON COLORS, RED, GREEN, BLUE, R_CURR, G_CURR, B_CURR
;
;  Form the color tables.
;
	TVSELECT, DISABLE=DISABLE
	NCOLORS = !D.N_COLORS - 2
	BLUE = BYTE( (INDGEN(NCOLORS) + 1)*255./NCOLORS )
	RED = REVERSE(BLUE)
	GREEN = BYTE((2*(RED < BLUE) - 128) > 0)
	RED   = [0B, RED,   255]
	GREEN = [0B, GREEN, 255]
	BLUE  = [0B, BLUE,  255]
;
;  If requested, switch the red and blue color tables.
;
	IF KEYWORD_SET(REVERSE_SWITCH) THEN BEGIN
		TEMP = RED
		RED = BLUE
		BLUE = TEMP
	ENDIF
;
;  If requested, use turquoise instead of blue.
;
	IF KEYWORD_SET(TURQUOISE) THEN BEGIN
		GREEN = 255B < (GREEN > ((2*BLUE - 255) > 0))
;
;  If requested, use green instead of blue.
;
	END ELSE IF KEYWORD_SET(GREEN_SWITCH) THEN BEGIN
		TEMP  = GREEN
		GREEN = BLUE
		BLUE  = TEMP
;
;  If requested, then lighten the color table by adding some green.
;
	END ELSE IF KEYWORD_SET(LIGHTEN) THEN BEGIN
		GREEN = 255B < (GREEN > (BLUE/2B))
	ENDIF
;
;  Load the color tables.
;
	TVLCT,RED,GREEN,BLUE
	R_CURR = RED
	G_CURR = GREEN
	B_CURR = BLUE
	TVUNSELECT, DISABLE=DISABLE
	RETURN
	END
