	PRO REMOVE_SPOT,IMAGE,MX,MY,IX,IY,MISSING=MISSING,SMOOTH=SMOOTH,   $
		NOSCALE=NOSCALE,DISABLE=DISABLE,COLOR=COLOR,MAX=MAX,MIN=MIN, $
		TOP=TOP,VELOCITY=VELOCITY,COMBINED=COMBINED,LOWER=LOWER, $
		ORIGIN=ORIGIN,SCALE=SCALE,DATA=DATA
;+
; Project     : SOHO - CDS
;
; Name        : 
;	REMOVE_SPOT
; Purpose     : 
;	Sets selected areas of displayed images to a constant background.  
; Explanation : 
;	The TV cursor is activated, and the user is prompted to enter in a 
;	series of points defining a polygon surrounding the region of interest 
;	on the displayed image.  This procedure is completed by entering in the 
;	same point twice.  Then POLYFILLV is used to get the positions of the
;	image within that polygon.  An average value is taken from the points 
;	used to define the polygon, and all points within the polygon are set
;	to this average value.  EXPAND_TV is then used to display the modified
;	image.
; Use         : 
;	REMOVE_SPOT, IMAGE  [, MX, MY, IX, IY ]
; Inputs      : 
;	IMAGE	= Image to remove spot from.
; Opt. Inputs : 
;	MX,MY	= Size of displayed image.
;	IX,IY	= Position of lower left-hand corner of image.
;
;	If the optional parameters are not passed, then they are retrieved with
;	GET_TV_SCALE.  It is anticipated that these optional parameters will
;	only be used in extremely rare circumstances.
;
; Outputs     : 
;	The values of some of the pixels in IMAGE are changed.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	SMOOTH	 = If passed, then interpolation used in expanding array.
;	NOSCALE  = If passed, then the command TV is used instead of TVSCL to
;		   display the image.
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero, except when NOSCALE is set.  Not used in
;		   interpolation.
;	DISABLE  = If set, then TVSELECT not used.
;	COLOR	 = Color used for drawing the box around the image.
;	MAX	 = The maximum value of ARRAY to be considered in scaling the
;		   image, as used by BYTSCL.  The default is the maximum value
;		   of ARRAY.
;	MIN	 = The minimum value of ARRAY to be considered in scaling the
;		   image, as used by BYTSCL.  The default is the minimum value
;		   of ARRAY.
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
;	ORIGIN	 = Two-element array containing the coordinate value in
;		   physical units of the center of the first pixel in the
;		   image.  If not passed, then [0,0] is assumed.
;	SCALE	 = Pixel scale in physical units.  Can have either one or two
;		   elements.  If not passed, then 1 is assumed in both
;		   directions.
;	DATA	 = If set, then immediately activate the data coordinates for
;		   the displayed image.
; Calls       : 
;	AVERAGE, EXPAND_TV, GET_IM_KEYWORD, GET_TV_SCALE, INTERP2, TVPOINTS
; Common      : 
;	None.
; Restrictions: 
;	Since this routine works interactively with the cursor, the image 
;	must be displayed on the TV screen.  It is best if the image is
;	displayed using EXPTV.  But other methods of display are supported by
;	passing MX, MY, and IX, IY directly to the procedure.
;
;	It is important that the user select the graphics device/window, and
;	image region before calling this routine.  For instance, if the image
;	was displayed using EXPTV,/DISABLE, then this routine should also be
;	called with the /DISABLE keyword.  If multiple images are displayed
;	within the same window, then use SETIMAGE to select the image before
;	calling this routine.
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
;	A polygon surrounding the selected area is drawn on the image display 
;	screen.  When the polygon is completed, the new image is displayed over
;	the old image, and the polygon disappears.
;
;	Messages about the size and position of the displayed image are printed
;	to the terminal screen.  This can be turned off by setting !QUIET to 1.
;
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	W.T.T., Oct. 1987.
;	W.T.T., Jan. 1991, changed FLAG to keyword BADPIXEL.
;	W.T.T., Nov. 1991, added MAX, MIN, and TOP keywords.
;	W.T.T., Nov. 1991, added INTENSITY, VELOCITY and COMBINED keywords.
;	W.T.T., Feb. 1992, added LOWER keyword.
;	William Thompson, May 1992, changed to call GET_TV_SCALE.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
;	William Thompson, September 1992, use COMBINED keyword in place of
;					  INTENSITY.
; Written     : 
;	William Thompson, GSFC, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 12 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 2 September 1993.
;		Added ORIGIN, SCALE and DATA keywords.
; Version     : 
;	Version 2, 2 September 1993.
;-
;
	ON_ERROR,2
	GET_IM_KEYWORD, MISSING, !IMAGE.MISSING
;
	IF (N_PARAMS(0) NE 1) AND (N_PARAMS(0) NE 5) THEN BEGIN
		PRINT,'*** REMOVE_SPOT must be called with 1 or 5 parameters:'
		PRINT,'             IMAGE  [, MX, MY, IX, IY ]'
	ENDIF
;
	S = SIZE(IMAGE)
	IF S(0) NE 2 THEN BEGIN
		PRINT,'*** Variable must be two-dimensional, name= IMAGE, routine REMOVE_SPOT.'
		RETURN
	ENDIF
;
	IF N_PARAMS(0) EQ 1 THEN BEGIN
		GET_TV_SCALE,SX,SY,MX,MY,IX,IY,DISABLE=DISABLE
		IF (SX NE S(1)) OR (SY NE S(2)) THEN MESSAGE,	$
			'IMAGE size does not agree with displayed image'
	ENDIF
;
	IF ((MX LE 1) OR (MY LE 1)) THEN BEGIN
		PRINT,'*** The dimensions MX,MY must be > 1, routine REMOVE_SPOT.'
		RETURN
	ENDIF
;
;  Call TVPOINTS to get an array of points on the image, using the cursor.  The
;  last parameter, 1, tells TVPOINTS to close the polygon.
;
	TVPOINTS,XVAL,YVAL,MX,MY,S(1),S(2),IX,IY,1,DISABLE=DISABLE
	NX = N_ELEMENTS(XVAL)
	IF NX LT 3 THEN BEGIN
		PRINT,'*** Must have at least three points, routine REMOVE_SPOT.'
		RETURN
	ENDIF
	POS = POLYFILLV(XVAL,YVAL,S(1),S(2))
	AVER = INTERP2(IMAGE,XVAL,YVAL,MISSING=MISSING)
	IF N_ELEMENTS(MISSING) EQ 1 THEN	$
		AVER = AVERAGE(AVER(WHERE(AVER NE MISSING))) ELSE	$
		AVER = AVERAGE(AVER)
	IMAGE(POS) = AVER
;
	EXPAND_TV,IMAGE,MX,MY,IX,IY,SMOOTH=SMOOTH,/NOBOX,	$
		NOSCALE=NOSCALE,MISSING=MISSING,DISABLE=DISABLE,	$
		COLOR=COLOR,MAX=MAX,MIN=MIN,TOP=TOP,VELOCITY=VELOCITY,	$
		COMBINED=COMBINED,LOWER=LOWER,ORIGIN=ORIGIN,SCALE=SCALE,$
		DATA=DATA
;
	RETURN
	END
