	PRO XBLINK,ARRAY1,ARRAY2,RATE,NOSCALE=NOSCALE,MISSING=MISSING,	$
		MAX=MAX,MIN=MIN,TOP=TOP,VELOCITY=VELOCITY,COMBINED=COMBINED, $
		LOWER=LOWER,NOEXACT=NOEXACT,SIZE=SIZE,SMOOTH=SMOOTH,	$
		RESIZE=RESIZE,RELATIVE=RELATIVE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	XBLINK
; Purpose     : 
;	Blinks two images together by using XMOVIE.
; Explanation : 
;	XMOVIE is called to blink the two images together.
; Use         : 
;	XBLINK, ARRAY1, ARRAY2  [, RATE ]
; Inputs      : 
;	ARRAY1	 = First image to be blinked against the second image.
;	ARRAY2	 = Second image.  Must have the same dimensions as the first
;		   image.
; Opt. Inputs : 
;	RATE	= Optional rate of display.  The rate is a value between 0 and
;		  100 that gives the speed that the animation is displayed.
;		  The fastest animation is with a value of 100 and the slowest
;		  is with a value of 0.  The default value is 10 if not
;		  specified.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	NOSCALE  = If set, then the images are not scaled.
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero.
;	MAX	 = The maximum value to be considered in scaling the
;		   images, as used by BYTSCL.  The default is the maximum value
;		   of IMAGES.
;	MIN	 = The minimum value of IMAGES to be considered in scaling the
;		   image, as used by BYTSCL.  The default is the minimum value
;		   of IMAGES.
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
;	RESIZE	 = If set, then the image will be resized up or down by integer
;		   factors to best fit within the display.  Unless RESIZE or
;		   one of the other size related keywords are set, then the
;		   image is displayed at its true pixel size.
;	NOEXACT	 = If set, then non-integer factors are allowed.
;	SIZE	 = If passed and positive, then used to determine the scale of
;		   the image.  Returned as the value of the image scale.
;	SMOOTH	 = If set, then the image is expanded with bilinear
;		   interpolation.
;	RELATIVE = Size of area to be used for displaying the image, relative
;		   to the total size available.  Must be between 0 and 1.
;		   Default is 1.  Ignored unless RESIZE or NOEXACT is set.
; Calls       : 
;	XMOVIE
; Common      : 
;	None.
; Restrictions: 
;	ARRAY1 and ARRAY2 must have the same dimensions.
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
;	Modified from BLINK.
; Written     : 
;	William Thompson, GSFC, 7 September 1994
; Modified    : 
;	Version 1, William Thompson, GSFC, 7 September 1994
; Version     : 
;	Version 1, 7 September 1994
;-
;
	ON_ERROR, 2
;
;  Check the input parameters.
;
	IF N_PARAMS() LT 2 THEN MESSAGE,	$
		'Syntax:  XBLINK, ARRAY1, ARRAY2  [, RATE ]'
;
	SZ1 = SIZE(ARRAY1)
	SZ2 = SIZE(ARRAY2)
	IF SZ1(0) NE 2 THEN MESSAGE, 'ARRAY1 must be two-dimensional'
	IF SZ2(0) NE 2 THEN MESSAGE, 'ARRAY2 must be two-dimensional'
	IF (SZ1(1) NE SZ2(1)) OR (SZ1(2) NE SZ2(2)) THEN MESSAGE,	$
		'ARRAY1 and ARRAY2 must have the same dimensions'
;
;  If RATE was not passed, then set it to 10.
;
	IF N_ELEMENTS(RATE) EQ 0 THEN RATE = 10
;
;  Concatenate ARRAY1 and ARRAY2 into a single array, and display it.
;
	XMOVIE, REFORM( [ARRAY1(*),ARRAY2(*)], SZ1(1), SZ1(2), 2 ), RATE, $
		NOSCALE=NOSCALE,MISSING=MISSING,MAX=MAX, $
		MIN=MIN,TOP=TOP,VELOCITY=VELOCITY,COMBINED=COMBINED,	$
		LOWER=LOWER,NOEXACT=NOEXACT,SIZE=SIZE,SMOOTH=SMOOTH,	$
		RESIZE=RESIZE,RELATIVE=RELATIVE
;
	RETURN
	END
