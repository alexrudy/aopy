	FUNCTION POLY_VAL,IMAGE,POS,XVAL,YVAL,MX,MY,IX,IY,DISABLE=DISABLE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	POLY_VAL()
; Purpose     : 
;	Returns values from polygonal areas of displayed images.
; Explanation : 
;	The TV cursor is activated, and the user is prompted to enter in a 
;	series of points defining a polygon surrounding the region of interest 
;	on the displayed image.  This procedure is completed by entering in the
;	same point twice.  Then POLYFILLV is used to get the positions POS 
;	within that polygon.
; Use         : 
;	VAL= POLY_VAL( IMAGE, POS, XVAL, YVAL  [, MX, MY, IX, IY ] )
; Inputs      : 
;	IMAGE		= The image to take the positions and values from.
; Opt. Inputs : 
;	MX, MY	 = Size of displayed image.
;	IX, IY	 = Position of the lower left-hand corner of the image.
;
;	If the optional parameters are not passed, then they are retrieved with
;	GET_TV_SCALE.  It is anticipated that these optional parameters will
;	only be used in extremely rare circumstances.
;
; Outputs     : 
;	Function value	= Values of the points within the selected area.
;	POS		= Positions of the points within the selected area.
;	XVAL,YVAL	= The X,Y positions of the surrounding polygon.
; Opt. Outputs: 
;
; Keywords    : 
;	DISABLE  = If set, then TVSELECT not used.
; Calls       : 
;	GET_TV_SCALE, TVPOINTS
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
;	screen.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	W.T.T., Oct. 1987.
;	William Thompson, May 1992, modified to use GET_TV_SCALE.
; Written     : 
;	William Thompson, GSFC, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 12 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 12 May 1993.
;-
;
	ON_ERROR,2
;
	IF (N_PARAMS(0) NE 4) AND (N_PARAMS(0) NE 8) THEN BEGIN
		PRINT,'*** POLY_VAL must be called with 4 or 8 parameters:'
		PRINT,'      IMAGE, POS, XVAL, YVAL  [, MX, MY, IX, IY ]'
		RETURN,0
	ENDIF
;
	S = SIZE(IMAGE)
	IF S(0) NE 2 THEN BEGIN
		PRINT,'*** Variable must be two-dimensional, name= IMAGE, routine POLY_VAL.'
		RETURN,0
	ENDIF
;
	IF N_PARAMS(0) EQ 4 THEN BEGIN
		GET_TV_SCALE,SX,SY,MX,MY,IX,IY,DISABLE=DISABLE
		IF (SX NE S(1)) OR (SY NE S(2)) THEN MESSAGE,	$
			'IMAGE size does not agree with displayed image'
	ENDIF
;
	IF ((MX LE 1) OR (MY LE 1)) THEN BEGIN
		PRINT,'*** The dimensions MX,MY must be > 1, routine POLY_VAL.'
		RETURN,0
	ENDIF
;
;  Call TVPOINTS to get an array of points on the image, using the cursor.  The
;  last parameter, 1, tells TVPOINTS to close the polygon.
;
	TVPOINTS,XVAL,YVAL,MX,MY,S(1),S(2),IX,IY,1,DISABLE=DISABLE
	NX = N_ELEMENTS(XVAL)
	IF NX LT 3 THEN BEGIN
		PRINT,'*** Must have at least three points, routine POLY_VAL.'
		RETURN,0
	ENDIF
	POS = POLYFILLV(XVAL,YVAL,S(1),S(2))
;
	RETURN,IMAGE(POS)
	END
