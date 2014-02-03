	PRO OPLOT_IMAGE,IMAGE,ORIGIN=ORIGIN,SCALE=SCALE,SMOOTH=SMOOTH,	$
		NOSCALE=NOSCALE,MISSING=MISSING,COLOR=COLOR,MAX=MAX,	$
		MIN=MIN,TOP=TOP,VELOCITY=VELOCITY,COMBINED=COMBINED,	$
		LOWER=LOWER
;+
; Project     : SOHO - CDS
;
; Name        : 
;	OPLOT_IMAGE
; Purpose     : 
;	Overplot an image.
; Explanation : 
;	Displays images over pre-existing plots.  The concept is to make
;	displaying an image a graphics command, like OPLOT or OCONTOUR.  Then
;	the special TV calls don't have to be used.
; Use         : 
;	OPLOT_IMAGE, IMAGE
; Inputs      : 
;	IMAGE	 = Two dimensional image array to be displayed.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	ORIGIN	 = Two-element array containing the coordinate value in
;		   physical units of the center of the first pixel in the
;		   image.  If not passed, then [0,0] is assumed.
;	SCALE	 = Pixel scale in physical units.  Can have either one or two
;		   elements.  If not passed, then 1 is assumed in both
;		   directions.
;	SMOOTH	 = If set, then the image is expanded with bilinear
;		   interpolation.
;	NOSCALE  = If set, then the command TV is used instead of TVSCL to
;		   display the image.
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero.  Ignored if NOSCALE is set.
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
; Calls       : 
;	EXPAND_TV
; Common      : 
;	None.
; Restrictions: 
;	The graphics device must be capable of displaying images.
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
;	Messages about the size and position of the displayed image are printed
;	to the terminal screen.  This can be turned off by setting !QUIET to 1.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, May 1992.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
;	William Thompson, September 1992, use COMBINED keyword in place of
;		INTENSITY.
;	William Thompson, October 1992, modified so that keyword ORIGIN refers
;		to the center of the first pixel, rather than to the lower left
;		corner.
; Written     : 
;	William Thompson, GSFC, May 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 9 November 1993.
;		Removed restriction that scales be positive.
; Version     : 
;	Version 2, 9 November 1993.
;-
;
	ON_ERROR,2
;
;  Check the number of parameters.
;
	IF N_PARAMS() NE 1 THEN MESSAGE,'Syntax:  OPLOT_IMAGE, IMAGE'
;
;  Check the image size.
;
	SZ = SIZE(IMAGE)
	IF SZ(0) NE 2 THEN MESSAGE,'IMAGE must be two-dimensional'
;
;  Get the image origin.
;
	IF N_ELEMENTS(ORIGIN) EQ 0 THEN BEGIN
		ORIGIN = [0,0]
	END ELSE IF N_ELEMENTS(ORIGIN) NE 2 THEN BEGIN
		MESSAGE,'ORIGIN must have two elements'
	ENDIF
;
;  Get the image scale.
;
	CASE N_ELEMENTS(SCALE) OF
		0:  BEGIN
			XSCALE = 1
			YSCALE = 1
			END
		1:  BEGIN
			XSCALE = SCALE
			YSCALE = SCALE
			END
		2: BEGIN
			XSCALE = SCALE(0)
			YSCALE = SCALE(1)
			END
	ENDCASE
;
;  Set the image display parameters, and display the image.
;
	XS = !X.S * !D.X_SIZE
	YS = !Y.S * !D.Y_SIZE
	MX = XS(1)*SZ(1)*XSCALE
	MY = YS(1)*SZ(2)*YSCALE
	IX = XS(0) + (ORIGIN(0) - XSCALE/2.)*XS(1)
	IY = YS(0) + (ORIGIN(1) - YSCALE/2.)*YS(1)
;
	IM = IMAGE
	IF MX LT 0 THEN BEGIN
		MX = ABS(MX)
		IX = IX - MX
		IM = REVERSE(IM,1)
	ENDIF
	IF MY LT 0 THEN BEGIN
		MY = ABS(MY)
		IY = IY - MX
		IM = REVERSE(IM,2)
	ENDIF
	EXPAND_TV,IM,MX,MY,IX,IY,SMOOTH=SMOOTH,/NOBOX,NOSCALE=NOSCALE,	$
		MISSING=MISSING,/DISABLE,COLOR=COLOR,MAX=MAX,MIN=MIN,	$
		TOP=TOP,VELOCITY=VELOCITY,COMBINED=COMBINED,LOWER=LOWER,$
		/NOSTORE
;
	RETURN
	END
