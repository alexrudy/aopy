	PRO VEL_STRETCH, HIGH, GAMMA, COMBINED=COMBINED, DISABLE=DISABLE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	VEL_STRETCH
; Purpose     : 
;	Stretch velocity color tables, either alone or combined.
; Explanation : 
;	Stretches velocity color tables so that zero velocities stay grey, and
;	positive and negative velocities scale together.
;
;	New red, green, and blue vectors are created by linearly interpolating
;	the vectors in the COLORS or COMBINE_COLORS common block from -HIGH to
;	HIGH.  The original vectors in the COMBINE_COLORS common block are not
;	changed.
;
;	If NO parameters are supplied, the original color tables are restored.
;
; Use         : 
;	VEL_STRETCH, HIGH  [, GAMMA ]
;
;	The following example shows how to put an intensity image I using color
;	table #3 next to a velocity image V using the velocity color table, and
;	then stretch the two color tables independently.
; 
;	LOADCT,3			      ;Select intensity color table
;	COMBINE_VEL			      ;Combine with velocity table
;	PUT,I,1,2,/COMBINED		      ;Display intensity image on left
;	PUT,V,2,2,/VELOCITY,/COMBINED	      ;And velocity image on right
;	INT_STRETCH,10,150		      ;Stretch intensity table
;	VEL_STRETCH,0.8,/COMBINED	      ;Stretch velocity table
;
; Inputs      : 
;	HIGH	= The highest scaled velocity value to use.  Can be a number
;		  between 0 and 1.  If omitted, then 1 is assumed.
; Opt. Inputs : 
;	GAMMA	= Gamma correction factor.  If this value is omitted, 1.0 is
;		  assumed.  Gamma correction works by raising the color indices
;		  to the GAMMA power, assuming they are scaled into the range 0
;		  to 1.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	COMBINED= If set, then the lower part of a combined color table is
;		  stretched, rather than the entire color table.
;	DISABLE	= If set, then TVSELECT is not called.
; Calls       : 
;	IM_KEYWORD_SET, TVSELECT, TVUNSELECT
; Common      : 
;	COLORS	    = The common block that contains R, G, and B color tables
;		      loaded by LOADCT, HSV, HLS and others.
;	COMBINE_COL = The common block containing the upper and lower color
;		      tables, as loaded by COMBINE_COLORS.
; Restrictions: 
;	The velocity color tables must be loaded by LOAD_VEL or COMBINE_VEL
;	before calling VEL_STRETCH.
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
;	The values of the current color tables in common block COLORS is
;	changed.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, Oct. 1992, from STRETCH by David M. Stern.
; Written     : 
;	William Thompson, GSFC, October 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 4 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 4 May 1993.
;-
;
	ON_ERROR,2
	COMMON COLORS,ORIG_RED,ORIG_GREEN,ORIG_BLUE,CUR_RED,CUR_GREEN,CUR_BLUE
	COMMON COMBINE_COL,LOWER_SET,LOWER_RED,LOWER_GREEN,LOWER_BLUE,	$
			   UPPER_SET,UPPER_RED,UPPER_GREEN,UPPER_BLUE
;
;  Make sure that the device can support loading color tables.
;
	TVSELECT, DISABLE=DISABLE
	NC = !D.TABLE_SIZE	;# of colors entries in device
	IF NC EQ 0 THEN BEGIN
		MESSAGE,/CONTINUE,	$
			"Device has static color tables--can't modify."
		GOTO, EXIT_POINT
	ENDIF
;
;  Parse the input parameters.  If any input parameters have not been passed,
;  then set them equal to their default values.
;
	IF N_PARAMS(0) LT 1 THEN HIGH  = 1.0
	IF N_PARAMS(0) LT 2 THEN GAMMA = 1.0
	IF HIGH LE 0 THEN GOTO, EXIT_POINT	;Nonsensical
;
;  Calculate the mapping between the original and the stretched color table.
;
	MAXCOLOR = !D.N_COLORS - 2
	COLORRANGE = FIX((MAXCOLOR - 1) / 2) * 1.
	ZEROCOLOR  = FIX((MAXCOLOR + 1) / 2)
;
;  Calculate the mapping, depending on whether GAMMA is 1 or not.
;
	X = FINDGEN(2*COLORRANGE+1) - COLORRANGE
	IF GAMMA EQ 1.0 THEN BEGIN
		SLOPE = 1. / HIGH
		P = 1 > LONG(X*SLOPE + ZEROCOLOR) < MAXCOLOR
	ENDIF ELSE BEGIN
		SLOPE = 1. / HIGH
		SIGN = X / (ABS(X) > 1)
		P = ABS(X * SLOPE / COLORRANGE) ^ GAMMA
		P = 1 > LONG(COLORRANGE * SIGN * P + ZEROCOLOR) < MAXCOLOR
	ENDELSE
;
;  Stretch the relevant color table from either the COLORS or COMBINE_COL
;  common block.
;
	IF IM_KEYWORD_SET(COMBINED,!IMAGE.COMBINED) THEN BEGIN
		IF (NOT KEYWORD_SET(LOWER_SET)) OR	$
				(NOT KEYWORD_SET(UPPER_SET)) THEN BEGIN
			MESSAGE,/CONTINUE,	$
			    "The combined color table has not been defined."
			GOTO, EXIT_POINT
		ENDIF
		X = BYTE(INDGEN(N_ELEMENTS(P)/2)*2)
		CUR_RED(1)    = LOWER_RED(P(X))
		CUR_GREEN(1)  = LOWER_GREEN(P(X))
		CUR_BLUE(1)   = LOWER_BLUE(P(X))
	END ELSE BEGIN
		IF N_ELEMENTS(CUR_RED) EQ 0 THEN	$
			TVLCT,CUR_RED,CUR_GREEN,CUR_BLUE,/GET
		CUR_RED   = ORIG_RED
		CUR_GREEN = ORIG_GREEN
		CUR_BLUE  = ORIG_BLUE
		CUR_RED(1)   = CUR_RED(P)
		CUR_GREEN(1) = CUR_GREEN(P)
		CUR_BLUE(1)  = CUR_BLUE(P)
	ENDELSE
	TVLCT, CUR_RED, CUR_GREEN, CUR_BLUE
;
EXIT_POINT:
	TVUNSELECT, DISABLE=DISABLE
	RETURN
	END
