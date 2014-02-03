	PRO INT_STRETCH, LOW, HIGH, GAMMA, LOWER=LOWER, DISABLE=DISABLE, $
		CHOP=CHOP
;+
; Project     : SOHO - CDS
;
; Name        : 
;	INT_STRETCH
; Purpose     : 
;	Stretch one of two combined intensity color tables.
; Explanation : 
;	Stretch one of the two combined image display color tables so the full
;	range runs from one color index to another.
;
;	New red, green, and blue vectors are created by linearly interpolating
;	the vectors in the COMBINE_COLORS common block from LOW to HIGH.
;	Vectors in the COMBINE_COLORS common block are not changed.
;
;	If NO parameters are supplied, the original (lower or upper) color
;	tables are restored.
;
; Use         : 
;	INT_STRETCH, LOW, HIGH  [, GAMMA ]
;
;	The following example shows how to put one intensity image I1 using
;	color table #3 next to another image I2 using color table #5, and then
;	stretch the two color tables independently.
; 
;	LOADCT,3				;Select first color table
;	COMBINE_COLORS,/LOWER			;Save lower color table
;	LOADCT,5				;Select second color table
;	COMBINE_COLORS				;Combine the color tables
;	PUT,I1,1,2,/COMBINED,/LOWER		;Display first image on left
;	PUT,I2,2,2,/COMBINED			;And second image on right
;	INT_STRETCH,10,150,/LOWER		;Stretch the first color table
;	INT_STRETCH,30,200			;Stretch the second
;
; Inputs      : 
;	LOW	= The lowest pixel value to use.  If this parameter is omitted,
;		  0 is assumed.  Appropriate values range from 0 to the number
;		  of available colors-1.
;	HIGH	= The highest pixel value to use.  If this parameter is
;		  omitted, the number of colors-1 is assumed.  Appropriate
;		  values range from 0 to the number of available colors-1.
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
;	LOWER	= If set, then the lower color table is stretched, rather than
;		  the upper one.
;	DISABLE	= If set, then TVSELECT is not called.
;	CHOP	= If this keyword is set, color values above the upper
;		  threshold are set to color index 0.  Normally, values above
;		  the upper threshold are set to the maximum color index.
; Calls       : 
;	TVSELECT, TVUNSELECT
; Common      : 
;	COLORS	    = The common block that contains R, G, and B color tables
;		      loaded by LOADCT, HSV, HLS and others.
;	COMBINE_COL = The common block containing the upper and lower color
;		      tables, as loaded by COMBINE_COLORS.
; Restrictions: 
;	The upper and lower color tables must be loaded by COMBINE_COLORS
;	before calling INT_STRETCH.
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
;  Make sure the color tables are defined in COMBINE_COL
;
	IF (NOT KEYWORD_SET(LOWER_SET)) OR (NOT KEYWORD_SET(UPPER_SET))	$
			THEN BEGIN
		MESSAGE,/CONTINUE,	$
			"The combined color table has not been defined."
		GOTO, EXIT_POINT
	ENDIF
;
;  Parse the input parameters.  If any input parameters have not been passed,
;  then set them equal to their default values.
;
	IF N_PARAMS(0) LT 1 THEN LOW = 0
	IF N_PARAMS(0) LT 2 THEN HIGH = NC-1
	IF N_PARAMS(0) LT 3 THEN GAMMA = 1.0
	IF HIGH EQ LOW THEN GOTO, EXIT_POINT	;Nonsensical
;
;  Calculate the mapping between the original and the stretched color table.
;
	IF GAMMA EQ 1.0 THEN BEGIN		;Simple case
		SLOPE = FLOAT(NC-1)/(HIGH-LOW)  ;Scale to range of 0 : nc-1
		INTERCEPT = -SLOPE*LOW
		P = LONG(FINDGEN(NC)*SLOPE+INTERCEPT) ;subscripts to select
	ENDIF ELSE BEGIN			;Gamma ne 0
		SLOPE = 1. / (HIGH-LOW)		;Range of 0 to 1.
		INTERCEPT = -SLOPE * LOW
		P = FINDGEN(NC) * SLOPE + INTERCEPT > 0.0
		P = LONG(NC * (P ^ GAMMA))
	ENDELSE
;
;  If chopping is selected, then modify the mapping accordingly.
;
	IF KEYWORD_SET(CHOP) THEN BEGIN
		TOO_HIGH = WHERE(P GE NC, N)
		IF N GT 0 THEN P(TOO_HIGH)  = 0L
	ENDIF
;
;  Stretch the relevant color table from the common block COMBINE_COL.
;
	NX = !D.N_COLORS/2
	X = BYTE(INDGEN(NX)*2)
	IF KEYWORD_SET(LOWER) THEN BEGIN
		CUR_RED(0)    = LOWER_RED(P(X))
		CUR_GREEN(0)  = LOWER_GREEN(P(X))
		CUR_BLUE(0)   = LOWER_BLUE(P(X))
	END ELSE BEGIN
		CUR_RED(NX)   = UPPER_RED(P(X))
		CUR_GREEN(NX) = UPPER_GREEN(P(X))
		CUR_BLUE(NX)  = UPPER_BLUE(P(X))
	ENDELSE
	TVLCT, CUR_RED, CUR_GREEN, CUR_BLUE
;
EXIT_POINT:
	TVUNSELECT, DISABLE=DISABLE
	RETURN
	END
