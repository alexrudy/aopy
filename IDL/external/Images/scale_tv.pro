	PRO SCALE_TV,ARRAY,MX,MY,JX,JY,NOSQUARE=NOSQUARE,SIZE=SIZE, $
		NOBOX=NOBOX,DISABLE=DISABLE,NOEXACT=NOEXACT,	    $
		XALIGN=XALIGN,YALIGN=YALIGN,RELATIVE=RELATIVE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	SCALE_TV
; Purpose     : 
;	Scales an image to best fit the image display screen.
; Explanation : 
;	Scales the size of an image to best fit the size of an available area 
;	on the image display screen.  Called from EXPTV and other routines.
; Use         : 
;	SCALE_TV, ARRAY, MX, MY, JX, JY
; Inputs      : 
;	ARRAY	= Image to be scaled.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	MX, MY	 = The size to use in displaying the image.
;	JX, JY	 = The position of the lower left-hand corner of the image to 
;		   use in displaying the image.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	NOSQUARE = If passed, then pixels are not forced to be square.
;	SIZE	 = If passed and positive, then used to determine the scale of
;		   the image.  Returned as the value of the image scale.  May
;		   not be compatible with /NOSQUARE.
;	NOBOX	 = If set, then no space is reserved for a border around the
;		   image.  Generally used with the EXPAND_TV switch of the same
;		   name.
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
; Calls       : 
;	GET_IM_KEYWORD, IM_KEYWORD_SET, TVSELECT, TVUNSELECT
; Common      : 
;	IMAGE_AREA  = Contains switch IMAGE_SET and position IX, NX, IY, NY.
; Restrictions: 
;	ARRAY must be two-dimensional.
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
;	W.T.T., Oct. 1987.
;	W.T.T., Feb. 1991, modified to use TVSELECT, TVUNSELECT.
;	W.T.T., Feb. 1991, modified to use common block IMAGE_AREA.
;	W.T.T., Feb. 1991, added SIZE keyword.
;	W.T.T., Mar. 1991, added NOEXACT keyword.
;	W.T.T., Oct. 1991, added !ASPECT system variable.
; Written     : 
;	William Thompson, GSFC, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 12 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 12 May 1993.
;-
;
	COMMON IMAGE_AREA, IMAGE_SET, IX, NX, IY, NY
;
;  Check the number of parameters.
;
	IF N_PARAMS(0) LT 5 THEN BEGIN
		PRINT,'*** SCALE_TV must be called with five parameters:'
		PRINT,'      ARRAY, MX, MY, JX, JY'
		RETURN
	ENDIF
;
;  Check the dimensions of ARRAY.
;
	S = SIZE(ARRAY)
	IF S(0) NE 2 THEN BEGIN
		PRINT,'*** Variable must be two-dimensional, name= ARRAY, ' + $
			'routine SCALE_TV.'
		RETURN
	ENDIF
;
;  Make sure that the common block parameters are defined.
;
	IF N_ELEMENTS(IMAGE_SET) EQ 0 THEN BEGIN
		IMAGE_SET = 0
		IX = 1  &  NX = 1
		IY = 1  &  NY = 1
	ENDIF
;
;  Select the image display device or window.
;
	TVSELECT, DISABLE=DISABLE
;
;  Get the size of the image display.  If the imaging device is a Tektronix
;  terminal, then redefine the image size to reflect that of the Tektronix
;  4211.  If the aspect ratio !ASPECT is not one, then readjust to the size of
;  the equivalent square pixels.
;
	X_SIZE = !D.X_SIZE  &  X_OFF = 4
	Y_SIZE = !D.Y_SIZE  &  Y_OFF = 4
	IF !D.NAME EQ 'TEK' THEN BEGIN
		X_SIZE = 1024
		Y_SIZE = 734
	ENDIF
	IF !ASPECT NE 1 THEN X_SIZE = X_SIZE / !ASPECT
