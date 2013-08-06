	PRO TVVALUE,IMAGE,X,Y,VALUE,DISABLE=DISABLE,FONT=FONT
;+
; Project     : SOHO - CDS
;
; Name        : 
;	TVVALUE
; Purpose     : 
;	Interactively display the values in an image.
; Explanation : 
;	Instructions are printed and the pixel values are printed as the 
;	cursor is moved over the image.
;
;	Press the left or center mouse button to create a new line of output,
;	saving the previous line.
;
;	Press the right mouse button to exit the procedure.
;
; Use         : 
;	TVVALUE, IMAGE  [, X, Y, VALUE ]
; Inputs      : 
;	IMAGE	= Image to get values from.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	X, Y	= Pixel position of cursor for the last point selected.
;	VALUE	= Value of image under cursor for the last point selected.
; Keywords    : 
;	DISABLE	= If set, then TVSELECT not used.
;	FONT	= Font to use when displaying the TVVALUE widget.  Only
;		  meaningful when the graphics device supports widgets.  If not
;		  passed, then the first available 20 point font is used.
; Calls       : 
;	GET_TV_SCALE, TVPOS, TVSELECT, TVUNSELECT
; Common      : 
;	None.
; Restrictions: 
;	The image must have been displayed with EXPTV.
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
;	None.
; Prev. Hist. : 
;	William Thompson, Feb. 1992.
;	William Thompson, May 1992, changed to call GET_TV_SCALE.
;	William Thompson, Nov 1992, changed way mouse buttons were addressed.
;	William Thompson, Nov 1992, rewrote based on standard routine RDPIX.
;	William Thompson, Mar 1993, changed to use TVPOS.
; Written     : 
;	William Thompson, GSFC, February 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 5 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 12 May 1993.
;		Converted to use widgets when available.  This makes it
;		compatible with IDL for Windows.  Also added FONT keyword.
; Version     : 
;	Version 2, 12 May 1993.
;-
;
	ON_ERROR,2
;
;  Check the number of parameters.
;
	IF N_PARAMS(0) LT 1 THEN BEGIN
		PRINT,'*** TVVALUE must be called with 1-4 parameters:'
		PRINT,'           IMAGE  [, X, Y, VALUE ]'
		RETURN
	ENDIF
;
;  Check the IMAGE array.
;
	S = SIZE(IMAGE)
	IF S(0) NE 2 THEN BEGIN
		PRINT,'*** Variable must be two-dimensional, name= IMAGE, routine TVVALUE.'
		RETURN
	ENDIF
;
;  Get the scale of the displayed image.
;
	GET_TV_SCALE,SX,SY,MX,MY,IX,IY,DISABLE=DISABLE
	IF (SX NE S(1)) OR (SY NE S(2)) THEN MESSAGE,	$
		'IMAGE size does not agree with displayed image'
;
	TVSELECT, DISABLE=DISABLE
;
	PRINT,'Press left or center mouse button for new output line.'
	PRINT,'... right mouse button to exit.'
;
	!ERR=0
	NX = FLOAT(MX) / S(1)
	NY = FLOAT(MY) / S(2)
;
;  If the current graphics device supports widgets, then display the text in
;  a special text widget.
;
	IF HAVE_WIDGETS() THEN BEGIN
		TEST = EXECUTE("BASE = WIDGET_BASE(TITLE='TV value',/ROW)")
		TEXT = ' '
		IF N_ELEMENTS(FONT) NE 1 THEN FONT = '*20'
		TEST = EXECUTE("LABEL = WIDGET_TEXT(BASE,VALUE=TEXT," +	$
			"FONT=FONT,XSIZE=52)")
		WIDGET_CONTROL,BASE,/REALIZE
	ENDIF
;
;  Form the format statement.
;
	IF S(S(0)+1) GE 4 THEN FORMAT = 'F' ELSE FORMAT = 'I'
	CR = STRING("15B)
	FORMAT = "'X=',I6,', Y=',I6,', VALUE='," + FORMAT
	IF HAVE_WIDGETS() THEN FORMAT = '(' + FORMAT + ')' ELSE	$
		FORMAT = "($," + FORMAT + ",A)"
;
;  Keep reading the cursor until the right button is pressed.
;
	WHILE !ERR NE 4 DO BEGIN
		TVPOS,X,Y,WAIT=2,/DISABLE
		IF (!ERR AND 3) NE 0 THEN BEGIN		;New line?
			IF HAVE_WIDGETS() THEN PRINT,TEXT ELSE	$
				PRINT,FORMAT="($,A)",STRING("12B)
			WHILE (!ERR NE 0) DO BEGIN
				WAIT,0.1
				TVPOS,X,Y,WAIT=0,/DISABLE
			ENDWHILE
		ENDIF
		X = FIX(X)  &  Y = FIX(Y)
		IF (X LT SX) AND (Y LT SY)  AND (X GE 0) AND (Y GE 0) $
				THEN BEGIN
			VALUE = IMAGE(X,Y)
			IF HAVE_WIDGETS() THEN BEGIN
				TEXT = STRING(X,Y,VALUE,FORMAT=FORMAT)
				WIDGET_CONTROL, LABEL, SET_VALUE=TEXT
			END ELSE PRINT,FORMAT=FORMAT,X,Y,VALUE,CR
		ENDIF
	ENDWHILE
;
	IF HAVE_WIDGETS() THEN BEGIN
		WIDGET_CONTROL, /DESTROY, BASE
		PRINT,TEXT
	END ELSE BEGIN
		PRINT,FORMAT="(/)"
	ENDELSE
	TVUNSELECT, DISABLE=DISABLE
;
	RETURN
	END
