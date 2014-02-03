	PRO WDISPLAY,IMAGE,NOSCALE=NOSCALE,WINDOW=WINDOW,NOEXACT=NOEXACT, $
		SIZE=SIZE,SMOOTH=SMOOTH,MISSING=MISSING,MAX=MAX,MIN=MIN,  $
		TOP=TOP,VELOCITY=VELOCITY,COMBINED=COMBINED,LOWER=LOWER,  $
		RESIZE=RESIZE,RELATIVE=RELATIVE,ORIGIN=ORIGIN,SCALE=SCALE,$
		DATA=DATA,TITLE=TITLE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	WDISPLAY
; Purpose     : 
;	Displays images in a window all their own, sized to fit.
; Explanation : 
;	A window is created with the same size as the image to be displayed.
;	The image is then displayed with EXPAND_TV, and the default window is
;	reset to the previous window.
; Use         : 
;	WDISPLAY, IMAGE
; Inputs      : 
;	IMAGE	= Image to be displayed.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	NOSCALE  = If set, then the command TV is used instead of TVSCL to
;		   display the image.
;	WINDOW	 = Window to use to display the image.  The action that this
;		   program takes depends on the value of this parameter.
;
;			Value		Action
;
;			Undefined	An arbitrary free window is created.
;			Negative	An arbitrary free window is created.
;			0 - 31		The specified window number is used.
;			32 or above	The window specified is deleted, and
;					another arbitrary free window is
;					created.
;
;		   The window used is also returned as an output value in this
;		   parameter.
;
;	RESIZE	 = If set, then the image will be resized up or down by integer
;		   factors to best fit within the display.  Unless RESIZE or
;		   one of the other size related keywords are set, then the
;		   image is displayed at its true pixel size.
;	NOEXACT	 = If set, then non-integer factors are allowed.
;	SIZE	 = If passed and positive, then used to determine the scale of
;		   the image.  Returned as the value of the image scale.
;	SMOOTH	 = If set, then the image is expanded with bilinear
;		   interpolation.
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero.  Ignored if NOSCALE is set.
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
;	RELATIVE = Size of area to be used for displaying the image, relative
;		   to the total size available.  Must be between 0 and 1.
;		   Default is 1.  Ignored unless RESIZE or NOEXACT is set.
;	ORIGIN	 = Two-element array containing the coordinate value in
;		   physical units of the center of the first pixel in the
;		   image.  If not passed, then [0,0] is assumed.
;	SCALE	 = Pixel scale in physical units.  Can have either one or two
;		   elements.  If not passed, then 1 is assumed in both
;		   directions.
;	DATA	 = If set, then immediately activate the data coordinates for
;		   the displayed image.
;	TITLE	 = Window title.
; Calls       : 
;	EXPAND_TV, GET_IM_KEYWORD, IM_KEYWORD_SET, SETWINDOW
; Common      : 
;	None.
; Restrictions: 
;	On SunView displays, the image must be small enough to fit within the
;	display size available.
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
;	William Thompson, Nov. 1992, integrated with SERTS image display
;				     package.
; Written     : 
;	William Thompson, GSFC, 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 4 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 2 September 1993.
;		Added ORIGIN, SCALE and DATA keywords.
;	Version 3, William Thompson, GSFC, 22 December 1993.
;		Added TITLE keyword.
;	Version 4, William Thompson, GSFC, 1 March 1993.
;		Added support for DOS.
; Version     : 
;	Version 4, 1 March 1994.
;-
;
	ON_ERROR,2
;
;  Check the number of parameters passed.
;
	IF N_PARAMS() EQ 0 THEN MESSAGE,'Syntax: WDISPLAY, IMAGE'
;
;  Get the size of the image display screen.
;
	IF !D.NAME EQ 'SUN' THEN BEGIN
		XMAX = 1140
		YMAX = 876
	END ELSE IF HAVE_WINDOWS() THEN BEGIN
		DEVICE,GET_SCREEN_SIZE=WINDOW_SIZE
		XMAX = WINDOW_SIZE(0)-10
		YMAX = WINDOW_SIZE(1)-40
	END ELSE MESSAGE,'WDISPLAY is only supported on windowing systems.'
;
;  Get the size of the image.
;
	SZ = SIZE(IMAGE)
	IF SZ(0) NE 2 THEN BEGIN
		PRINT,'*** IMAGE must be two-dimensional, routine WDISPLAY.'
		RETURN
	ENDIF
;
;  Get the value of the RELATIVE keyword.
;
	REL = 1
	GET_IM_KEYWORD,RELATIVE,!IMAGE.RELATIVE
	IF N_ELEMENTS(RELATIVE) EQ 1 THEN BEGIN
		IF (RELATIVE GT 0) AND (RELATIVE LE 1) THEN REL = RELATIVE
	ENDIF
