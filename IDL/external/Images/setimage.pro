	PRO SETIMAGE,P1,P2,P3,P4,NORMAL=NORMAL,DATA=DATA,DISABLE=DISABLE, $
		CURRENT=CURRENT
;+
; Project     : SOHO - CDS
;
; Name        : 
;	SETIMAGE
; Purpose     : 
;	Allow several images in one window.
; Explanation : 
;	Allows several images in one window, arranged horizontally and/or
;	vertically.
;
;	If the /NORMAL keyword is set, then the equivalent values of IX, NX,
;	and IY, NY (which may be fractional) are calculated and substituted in
;	the common block.
;
;	If no parameters are passed, or the full screen is selected, then
;	the behavior is reset to the default.
;
;	Normally, PUT is used to actually display an image using only part of
;	the screen, although SETIMAGE and EXPTV,/NORESET could be used to
;	generate the same output.
;
;	SETIMAGE can be used to reselect an image that was previously displayed
;	(e.g. with PUT).
;
; Use         : 
;	SETIMAGE					;Reset to default
;
;	SETIMAGE, IX, NX  [, IY, NY ]			;Divide screen into
;							;NX x NY boxes
;
;	SETIMAGE, /NORMAL, X1, X2  [, Y1, Y2 ]		;Arbitrary box in
;							;normalized coordinates
;
;	Example: Display an image as the third of five from the left, and the
;	second of three from the top.
;
;		SETIMAGE, 3, 5, 2, 3
;		EXPTV, image, /NORESET
;
;	Example: Display an image in a box using the top 80% of the screen,
;	with 5% margins on either side.
;
;		SETIMAGE, 0.05, 0.95, 0.2, 1, /NORMAL
;		EXPTV, image, /NORESET
;
;	Example: Select a previously displayed image and retrieve the data
;	coordinates associated with it.
;
;		SETIMAGE, 2, 5, 1, 3, /DATA
;
; Inputs      : 
;	None required.
; Opt. Inputs : 
;	IX, NX	= Relative position along X axis, expressed as position IX
;		  out of a possible NX, from left to right.  If not passed,
;		  then 1,1 is assumed. 
;	IY, NY	= Relative position along Y axis, from top to bottom.  If
;		  not passed, then 1,1 is assumed.
;
;	or
;
;	X1, X2	= Coordinates along the X axis of an arbitrary box in
;		  normalized coordinates.  Can have values between 0 and 1.
;	Y1, Y2	= Coordinates along the Y axis of an arbitrary box in
;		  normalized coordinates.  Can have values between 0 and 1.  If
;		  not passed, then 0,1 is assumed.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	NORMAL	= If set, then the input parameters are in normalized
;		  coordinates.  Otherwise, they refer to the relative position
;		  of the image on the screen in a regular array of images.
;	DATA	= Retrieve the data coordinates associated with an already
;		  displayed image.
;	DISABLE	= If set, then TVSELECT is not called.  Only relevant in
;		  conjunction with the DATA keyword.
;	CURRENT	= If set, then the currently stored settings are used.  Used in
;		  conjunction with the DATA keyword to allow calling without
;		  parameters.
; Calls       : 
;	TRIM, TVSELECT, TVUNSELECT
; Common      : 
;	IMAGE_AREA  = Contains switch IMAGE_SET and position IX, NX, IY, NY.
; Restrictions: 
;	If /NORMAL is set, then X1, X2, Y1, Y2 must be between 0 and 1.
;	Otherwise, IX must be between 1 and NX, and (if passed) IY must be
;	between 1 and NY.
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
;	William Thompson	Applied Research Corporation
;	February, 1991          8201 Corporate Drive
;				Landover, MD  20785
;
;	William Thompson, November 1992, added /NORMAL keyword.
; Written     : 
;	William Thompson, GSFC, February 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 12 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 24 June 1993.
;		Added call to ON_ERROR.
;	Version 3, William Thompson, GSFC, 2 September 1993.
;		Added DATA and DISABLE keywords.
;		Added CURRENT keyword.
; Version     : 
;	Version 3, 2 September 1993.
;-
;
	ON_ERROR, 2
	COMMON IMAGE_AREA, IMAGE_SET, IX, NX, IY, NY
