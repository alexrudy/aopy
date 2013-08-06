	PRO TVPOS,XXVAL,YYVAL,P0,P1,P2,P3,P4,P5,DISABLE=DISABLE,WAIT=WAIT, $
		ZOOM=ZOOM, NOSCALE=NOSCALE, MISSING=MISSING, MAX=MAX,	$
		MIN=MIN, TOP=TOP, VELOCITY=VELOCITY, COMBINED=COMBINED, $
		LOWER=LOWER
;+
; Project     : SOHO - CDS
;
; Name        : 
;	TVPOS
; Purpose     : 
;	Returns cursor positions on displayed images.
; Explanation : 
;	The values MX, MY and IX, IY are used to convert screen coordinates to
;	data coordinates.
; Use         : 
;	TVPOS,  [ XVAL, YVAL  [, PRINT_SWITCH ]]  [, IMAGE [, MX, MY, IX, IY ]]
;
;	TVPOS			;Prints position to screen
;	TVPOS, X, Y		;Save positions in arrays
;	TVPOS, X, Y, 1		;Both saves and prints
;
;	TVPOS, IMAGE, /ZOOM		;Get position from zoomed image.
;	TVPOS, X, Y, IMAGE, /ZOOM	;These three are variations on the
;	TVPOS, X, Y, 1, IMAGE, /ZOOM	;	three examples shown above.
;
; Inputs      : 
;	None required.
; Opt. Inputs : 
;	PRINT_SWITCH	= Switch used to control printing the values of 
;			  XVAL, YVAL to the screen.  If not passed,
;			  then assumed 0 (no printing) unless XVAL and YVAL are
;			  not passed, in which case 1 (printing) is assumed.
;
;	IMAGE		= The image to find positions on.
;	MX, MY		= Size of displayed image.
;	IX, IY		= Position of the lower left-hand corner of the image.
;
;	If the last five optional parameters are not passed, then they are
;	retrieved with GET_TV_SCALE.  It is anticipated that these optional
;	parameters will only be used in extremely rare circumstances.
;
; Outputs     : 
;	None required.
; Opt. Outputs: 
;	XVAL,YVAL	= The X,Y positions of the selected points.
; Keywords    : 
;	DISABLE  = If set, then TVSELECT not used.
;
;	ZOOM	 = If set, then retrieve the position from a zoomed version of
;		   the image.  Can only be used if the IMAGE parameter was
;		   passed.
;
;	WAIT	 = An integer that specifies the conditions under 
;		   which CURSOR returns. This parameter can be used 
;		   interchangeably with the keyword parameters listed 
;		   below that specify the type of wait. The default 
;		   value is 1. The table below describes each type of 
;		   wait
;        
;		NOTE: not all wait modes work with all display devices
;
;		Value  Corresponding Keyword  Action
;		------------------------------------------------
;		0	NOWAIT		Return immediately
;		1	WAIT		Return if button is down
;		2	CHANGE		Return if a button is
;					pressed, released, or the
;					pointer is moved.
;		3	DOWN		Return on button down
;		4	UP		Return on button up
;
;
;	    If the optional IMAGE parameter is passed, together with the ZOOM
;	    keyword, then the following keyword parameters can be used to
;	    adjust the scale of the temporary zoomed image:
;
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
;	GET_TV_SCALE, TRIM, TVSELECT, TVUNSELECT
; Common      : 
;	None.
; Restrictions: 
;	It is important that the user select the graphics device/window, and
;	image region before calling this routine.  For instance, if the image
;	was displayed using EXPTV,/DISABLE, then this routine should also be
;	called with the /DISABLE keyword.  If multiple images are displayed
;	within the same window, then use SETIMAGE to select the image before
;	calling this routine.
;
;	Using TVPOS with the /ZOOM keyword causes the WAIT keyword to be
;	ignored.
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
;	Forces TVZOOM to use a new window for zoomed images.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	W.T.T., Oct. 1987.
;	W.T.T., Feb. 1991, modified to use TVSELECT, TVUNSELECT.
;	William Thompson, May 1992, modified to use GET_TV_SCALE.
;	William Thompson, March 1993, added WAIT keyword.
; Written     : 
;	William Thompson, GSFC, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 11 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 20 May 1993.
;		Added ZOOM keyword.
; Version     : 
;	Version 2, 20 May 1993.
;-
;
	ON_ERROR,2
;
;  Parse the input parameters.
;
	CASE N_PARAMS(0) OF
;
;  Nothing passed.
;
		0:  BEGIN
			PASSED_XY = 0
			PRINT_SWITCH = 1
			PASSED_MI = 0
			IMAGE_PARAMETER = ''
			END
;
;  IMAGE passed.
;
		1:  BEGIN
			PASSED_XY = 0
			PRINT_SWITCH = 1
			PASSED_MI = 0
			IMAGE_PARAMETER = 'XXVAL'
			END
;
;  XVAL and YVAL passed.
;
		2:  BEGIN
			PASSED_XY = 1
			PRINT_SWITCH = 0
			PASSED_MI = 0
			IMAGE_PARAMETER = ''
			END
;
;  XVAL, YVAL and PRINT_SWITCH passed.
;
		3:  BEGIN
			If N_ELEMENTS(P0) EQ 1 THEN BEGIN
				PASSED_XY = 1
				PRINT_SWITCH = P0
				PASSED_MI = 0
				IMAGE_PARAMETER = ''
