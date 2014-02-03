	FUNCTION TVSUBIMAGE, IMAGE, X1, X2, Y1, Y2, MX, MY, IX, IY,	$
		DISABLE=DISABLE, INIT=INIT, FIXED_SIZE=FIXED_SIZE,	$
		PRINT=PRINT
;+
; Project     : SOHO - CDS
;
; Name        : TVSUBIMAGE()
;
; Purpose     : Interactively selects a subimage from a displayed image.
;
; Explanation : Uses TVBOX to select a rectangular subregion of a displayed
;		image, and returns that subregion.
;
; Use         : Result = TVSUBIMAGE( IMAGE [, X1,X2,Y1,Y2 [, MX,MY,IX,IY ]] )
;
; Inputs      : IMAGE	= Image to extract subimage from.
;
; Opt. Inputs : MX, MY	= Size of displayed image.
;		IX, IY	= Position of the lower left-hand corner of the image.
;
;		If these optional parameters are not passed, then they are
;		retrieved with GET_TV_SCALE.  It is anticipated that these
;		optional parameters will only be used in extremely rare
;		circumstances.
;
; Outputs     : The result of the function is the extracted subimage.
;
; Opt. Outputs: X1,X2,Y1,Y2	= The X,Y positions of the corners of the
;				  selected subimage.
;
; Keywords    : DISABLE    = If set, then TVSELECT not used.
;
;		PRINT	   = If set, then a message is printed given the range
;			     of the extracted subimage.
;
;		The following keywords are only relevant when used on a
;		graphics device that supports windows:
;
;		INIT	   = If this keyword is set, X1, X2, and Y1, Y2 contain
;			     the initial parameters for the box.
;
;		FIXED_SIZE = If this keyword is set, X1, X2, and Y1, Y2
;			     describe the initial size of the box.  This size
;			     may not be changed by the user.
;
; Calls       : GET_TV_SCALE, TVBOX
;
; Common      : None.
;
; Restrictions: It is important that the user select the graphics
;		device/window, and image region before calling this routine.
;		For instance, if the image was displayed using EXPTV,/DISABLE,
;		then this routine should also be called with the /DISABLE
;		keyword.  If multiple images are displayed within the same
;		window, then use SETIMAGE to select the image before calling
;		this routine.
;
;		In general, the SERTS image display routines use several
;		non-standard system variables.  These system variables are
;		defined in the procedure IMAGELIB.  It is suggested that the
;		command IMAGELIB be placed in the user's IDL_STARTUP file.
;
;		Some routines also require the SERTS graphics devices software,
;		generally found in a parallel directory at the site where this
;		software was obtained.  Those routines have their own special
;		system variables.
;
; Side effects: None.
;
; Category    : Utilities, Image_display.
;
; Prev. Hist. : None.
;
; Written     : William Thompson, GSFC, 25 June 1993.
;
; Modified    : Version 1, William Thompson, GSFC, 25 June 1993.
;		Version 2, William Thompson, GSFC, 30 August 1993.
;			Renamed to TVSUBIMAGE.
;			Added checks on IMAGE parameter.
;		Version 3, Liyun Wang, GSFC/ARC, March 1, 1995
;                       Added check on subimage limits
;
; Version     : Version 3, March 1, 1995
;-
;
	ON_ERROR, 2
;
	PR = KEYWORD_SET(PRINT)
;
;  The variables MX, MY, IX, IY were not passed.
;
	IF (N_PARAMS() EQ 1) OR (N_PARAMS() EQ 5) THEN BEGIN
		SZ = SIZE(IMAGE)
		IF SZ(0) NE 2 THEN MESSAGE,'IMAGE must be two-dimensional'
		GET_TV_SCALE, SX, SY, MX, MY, IX, IY, DISABLE=DISABLE
		IF (SZ(1) NE SX) OR (SZ(2) NE SY) THEN MESSAGE,	$
			'Dimensions do not match that of displayed image'
		TVBOX, X1, X2, Y1, Y2, PR, DISABLE=DISABLE, INIT=INIT,	$
			FIXED_SIZE=FIXED_SIZE
;
;  All variables were passed.
;
	END ELSE IF N_PARAMS() EQ 9 THEN BEGIN
		SZ = SIZE(IMAGE)
		IF SZ(0) NE 2 THEN MESSAGE,'IMAGE must be two-dimensional'
		TVBOX, X1, X2, Y1, Y2, PR, IMAGE, MX, MY, IX, IY,	$
			DISABLE=DISABLE, INIT=INIT, FIXED_SIZE=FIXED_SIZE
;
;  An incorrect number of parameters were passed.
;
	END ELSE MESSAGE, 'Syntax:  Result = ' +	$
		'TVSUBIMAGE(IMAGE [,X1,X2,Y1,Y2 [,MX,MY,IX,IY]])'
;
;  Check the subimage limits, make sure the subimage is indeed a
;  subset of the original image
;
        IF x1 LT 0 THEN x1 = 0
        IF x2 GT sz(1) THEN x2 = sz(1)-1
        IF y1 LT 0 THEN y1 = 0
        IF y2 GT sz(2) THEN y2 = sz(2)-1
;
;  Return the selected subimage.
;
	RETURN, IMAGE(X1:X2,Y1:Y2)
	END