;
;  If the CURRENT keyword is set, then no input parameters are needed.
;
	IF KEYWORD_SET(CURRENT) THEN GOTO, SET_DATA
;
;  Interpret the input variables.
;
	IF N_PARAMS(0) EQ 0 THEN BEGIN
		IXX = 1
		NXX = 1
		IYY = 1
		NYY = 1
	END ELSE IF N_PARAMS(0) EQ 2 THEN BEGIN
		IF KEYWORD_SET(NORMAL) THEN BEGIN
			IF P1 EQ P2 THEN MESSAGE,'X1 and X2 must not be equal'
			IXX = (P1 > P2) / ABS(P2 - P1)
			NXX = 1 / ABS(P2 - P1)
		END ELSE BEGIN
			IXX = P1
			NXX = P2
		ENDELSE
		IYY = 1
		NYY = 1
	END ELSE IF N_PARAMS(0) EQ 4 THEN BEGIN
		IF KEYWORD_SET(NORMAL) THEN BEGIN
			IF P1 EQ P2 THEN MESSAGE,'X1 and X2 must not be equal'
			IXX = (P1 > P2) / ABS(P2 - P1)
			NXX = 1 / ABS(P2 - P1)
			IF P3 EQ P4 THEN MESSAGE,'Y1 and Y2 must not be equal'
			IYY = (1 - (P3 < P4)) / ABS(P3 - P4)
			NYY = 1 / ABS(P3 - P4)
		END ELSE BEGIN
			IXX = P1
			NXX = P2
			IYY = P3
			NYY = P4
		ENDELSE
	END ELSE BEGIN
		PRINT,'*** SETIMAGE must be called with up to four parameters:'
		PRINT,'        [ IX, NX  [, IY, NY  ]]'
		PRINT,'        [ X1, X2  [, Y1, Y2  ]], /NORMAL'
		RETURN
	ENDELSE
;
;  Check the input parameters.
;
	IF KEYWORD_SET(NORMAL) THEN BEGIN
		IF (P1 LT 0) OR (P1 GT 1) THEN MESSAGE,	$
			'X1 must be between 0 and 1'
		IF (P2 LT 0) OR (P2 GT 1) THEN MESSAGE,	$
			'X2 must be between 0 and 1'
		IF N_PARAMS() EQ 4 THEN BEGIN
			IF (P3 LT 0) OR (P3 GT 1) THEN MESSAGE,	$
				'Y1 must be between 0 and 1'
			IF (P4 LT 0) OR (P4 GT 1) THEN MESSAGE,	$
				'Y2 must be between 0 and 1'
		ENDIF
	ENDIF
	IF NXX LT 1 THEN MESSAGE,'NX must be GE 1'
	IF NYY LT 1 THEN MESSAGE,'NY must be GE 1'
	IF (IXX LT 1) OR (IXX GT NXX) THEN MESSAGE,	$
		'IX must be in the range 1 to ' + TRIM(NXX)
	IF (IYY LT 1) OR (IYY GT NYY) THEN MESSAGE,	$
		'IY must be in the range 1 to ' + TRIM(NYY)
;
;  Store the variables in the common block.
;
	IX = IXX  &  NX = NXX
	IY = IYY  &  NY = NYY
	IF IX*IY*NX*NY EQ 1 THEN IMAGE_SET = 0 ELSE IMAGE_SET = 1
;
;  If requested, then retrieve the data coordinates associated with a
;  previously displayed image.
;
SET_DATA:
	IF KEYWORD_SET(DATA) THEN BEGIN
		TVSELECT, DISABLE=DISABLE, /SAFE
		GET_TV_SCALE, SX0, SY0, MX0, MY0, JX0, JY0, DT, /DISABLE
		!P.CLIP = DT.CLIP
		!X.S = DT.XS
		!Y.S = DT.YS
		GET_VIEWPORT,SC1,SC2,SC3,SC4
		!X.CRANGE = ([SC1,SC2]/!D.X_SIZE - !X.S(0)) / !X.S(1)
		!Y.CRANGE = ([SC3,SC4]/!D.Y_SIZE - !Y.S(0)) / !Y.S(1)
		!X.TYPE = 0
		!Y.TYPE = 0
		TVUNSELECT, DISABLE=DISABLE, /SAFE
	ENDIF
;
	RETURN
	END