;
;  From IX,IY and NX,NY determine X_SIZE and Y_SIZE, the size of used portion
;  of the image display screen in the X and Y directions.  This is the device
;  dependent part of the code.	Also determine X_OFF and Y_OFF, the amount of
;  space needed to leave room for the border.
;
	IF NX GT 1 THEN BEGIN
		X_SIZE = X_SIZE / NX
		X_OFF = 3
	ENDIF
	IF NY GT 1 THEN BEGIN
		Y_SIZE = Y_SIZE / NY
		Y_OFF = 3
	ENDIF
;
;  If NOBOX was set, then set X_OFF and Y_OFF to zero.
;
	IF IM_KEYWORD_SET(NOBOX,!IMAGE.NOBOX) THEN BEGIN
		X_OFF = 0
		Y_OFF = 0
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
;  From X_SIZE, Y_SIZE and X_OFF, Y_OFF determine the number of pixels NNX, NNY
;  to expand or contract the image by.
;
	SX = S(1)
	SY = S(2)
	NNX = REL * (X_SIZE - X_OFF) / FLOAT(SX)
	IF NOT IM_KEYWORD_SET(NOEXACT,!IMAGE.NOEXACT) THEN BEGIN
		IF NNX GE 1 THEN NNX = FIX(NNX) ELSE BEGIN
			INV = FIX(1 / NNX)
			IF INV*NNX LT 1 THEN INV = INV + 1
			NNX = 1. / INV
		ENDELSE
	ENDIF
;
	NNY = REL * (Y_SIZE - Y_OFF) / FLOAT(SY)
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
	GET_IM_KEYWORD,SIZE,!IMAGE.SIZE
	IF N_ELEMENTS(SIZE) EQ 1 THEN BEGIN
		IF SIZE GT 0 THEN BEGIN
			NNX = SIZE
			NNY = SIZE
		ENDIF
	ENDIF
	SIZE = NNX < NNY
;
;  Use NNX, NNY to determine the size of the expanded image MX, MY.  If the
;  variable NOSQUARE is not set then the image pixels will be displayed as
;  square.  Otherwise the scaling will be independent in the X and Y 
;  directions.
;
	IF NOT IM_KEYWORD_SET(NOSQUARE,!IMAGE.NOSQUARE) THEN BEGIN
		NNX = NNX < NNY
		NNY = NNX
	ENDIF
	MX = FIX(SX*NNX)
	MY = FIX(SY*NNY)
;
;  Get the alignment in the X and Y directions.
;
	GET_IM_KEYWORD,XALIGN,!IMAGE.XALIGN
	XALIGNMENT = 0.5
	IF N_ELEMENTS(XALIGN) EQ 1 THEN BEGIN
		IF (XALIGN GE 0) AND (XALIGN LE 1) THEN XALIGNMENT = XALIGN
	ENDIF
;
	GET_IM_KEYWORD,YALIGN,!IMAGE.YALIGN
	YALIGNMENT = 0.5
	IF N_ELEMENTS(YALIGN) EQ 1 THEN BEGIN
		IF (YALIGN GE 0) AND (YALIGN LE 1) THEN YALIGNMENT = YALIGN
	ENDIF
;
;  Calculate the position of the image JX, JY.
;
	JX = FIX((IX- 1)*X_SIZE + X_OFF + (X_SIZE-MX-2*X_OFF)*XALIGNMENT)
	JY = FIX((NY-IY)*Y_SIZE + Y_OFF + (Y_SIZE-MY-2*Y_OFF)*YALIGNMENT)
;
;  If the graphics device is a Tektronix terminal, then reconvert the device
;  coordinates into graphics coordinates.
;
	IF !D.NAME EQ 'TEK' THEN BEGIN
		JX = JX * 4
		MX = MX * 4
		JY = FIX( JY * 3277. / 768.  + 0.5 )
		MY = FIX( MY * 3277. / 768.  + 0.5 )
	ENDIF
;
;  If !ASPECT is not one, then resize JX and MX back to the real size of the
;  pixels.
;
	IF !ASPECT NE 1 THEN BEGIN
		JX = FIX(0.5 + JX * !ASPECT)
		MX = FIX(0.5 + MX * !ASPECT)
	ENDIF
;
;  Reset to the previous device or window.
;
	TVUNSELECT, DISABLE=DISABLE
;
	RETURN
	END