;
;  XVAL, YVAL, and IMAGE passed.
;
			END ELSE BEGIN
				PASSED_XY = 1
				PRINT_SWITCH = 0
				PASSED_MI = 0
				IMAGE_PARAMETER = 'P0'
			ENDELSE
			END
;
;  IMAGE, MX, MY, IX, IY passed.
;
		5:  BEGIN
			PASSED_XY = 0
			PRINT_SWITCH = 1
			PASSED_MI = 1
			IMAGE_PARAMETER = 'XXVAL'
			S = SIZE(XXVAL)
			IF S(0) NE 2 THEN MESSAGE,	$
				'IMAGE must be two-dimensional'
			SX = S(1)
			SY = S(2)
			MX = YYVAL
			MY = P0
			IX = P1
			IY = P2
			END
;
;  XVAL, YVAL, IMAGE, MX, MY, IX, IY passed.
;
		7:  BEGIN
			PASSED_XY = 1
			PRINT_SWITCH = 0
			PASSED_MI = 1
			IMAGE_PARAMETER = 'P0'
			S = SIZE(P0)
			IF S(0) NE 2 THEN MESSAGE,	$
				'IMAGE must be two-dimensional'
			SX = S(1)
			SY = S(2)
			MX = P1
			MY = P2
			IX = P3
			IY = P4
			END
;
;  XVAL, YVAL, PRINT_SWITCH, IMAGE, MX, MY, IX, IY passed.
;
		8:  BEGIN
			PASSED_XY = 1
			PRINT_SWITCH = P0
			PASSED_MI = 1
			IMAGE_PARAMETER = 'P1'
			S = SIZE(P1)
			IF S(0) NE 2 THEN MESSAGE,	$
				'IMAGE must be two-dimensional'
			SX = S(1)
			SY = S(2)
			MX = P2
			MY = P3
			IX = P4
			IY = P5
			END
		ELSE:  BEGIN
			PRINT,'*** TVPOS must be called with 0-8 parameters:'
			PRINT,'	[ XVAL, YVAL  [, PRINT_SWITCH ]]  [, IMAGE [, MX, MY, IX, IY ]]'
			RETURN
			END
	ENDCASE
;
;  Retrieve the scale of the displayed image if necessary.
;
	IF NOT PASSED_MI THEN BEGIN
		GET_TV_SCALE,SX,SY,MX,MY,IX,IY,DISABLE=DISABLE
;
;  If the IMAGE parameter was passed, then check it against the retrieved
;  parameters.
;
		IF IMAGE_PARAMETER NE '' THEN BEGIN
			TEST = EXECUTE('S = SIZE(' + IMAGE_PARAMETER + ')')
			IF (SX NE S(1)) OR (SY NE S(2)) THEN MESSAGE,	$
			    'IMAGE size does not agree with displayed image'
		ENDIF
	ENDIF
;
;  Check to see if the image was properly scaled.
;
	IF ((MX LE 1) OR (MY LE 1)) THEN MESSAGE,	$
		'The dimensions MX,MY must be > 1'
;
;  Get the wait state.
;
	IF N_ELEMENTS(WAIT) EQ 1 THEN WT = WAIT ELSE WT = 1
;
;  Select the image display device or window.
;
	TVSELECT, DISABLE=DISABLE
;
;  If the ZOOM keyword was set, then use TVZOOM to zoom in on the image, and
;  read the cursor from the zoomed image.
;
	IF KEYWORD_SET(ZOOM) AND IMAGE_PARAMETER NE '' THEN BEGIN
		TEST = EXECUTE('IMAGE = ' + IMAGE_PARAMETER)
		TVZOOM,IMAGE,X0,X1,Y0,Y1,/KEEP,/NEW_WINDOW,/DISABLE,	$
			ZOOM_WINDOW=ZOOM_WINDOW, NOSCALE=NOSCALE,	$
			MISSING=MISSING, MAX=MAX, MIN=MIN, TOP=TOP,	$
			VELOCITY=VELOCITY, COMBINED=COMBINED, LOWER=LOWER
		OLD_WINDOW = !D.WINDOW
		WSET, ZOOM_WINDOW
		PRINT,'Mark the selected point with the cursor.'
		CURSOR,XX,YY,/DEVICE
		XVAL = X0 + FLOAT(XX) / FIX((!D.X_SIZE+X1-X0) / (X1-X0+1.))
		YVAL = Y0 + FLOAT(YY) / FIX((!D.Y_SIZE+Y1-Y0) / (Y1-Y0+1.))
		WSET, OLD_WINDOW
		WDELETE, ZOOM_WINDOW
;
;  Otherwise, just read in the cursor position, and convert device position
;  into data position.
;
	END ELSE BEGIN
		IF WT EQ 1 THEN PRINT,	$
			'Mark the selected point with the cursor.'
		CURSOR,XX,YY,WT,/DEVICE
		NX = FLOAT(MX) / SX
		NY = FLOAT(MY) / SY
		XVAL = (XX - IX) / NX
		YVAL = (YY - IY) / NY
		IF !ORDER NE 0 THEN YVAL = SY - YVAL - 1
	ENDELSE
	IF PRINT_SWITCH NE 0 THEN PRINT,' Position:  ' + TRIM(XVAL) +	$
		', ' + TRIM(YVAL)
	IF PASSED_XY THEN BEGIN
		XXVAL = XVAL
		YYVAL = YVAL
	ENDIF
;
EXIT_POINT:
	TVUNSELECT, DISABLE=DISABLE
	RETURN
	END
