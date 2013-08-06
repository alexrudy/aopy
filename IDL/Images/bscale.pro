	PRO BSCALE,IMAGE,NOSCALE=NOSCALE,MISSING=MISSING,MAX=MAX,MIN=MIN, $
		TOP=TOP,VELOCITY=VELOCITY,COMBINED=COMBINED,LOWER=LOWER
;+
; Project     : SOHO - CDS
;
; Name        : 
;	BSCALE
; Purpose     : 
;	Scale images into byte arrays suitable for displaying.
; Explanation : 
;	Depending on the keywords passed, the routine BYTSCLI, FORM_INT or
;	FORM_VEL is used to scale the image.
; Use         : 
;	BSCALE, IMAGE
; Inputs      : 
;	IMAGE	= Image to be scaled.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	IMAGE	= The scaled image is returned in place of the original.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	NOSCALE  = If set, then the image is not scaled.
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero.
;	MAX	 = The maximum value of IMAGE to be considered in scaling the
;		   image, as used by BYTSCL.  The default is the maximum value
;		   of IMAGE.
;	MIN	 = The minimum value of IMAGE to be considered in scaling the
;		   image, as used by BYTSCL.  The default is the minimum value
;		   of IMAGE.
;	TOP	 = The maximum value of the scaled image array, as used by
;		   BYTSCL.  The default is !D.N_COLORS-1.
;	VELOCITY = If set, then the image is scaled using FORM_VEL as a
;		   velocity image.  Can be used in conjunction with COMBINED
;		   keyword.  Ignored if NOSCALE is set.
;	COMBINED = Signals that the image is to be displayed in one of two
;		   combined color tables.  Can be used by itself, or in
;		   conjunction with the VELOCITY or LOWER keywords.
;	LOWER	 = If set, then the image is placed in the lower part of the
;		   color table, rather than the upper.  Used in conjunction
;		   with COMBINED keyword.
; Calls       : 
;	BYTSCLI, FORM_INT, FORM_VEL, GET_IM_KEYWORD, IM_KEYWORD_SET
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
;	William Thompson, May 1992.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
;	William Thompson, September 1992, use COMBINED keyword in place of
;					  INTENSITY.
; Written     : 
;	William Thompson, GSFC, May 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 14 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 14 June 1993.
;		Added support for monochrome (dithered) devices.
;	Version 3, William Thompson, GSFC, 22 October 1993.
;		Modified to call BYTSCLI instead of BYTSCL.
; Version     : 
;	Version 3, 22 October 1993.
;-
;
	ON_ERROR,2
	GET_IM_KEYWORD, MISSING, !IMAGE.MISSING
;
	IF N_PARAMS() EQ 0 THEN MESSAGE,'Syntax:  Result = BSCALE( IMAGE )'
;
;  Find out how to scale the image.  The possibilities are either no scaling,
;  intensity scaling, velocity scaling, or ordinary scaling.  The default is
;  the last.
;
	IF IM_KEYWORD_SET(NOSCALE,!IMAGE.NOSCALE) THEN RETURN
;
;  Velocity scaling.
;
	IF KEYWORD_SET(VELOCITY) THEN BEGIN
		IMAGE = FORM_VEL(IMAGE,MIN=MIN,MAX=MAX,MISSING=MISSING, $
			COMBINED=COMBINED)
;
;  Intensity scaling (for combining with velocity images).
;
	END ELSE IF IM_KEYWORD_SET(COMBINED,!IMAGE.COMBINED) OR		$
			KEYWORD_SET(LOWER) THEN BEGIN
		IMAGE = FORM_INT(IMAGE,MIN=MIN,MAX=MAX,MISSING=MISSING, $
			LOWER=LOWER)
;
;  Ordinary scaling.  First, set any missing pixels to the mininum of the good
;  array.
;
	END ELSE BEGIN
		IF (N_ELEMENTS(MISSING) EQ 1) THEN BEGIN
			IMIN = MIN(IMAGE(WHERE(IMAGE NE MISSING)))
			W = WHERE(IMAGE EQ MISSING, COUNT)
			IF COUNT NE 0 THEN IMAGE(W) = IMIN
		ENDIF
;
;  Use BYTSCLI to scale the image.
;
		COMMAND = 'IMAGE = BYTSCLI(IMAGE'
;
		GET_IM_KEYWORD,MAX,!IMAGE.MAX
		IF N_ELEMENTS(MAX) EQ 1 THEN COMMAND = COMMAND + ',MAX=MAX'
;
		GET_IM_KEYWORD,MIN,!IMAGE.MIN
		IF N_ELEMENTS(MIN) EQ 1 THEN COMMAND = COMMAND + ',MIN=MIN'
;
;  The default top color depends on whether the device is monochrome or not.
;
		DEFAULT_TOP = !D.N_COLORS - 1
		IF DEFAULT_TOP EQ 1 THEN DEFAULT_TOP = 255
		GET_IM_KEYWORD, TOP, !IMAGE.TOP
		IF N_ELEMENTS(TOP) EQ 1 THEN	$
			COMMAND = COMMAND + ',TOP=TOP' ELSE	$
			COMMAND = COMMAND + ',TOP=DEFAULT_TOP'
;
		TEST = EXECUTE(COMMAND + ')')
	ENDELSE
;
	RETURN
	END
