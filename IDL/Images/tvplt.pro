	PRO TVPLT,XVAL,YVAL,IMAGE,MX,MY,IX,IY,DISABLE=DISABLE,PSYM=PSYM, $
		COLOR=COLOR,THICK=THICK
;+
; Project     : SOHO - CDS
;
; Name        : 
;	TVPLT
; Purpose     : 
;	Plots points on displayed images.
; Explanation : 
;	The values MX, MY and IX, IY are used to convert the data coordinates
;	XVAL, YVAL to screen coordinates.  Then OPLOT is used to plot the 
;	points.
; Use         : 
;	TVPLT, XVAL, YVAL  [, IMAGE, MX, MY, IX, IY ]
; Inputs      : 
;	XVAL,YVAL = The X,Y positions of the points to plot.
; Opt. Inputs : 
;	IMAGE	  = The image to plot over.
;	MX, MY	  = Size of displayed image.
;	IX, IY	  = Position of the lower left-hand corner of the image.
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
;	DISABLE   = If set, then TVSELECT not used.
;	PSYM	  = Plotting symbol.
;	COLOR	  = Plotting color.
;	THICK	  = Plotting thickness.
; Calls       : 
;	GET_TV_SCALE, TVSELECT, TVUNSELECT
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
;	William Thompson, May 1992, modified to use GET_TV_SCALE.
;	William Thompson, Oct 1992, added THICK keyword.
;
; Written     : 
;	William Thompson, GSFC, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 11 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 11 May 1993.
;-
;
	ON_ERROR,2
;
	IF (N_PARAMS() NE 2) AND (N_PARAMS() NE 7) THEN MESSAGE,	$
		'Syntax:  TVPLT, XVAL, YVAL  [, IMAGE, MX, MY, IX, IY ]'
;
	IF N_PARAMS() EQ 2 THEN BEGIN
		GET_TV_SCALE,SX,SY,MX,MY,IX,IY,DISABLE=DISABLE
	END ELSE BEGIN
		S = SIZE(IMAGE)
		IF S(0) NE 2 THEN MESSAGE,'IMAGE must be two-dimensional'
		SX = S(1)
		SY = S(2)
	ENDELSE
;
	IF ((MX LE 1) OR (MY LE 1)) THEN BEGIN
		PRINT,'*** The dimensions MX,MY must be > 1, routine TVPLT.'
		RETURN
	ENDIF
;
;  Set the image display device or window.
;
	TVSELECT, DISABLE=DISABLE
;
;  Make sure the optional plotting keywords are defined.
;
	IF N_ELEMENTS(COLOR) EQ 0 THEN COLOR = !COLOR
	IF N_ELEMENTS(PSYM)  EQ 0 THEN PSYM  = !PSYM
	IF N_ELEMENTS(THICK) EQ 0 THEN THICK = !P.THICK
;
;  Set the proper coordinate system, and plot the points XVAL, YVAL.
;
	XS = SX / FLOAT(MX)
	YS = SY / FLOAT(MY)
	PLOTS,IX + XVAL/XS,IY + YVAL/YS,/DEVICE,PSYM=PSYM,COLOR=COLOR,THICK=THICK
	TVUNSELECT, DISABLE=DISABLE
;
	RETURN
	END
