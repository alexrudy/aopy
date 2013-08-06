	PRO PUT,ARRAY,IIX,NNX,IIY,NNY,NOSQUARE=NOSQUARE,SMOOTH=SMOOTH,	$
		NOBOX=NOBOX,NOSCALE=NOSCALE,MISSING=MISSING,SIZE=SIZE,	$
		DISABLE=DISABLE,NOEXACT=NOEXACT,XALIGN=XALIGN,YALIGN=YALIGN, $
		RELATIVE=RELATIVE,COLOR=COLOR,MAX=MAX,MIN=MIN,TOP=TOP,	$
		VELOCITY=VELOCITY,COMBINED=COMBINED,LOWER=LOWER,	$
		NORMAL=NORMAL,ORIGIN=ORIGIN,SCALE=SCALE,DATA=DATA
color=!p.color
;fix for a change in how IDL handles color, appliedby bmac jan 2013

;+
; Project     : SOHO - CDS
;
; Name        : 
;	PUT
; Purpose     : 
;	Places one of several images on the image display screen.
; Explanation : 
;	Uses SETIMAGE, SCALE_TV and EXPAND_TV to place an image on the TV
;	display screen.  The image is placed at position IX out of NX from the
;	left and position IY out of NY from the top.
; Use         : 
;	PUT, ARRAY, II, NN
;	PUT, ARRAY, IX, NX, IY, NY
;	PUT, ARRAY, X1, X2, Y1, Y2, /NORMAL
;
;	Examples: Display the third in a series of five images, and let the
;	computer decide how to arrange the images.  All of the images should be
;	of the same size.
;
;		PUT, image, 3, 5
;
;	In this example, the computer will decide to put the images into one of
;	the following configurations, depending on the size of the screen, and
;	the size of the images.
;
;		1       1 2     1 2 3     1 2 3 4     1 2 3 4 5
;		2       3 4     4 5       5
;		3       5
;		4
;		5
;
;	Display an image as the third of five from the left, and the second of
;	three from the top.
;
;		PUT, image, 3, 5, 2, 3
;
;	Display an image in a box using the top 80% of the screen, with 5%
;	margins on either side.
;
;		PUT, image, 0.05, 0.95, 0.2, 1, /NORMAL
;
; Inputs      : 
;	ARRAY	 = Image to be displayed.
;
;	Also, either the parameters II, NN or the parameters IX, NX, IY, NY
;	must be passed.
;
; Opt. Inputs : 
;
;	II, NN	 = Relative position within a series of NN images.  The program
;		   chooses how to arrange the images along the X and Y axes
;		   depending on the size of the image and the size of the
;		   window.
;
;		or
;
;	IX, NX	= Relative position along X axis, expressed as position IX
;		  out of a possible NX, from left to right.
;	IY, NY	= Relative position along Y axis, from top to bottom.
;
;		or
;
;	X1, X2	= Coordinates along the X axis of an arbitrary box in
;		  normalized coordinates.  Can have values between 0 and 1.
;	Y1, Y2	= Coordinates along the Y axis of an arbitrary box in
;		  normalized coordinates.  Can have values between 0 and 1.
;
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	NORMAL	 = If set, then the input parameters are in normalized
;		   coordinates.  Otherwise, they refer to the relative position
;		   of the image on the screen in a regular array of images.
;	NOSQUARE = If passed, then pixels are not forced to be square.
;	SMOOTH	 = If passed, then interpolation used in expanding array.
;	NOBOX	 = If passed, then box is not drawn, and no space is reserved
;		   for a border around the image.
;	NOSCALE  = If passed, then the command TV is used instead of TVSCL to
;		   display the image.
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero.  Ignored if NOSCALE is set.
;	SIZE	 = If passed and positive, then used to determine the scale of
;		   the image.  Returned as the value of the image scale.  May
;		   not be compatible with /NOSQUARE.
;	DISABLE  = If set, then TVSELECT not used.
;	NOEXACT  = If set, then exact scaling is not imposed.  Otherwise, the
;		   image scale will be either an integer, or one over an
;		   integer.  Ignored if SIZE is passed with a positive value.
;	XALIGN	 = Alignment within the image display area.  Ranges between 0
;		   (left) to 1 (right).  Default is 0.5 (centered).
;	YALIGN	 = Alignment within the image display area.  Ranges between 0
;		   (bottom) to 1 (top).  Default is 0.5 (centered).
;	RELATIVE = Size of area to be used for displaying the image, relative
;		   to the total size available.  Must be between 0 and 1.
;		   Default is 1.  Passing SIZE explicitly will override this
;		   keyword.
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
;	EXPAND_TV, GET_IM_KEYWORD, SCALE_TV, SETIMAGE, TRIM, TVSELECT,
;	TVUNSELECT
; Common      : 
;	None.
; Restrictions: 
;	ARRAY must be two-dimensional.  If /NORMAL is set, then X1, X2, Y1, Y2
;	must be between 0 and 1.  Otherwise, IX must be between 1 and NX, and
;	(if passed) IY must be between 1 and NY.
;
;	If the II, NN option is used, then II must be between 1 and NN.  This
;	option really only works if all the images to be displayed are the same
;	size.
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
;	SETIMAGE is set to the portion of the window the image is displayed in.
;
;	Messages about the size and position of the displayed image are printed
;	to the terminal screen.  This can be turned off by setting !QUIET to 1.
;
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	W.T.T., Oct. 1987.
;	W.T.T., Jan. 1991, added BADPIXEL keyword.
;	W.T.T., Feb. 1991, modified to use SETIMAGE.
;	W.T.T., Feb. 1991, added SIZE keyword.
;	W.T.T., Mar. 1991, this used to be PLACE_TV, and PUT was somewhat
;			   different.
;	W.T.T., Mar. 1991, added NOEXACT keyword.
;	W.T.T., Nov. 1991, added MAX, MIN, and TOP keywords.
;	W.T.T., Nov. 1991, added INTENSITY, VELOCITY and COMBINED keywords.
;	W.T.T., Jan. 1992, changed SETIMAGE behavior, and added RETAIN keyword.
;	W.T.T., Feb. 1992, added LOWER keyword.
;	W.T.T., Feb. 1992, returned SETIMAGE behavior to the way it was before.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
;	William Thompson, September 1992, use COMBINED keyword in place of
;					  INTENSITY.
;	William Thompson, Oct. 1992, changed strategy used when II,NN are
;				     passed instead of IX,NX,IY,NY.
;	William Thompson, November 1992, added /NORMAL keyword.
; Written     : 
;	William Thompson, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 12 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 24 June 1993.
;		Fixed problem with /NORMAL keyword.
;	Version 3, William Thompson, GSFC, 2 September 1993.
;		Added ORIGIN, SCALE and DATA keywords.
; Version     : 
;	Version 3, 2 September 1993.
;-
;
	ON_ERROR,2
	GET_IM_KEYWORD, MISSING, !IMAGE.MISSING
