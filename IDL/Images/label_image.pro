	PRO LABEL_IMAGE,TITLE,BELOW=BELOW,LEFT=LEFT,RIGHT=RIGHT,CENTER=CENTER,$
		DISABLE=DISABLE,CHARSIZE=CHAR_SIZE,COLOR=COLOR,REVERSE=REVERSE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	LABEL_IMAGE
; Purpose     : 
;	Puts labels on images.
; Explanation : 
;	The routine XYOUTS is used to display the title centered either above
;	or below the image, or to either side of the image.
; Use         : 
;	LABEL_IMAGE, TITLE
; Inputs      : 
;	TITLE	 = Character string to be output to image.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	BELOW	 = If set, then the title is displayed below the image.
;	LEFT	 = If set, then the title is displayed to the left of the
;		   image.  Overrides BELOW keyword.
;	RIGHT	 = If set, then the title is displayed to the right of the
;		   image.  Overrides BELOW and LEFT keywords.
;	CENTER	 = If set, then the title is centered on the screen, regardless
;		   of where the image is.  Centering is in X, unless the LEFT
;		   or RIGHT keywords are set, in which case it is in Y.
;	CHARSIZE = Character size to use in displaying titles.  Normally 1.
;	COLOR	 = Color to display label in.
;	DISABLE  = If set, then TVSELECT not used.
;	REVERSE	 = If set, then the orientation of the letters is 180 degrees
;		   from what it ordinarily would be.
; Calls       : 
;	GET_TV_SCALE, TVSELECT, TVUNSELECT
; Common      : 
;	None.
; Restrictions: 
;	There must be enough space to display the title.
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
;	William Thompson, March 1991.
;	William Thompson, May 1992, modified to use GET_TV_SCALE.
;	William Thompson, Nov 1992, modified algorithm for getting the relative
;		character size.
; Written     : 
;	William Thompson, GSFC, March 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 13 May 1993.
;-
;
	ON_ERROR,2
;
;  Check the number of parameters.
;
	IF N_PARAMS() NE 1 THEN MESSAGE,'Syntax:  LABEL_IMAGE, TITLE'
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
;  Get the parameters describing the displayed image.
;
	GET_TV_SCALE,SX,SY,MX,MY,IX,IY,DISABLE=DISABLE
;
;  If the CENTER keyword is set, then modify the parameters to center the
;  title.
;
	IF KEYWORD_SET(CENTER) THEN BEGIN
		IF KEYWORD_SET(LEFT) OR KEYWORD_SET(RIGHT) THEN BEGIN
			MY = Y_SIZE  &  IY = 0
		END ELSE BEGIN
			MX = X_SIZE  &  IX = 0
		ENDELSE
	ENDIF
;
;  Calculate the position of the center of label.
;
	XCEN = IX + MX/2
	YCEN = IY + MY/2
	ORIENTATION = 0
	IF KEYWORD_SET(RIGHT) THEN BEGIN
		XCEN = IX + MX + 0.875*Y_CH_SIZE
		ORIENTATION = 90
	END ELSE IF KEYWORD_SET(LEFT) THEN BEGIN
		XCEN = IX - 0.375*Y_CH_SIZE
		ORIENTATION = 90
	END ELSE IF KEYWORD_SET(BELOW) THEN BEGIN
		YCEN = IY - 0.875*Y_CH_SIZE
	END ELSE BEGIN
		YCEN = IY + MY + 0.375*Y_CH_SIZE
	ENDELSE
;
;  Check to make sure that the label will fit within the confines of the
;  graphics device.
;
	IF ORIENTATION EQ 0 THEN BEGIN
		CEN = YCEN
		H_SIZE = Y_SIZE
		W_SIZE = X_SIZE
	END ELSE BEGIN
		CEN = XCEN
		H_SIZE = X_SIZE
		W_SIZE = Y_SIZE
	ENDELSE
;
	IF ((CEN - 0.25*Y_CH_SIZE) LT 0) OR	$
			((CEN + 0.75*Y_CH_SIZE) GT H_SIZE) THEN BEGIN
		PRINT,'*** Not enough space to display the label, ' +	$
			'routine LABEL_IMAGE.'
		RETURN
	END ELSE IF STRLEN(TITLE)*X_CH_SIZE GT W_SIZE THEN BEGIN
		PRINT,'*** Label is too wide to display, routine LABEL_IMAGE.'
		RETURN
	ENDIF
;
;  If necessary, then rotate the label.
;
	IF KEYWORD_SET(REVERSE) THEN ORIENTATION = ORIENTATION + 180
;
;  Display the label.
;
	TVSELECT, DISABLE=DISABLE
	IF N_ELEMENTS(COLOR) EQ 0 THEN COLOR = !COLOR
	XYOUTS,XCEN,YCEN,TITLE,ALIGNMENT=0.5,/DEVICE,CHARSIZE=CHARSIZE,	$
		COLOR=COLOR,ORIENTATION=ORIENTATION
	TVUNSELECT, DISABLE=DISABLE
;
	RETURN
	END
