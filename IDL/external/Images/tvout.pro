	PRO TVOUT,XPOS,YPOS,STRING,ARRAY,MX,MY,IX,IY,ALIGNMENT=ALIGNMENT, $
		DISABLE=DISABLE,CHARSIZE=CHAR_SIZE,COLOR=COLOR,		  $
		ORIENTATION=ORIENTATION
;+
; Project     : SOHO - CDS
;
; Name        : 
;	TVOUT
; Purpose     : 
;	Outputs text onto images.
; Explanation : 
;	The routine XYOUTS is used to display the string at the device position
;	corresponding to the specified image pixel position.
; Use         : 
;	TVOUT, XPOS, YPOS, STRING  [, ARRAY, MX, MY, IX, IY ]
; Inputs      : 
;	XPOS	= X position of the string in pixels.
;	YPOS	= Y position of the string in pixels.
;	STRING	= Character string to be output to image.
; Opt. Inputs : 
;	ARRAY	= Image array.
;	MX, MY	= Size of displayed image.
;	IX, IY	= Position of displayed image.
;
;	If the optional parameters are not passed, then they are retrieved with
;	GET_TV_SCALE.  It is anticipated that these optional parameters will
;	only be used in extremely rare circumstances.
;
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	ALIGNMENT= Alignment of the string as described in the IDL manual.
;	CHARSIZE = Character size to use in displaying strings.  Normally 1.
;	COLOR	 = Color to display text in.
;	DISABLE  = If set, then TVSELECT not used.
;	ORIENTATION = Text orientation in degrees.
; Calls       : 
;	GET_TV_SCALE, TVSELECT, TVUNSELECT
; Common      : 
;	None.
; Restrictions: 
;	There must be enough space to display the string.
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
;	None.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, April 1991.
;	William Thompson, May 1992, modified to use GET_TV_SCALE.
;	William Thompson, Nov 1992, modified algorithm for getting the relative
;		character size.
; Written     : 
;	William Thompson, GSFC, April 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 11 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 29 October 1993.
;		Fixed bug with checking number of parameters.
; Version     : 
;	Version 2, 29 October 1993.
;-
;
	ON_ERROR,2
;
;  Check the number of parameters passed.
;
	IF (N_PARAMS() NE 3) AND (N_PARAMS() NE 8) THEN BEGIN
		PRINT,'*** TVOUT must be called with 3 or 8 paramters:'
		PRINT,'       XPOS, YPOS, STRING  [, ARRAY, MX, MY, IX, IY ]'
		RETURN
	ENDIF
;
;  Get the relative character size.
;
	IF N_ELEMENTS(CHAR_SIZE) EQ 1 THEN CHARSIZE = CHAR_SIZE	$
		ELSE CHARSIZE = !P.CHARSIZE
	IF CHARSIZE LE 0 THEN CHARSIZE = 1
;
;  Get the size of the image display screen.
;
	TVSELECT, DISABLE=DISABLE
    	X_SIZE = !D.X_SIZE  &  X_CH_SIZE = !D.X_CH_SIZE * CHARSIZE
	Y_SIZE = !D.Y_SIZE  &  Y_CH_SIZE = !D.Y_CH_SIZE * CHARSIZE
	TVUNSELECT, DISABLE=DISABLE
;
;  Get the size and position of the displayed image.
;
	IF N_PARAMS() EQ 3 THEN BEGIN
		GET_TV_SCALE,NX,NY,MX,MY,IX,IY,DISABLE=DISABLE
	END ELSE BEGIN
		SZ = SIZE(ARRAY)
		IF SZ(0) NE 2 THEN MESSAGE,'ARRAY must be two-dimensional'
		NX = SZ(1)
		NY = SZ(2)
	ENDELSE
;
;  Calculate the position of the text, and display it.
;
	XPIX = IX + MX * FLOAT(XPOS) / NX
	YPIX = IY + MY * FLOAT(YPOS) / NY
	TVSELECT, DISABLE=DISABLE
	IF N_ELEMENTS(COLOR) EQ 0 THEN COLOR = !COLOR
	IF N_ELEMENTS(ALIGNMENT) EQ 0 THEN ALIGNMENT = 0
	IF N_ELEMENTS(ORIENTATION) EQ 0 THEN ORIENTATION = 0
	XYOUTS,XPIX,YPIX,STRING,ALIGNMENT=ALIGNMENT,/DEVICE,	$
		CHARSIZE=CHARSIZE,COLOR=COLOR,ORIENTATION=ORIENTATION
	TVUNSELECT, DISABLE=DISABLE
;
	RETURN
	END