;
;  Decide what size to display the image.
;
	SX = SZ(1)
	SY = SZ(2)
;
	NNX = REL * XMAX / FLOAT(SX)
	IF NOT IM_KEYWORD_SET(NOEXACT,!IMAGE.NOEXACT) THEN BEGIN
		IF NNX GE 1 THEN NNX = FIX(NNX) ELSE BEGIN
			INV = FIX(1 / NNX)
			IF INV*NNX LT 1 THEN INV = INV + 1
			NNX = 1. / INV
		ENDELSE
	ENDIF
;
	NNY = REL * YMAX / FLOAT(SY)
	IF NOT IM_KEYWORD_SET(NOEXACT,!IMAGE.NOEXACT) THEN BEGIN
		IF NNY GE 1 THEN NNY = FIX(NNY) ELSE BEGIN
			INV = FIX(1 / NNY)
			IF INV*NNY LT 1 THEN INV = INV + 1
			NNY = 1. / INV
		ENDELSE
	ENDIF
;
;  If the parameter SIZE has been passed, then replace NNX and NNY with SIZE.
;  Otherwise, store the smaller of NNX and NNY in SIZE.
;
	GET_IM_KEYWORD, SIZE, !IMAGE.SIZE
	SIZE_SET = 0
	IF N_ELEMENTS(SIZE) EQ 1 THEN BEGIN
		IF SIZE GT 0 THEN BEGIN
			NNX = SIZE
			NNY = SIZE
			SIZE_SET = 1
		ENDIF
	ENDIF
	SIZE = NNX < NNY
;
;  Unless one of the size keywords has been set, then reset the size to the
;  true image size.  It's not sufficient simply to depend on the !IMAGE flags.
;
	IF (NOT KEYWORD_SET(RESIZE)) AND (NOT KEYWORD_SET(NOEXACT))	$
		AND (NOT SIZE_SET) THEN SIZE = 1
;
;  Use SIZE to determine the size of the expanded image MX, MY.
;
	MX = FIX(SX*SIZE)
	MY = FIX(SY*SIZE)
;
;  Make sure the image will fit on the display (SunView only).
;
	IF !D.NAME EQ 'SUN' THEN BEGIN
		IF MX GT XMAX THEN MESSAGE,'IMAGE is too wide to display'
		IF MY GT YMAX THEN MESSAGE,'IMAGE is too tall to display'
	ENDIF
;
;  Decide whether or not to allocate an arbitrary free window, and whether a
;  previously defined arbitrary free window needs to be deleted.  Create a
;  window of the correct size.
;
	GRAPHICS_WINDOW = !D.WINDOW
	ALLOCATE_FREE = 1
	IF (N_ELEMENTS(WINDOW) EQ 1) THEN BEGIN
		IF WINDOW GT 31 THEN BEGIN
			WDELETE, WINDOW
		END ELSE IF WINDOW GE 0 THEN BEGIN
			ALLOCATE_FREE = 0
		ENDIF
	ENDIF
	IF ALLOCATE_FREE THEN BEGIN
		IF N_ELEMENTS(TITLE) EQ 1 THEN BEGIN
			WINDOW, XSIZE=MX, YSIZE=MY, /FREE, TITLE=TITLE
		END ELSE BEGIN
			WINDOW, XSIZE=MX, YSIZE=MY, /FREE
		ENDELSE
		WINDOW = !D.WINDOW
	END ELSE BEGIN
		IF N_ELEMENTS(TITLE) EQ 1 THEN BEGIN
			WINDOW, XSIZE=MX, YSIZE=MY, WINDOW, TITLE=TITLE
		END ELSE BEGIN
			WINDOW, XSIZE=MX, YSIZE=MY, WINDOW
		ENDELSE
	ENDELSE
;
;  Display the image in the window, and reset to the previous window.
;
	EXPAND_TV,IMAGE,NOSCALE=NOSCALE,MX,MY,0,0,/NOBOX,/DISABLE,	$
		SMOOTH=SMOOTH,MISSING=MISSING,MAX=MAX,MIN=MIN,TOP=TOP,	$
		VELOCITY=VELOCITY,COMBINED=COMBINED,LOWER=LOWER,	$
		ORIGIN=ORIGIN,SCALE=SCALE
	IF GRAPHICS_WINDOW NE -1 THEN WSET, GRAPHICS_WINDOW
;
;  If the DATA keyword was set, then activate the data coordinates.
;
	IF KEYWORD_SET(DATA) THEN BEGIN
		SETWINDOW, WINDOW
		SETIMAGE, /CURRENT, /DATA, /DISABLE
		IF GRAPHICS_WINDOW NE -1 THEN SETWINDOW, GRAPHICS_WINDOW
	ENDIF
;
	RETURN
	END