;
;  Check the dimensions of ARRAY.
;
	S = SIZE(ARRAY)
	ARRAY_TYPE = S(S(0) + 1)
	IF S(0) NE 2 THEN MESSAGE,'ARRAY must be two-dimensional'
;
;  Check the number of parameters.  If only three, then choose how to arrange
;  along the X and Y axes based on the size of the image and the size of the
;  window.
;
	IF N_PARAMS(0) EQ 3 THEN BEGIN
		IF KEYWORD_SET(NORMAL) THEN MESSAGE,	$
			'/NORMAL can only be used if X1,X2,Y1,Y2 are passed'
		IF NNX LT 1 THEN MESSAGE,'NX should be GE 1'
		IF (IIX LT 1) OR (IIX GT NNX) THEN MESSAGE,	$
			'IX should be between 1 and ' + TRIM(NX)
		TVSELECT,DISABLE=DISABLE
		NX = NNX
		NY = 1
		AMAX = 0
		FOR NI = 1,NNX DO BEGIN
			NJ = (NNX + NI - 1) / NI
			AX = !D.X_SIZE / (S(1)*FLOAT(NI))
			AY = !D.Y_SIZE / (S(2)*FLOAT(NJ))
			AA = AX < AY
			IF AA GT AMAX THEN BEGIN
				AMAX = AA
				NX = NI
				NY = NJ
			ENDIF
		ENDFOR
		IX = ((IIX - 1) MOD NX) + 1
		IY = (IIX - 1)/NX + 1
		TVUNSELECT,DISABLE=DISABLE
;
;  Otherwise, there have to be five parameters passed.
;
	END ELSE IF N_PARAMS(0) NE 5 THEN BEGIN
		PRINT,'*** PUT must be called with three or five parameters:'
		PRINT,'               ARRAY, II, NN
		PRINT,'               ARRAY, IX, NX, IY, NY'
		RETURN
	END ELSE BEGIN
		IX = IIX  &  NX = NNX
		IY = IIY  &  NY = NNY
	ENDELSE
;
;  Check the parameters IX, NX and IY, NY.
;
	IF KEYWORD_SET(NORMAL) THEN BEGIN
		IF (IX LT 0) OR (IX GT 1) THEN MESSAGE,	$
			'X1 should be between 0 and 1'
		IF (NX EQ IX) THEN MESSAGE,'X1 and X2 must not be equal'
		IF (NX LT IX) OR (NX GT 1) THEN MESSAGE, $
			'X2 should be between X1 and 1'
		IF (IY LT 0) OR (IY GT 1) THEN MESSAGE,	$
			'Y1 should be between 0 and 1'
		IF (NY EQ IY) THEN MESSAGE,'Y1 and Y2 must not be equal'
		IF (NY LT IY) OR (NY GT 1) THEN MESSAGE, $
			'Y2 should be between Y1 and 1'
	END ELSE BEGIN
		IF (NX LT 1) OR (NY LT 1) THEN MESSAGE,'NX, NY should be GE 1'
		IF (IX LT 1) OR (IX GT NX) THEN MESSAGE,	$
			'IX should be between 1 and ' + TRIM(NX)
		IF (IY LT 1) OR (IY GT NY) THEN MESSAGE,	$
			'IY should be between 1 and ' + TRIM(NY)
	ENDELSE
;
;  Call SETIMAGE and SCALE_TV to calculate MX, MY and JX, JY.
;
	SETIMAGE,IX,NX,IY,NY,NORMAL=NORMAL
	SCALE_TV,ARRAY,MX,MY,JX,JY,NOSQUARE=NOSQUARE,SIZE=SIZE,NOBOX=NOBOX, $
		DISABLE=DISABLE,NOEXACT=NOEXACT,XALIGN=XALIGN,YALIGN=YALIGN,$
		RELATIVE=RELATIVE
;
;  Call EXPAND_TV to display the image.
;
	EXPAND_TV,ARRAY,MX,MY,JX,JY,SMOOTH=SMOOTH,NOBOX=NOBOX,  $
		NOSCALE=NOSCALE,MISSING=MISSING,DISABLE=DISABLE,	$
		COLOR=COLOR,MAX=MAX,MIN=MIN,TOP=TOP,VELOCITY=VELOCITY,	$
		COMBINED=COMBINED,LOWER=LOWER,ORIGIN=ORIGIN,SCALE=SCALE,$
		DATA=DATA
;
	RETURN
	END
