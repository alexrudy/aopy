	PRO PLOT_IMAGE,IMAGE,ORIGIN=ORIGIN,SCALE=SCALE,NOERASE=NOERASE,	$
		NOSQUARE=NOSQUARE,SMOOTH=SMOOTH,NOSCALE=NOSCALE,	$
		MISSING=MISSING,COLOR=COLOR,MAX=MAX,MIN=MIN,TOP=TOP,	$
		VELOCITY=VELOCITY,COMBINED=COMBINED,LOWER=LOWER,	$
		NOADJUST=NOADJUST,TITLE=TITLE,XTITLE=XTITLE,YTITLE=YTITLE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	PLOT_IMAGE
; Purpose     : 
;	Display images with plot axes around it.
; Explanation : 
;	Display images with plot axes around it.  Subsequent graphics commands,
;	such as OPLOT and CURSOR, can then be called in the ordinary way.  In
;	other words, the concept is to make displaying an image a graphics
;	command, like PLOT or CONTOUR.  Then the special TV calls don't have to
;	be used.
;
;	SETSCALE is called to set the scale.  Axes are then plotted, and
;	EXPAND_TV is called to display the image.  SETSCALE is then called
;	again to reset to the default.
;
;	If the NOSQUARE keyword is set, then SETSCALE is not called.  In this
;	case, either the scale will be chosen in the normal manner, or a
;	predefined scale (e.g. using SETSCALE) will be used.
;
; Use         : 
;	PLOT_IMAGE, IMAGE
; Inputs      : 
;	IMAGE	 = Two dimensional image array to be displayed.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	ORIGIN	 = Two-element array containing the coordinate value in
;		   physical units of the center of the first pixel in the
;		   image.  If not passed, then [0,0] is assumed.
;	SCALE	 = Pixel scale in physical units.  Can have either one or two
;		   elements.  If not passed, then 1 is assumed in both
;		   directions.
;	NOERASE	 = If set, then the screen is not erased before putting up the
;		   plot.
;	NOSQUARE = If set, then the scales in the X and Y directions are not
;		   forced to be the same.
;	NOADJUST = If set, then the viewport parameters !SC1,!SC2,!SC3,!SC4 are
;		   not modified.  Ignored if NOSQUARE is set.
;	SMOOTH	 = If set, then the image is expanded with bilinear
;		   interpolation.
;	NOSCALE  = If set, then the command TV is used instead of TVSCL to
;		   display the image.
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero.  Ignored if NOSCALE is set.
;	COLOR	 = Color used for drawing the axes.
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
;	TITLE	 = Main plot title, default is !P.TITLE.
;	XTITLE	 = X axis title, default is !X.TITLE.
;	YTITLE	 = Y axis title, default is !Y.TITLE.
; Calls       : 
;	EXPAND_TV, SETSCALE
; Common      : 
;	None.
; Restrictions: 
;	The graphics device must be capable of displaying images.
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
;	Unless the NOSQUARE keyword is set, the system variables !X.STYLE,
;	!Y.STYLE, !X.S, !Y.S, !X.RANGE (!XMIN and !XMAX) and !Y.RANGE (!YMIN
;	and !YMAX) are modified.  Any previous settings are lost.
;
;	System variables may be changed even if the routine exits with an error
;	message.
;
;	Messages about the size and position of the displayed image are printed
;	to the terminal screen.  This can be turned off by setting !QUIET to 1.
;
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, May 1992.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
;	William Thompson, September 1992, use COMBINED keyword in place of
;		INTENSITY.
;	William Thompson, October 1992, modified so that keyword ORIGIN refers
;		to the center of the first pixel, rather than to the lower left
;		corner.
;	William Thompson, November 1992, modified behavior when /NOSQUARE
;		keyword is used to force exact X and Y ranges.
;	William Thompson, November 1992, modified to be compatible with
;		!P.MULTI.
;	William Thompson, January 1993, modified to use modern system variable
;		names.
;	William Thompson, 28 April 1993, fixed bug with COLOR keyword.
;	William Thompson, 30 April 1993, fixed bug with !P.MULTI.
; Written     : 
;	William Thompson, GSFC, May 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 12 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 9 November 1993.
;		Removed (unnecessary) restriction that scales be positive.
; Version     : 
;	Version 2, 9 November 1993.
;-
;
	ON_ERROR,2
;
;  Check the number of parameters.
;
	IF N_PARAMS() NE 1 THEN MESSAGE,'Syntax:  PLOT_IMAGE, IMAGE'
;
;  Check the image size.
;
	SZ = SIZE(IMAGE)
	IF SZ(0) NE 2 THEN MESSAGE,'IMAGE must be two-dimensional'
;
;  Get the image origin.
;
	IF N_ELEMENTS(ORIGIN) EQ 0 THEN BEGIN
		ORIGIN = [0,0]
	END ELSE IF N_ELEMENTS(ORIGIN) NE 2 THEN BEGIN
		MESSAGE,'ORIGIN must have two elements'
	ENDIF
;
;  Get the image scale.
;
	CASE N_ELEMENTS(SCALE) OF
		0:  BEGIN
			XSCALE = 1
			YSCALE = 1
			END
		1:  BEGIN
			XSCALE = SCALE
			YSCALE = SCALE
			END
		2: BEGIN
			XSCALE = SCALE(0)
			YSCALE = SCALE(1)
			END
	ENDCASE
;
;  Set the scale, and plot the axes.
;
	X1 = ORIGIN(0) - XSCALE/2.  &  X2 = X1 + SZ(1)*XSCALE
	Y1 = ORIGIN(1) - YSCALE/2.  &  Y2 = Y1 + SZ(2)*YSCALE
	IF NOT KEYWORD_SET(NOSQUARE) THEN BEGIN
		SETSCALE,X1,X2,Y1,Y2,/NOBORDER,NOADJUST=NOADJUST
	END ELSE BEGIN
		XSTYLE = !X.STYLE  &  !X.STYLE = !X.STYLE OR 1
		YSTYLE = !Y.STYLE  &  !Y.STYLE = !Y.STYLE OR 1
	ENDELSE
	IF N_ELEMENTS(TITLE)  EQ 0 THEN TITLE  = !P.TITLE
	IF N_ELEMENTS(XTITLE) EQ 0 THEN XTITLE = !X.TITLE
	IF N_ELEMENTS(YTITLE) EQ 0 THEN YTITLE = !Y.TITLE
	IF N_ELEMENTS(COLOR)  EQ 0 THEN COLOR  = !COLOR
	PMULTI = !P.MULTI
	PLOT,[X1,X2],[Y1,Y2],/NODATA,NOERASE=NOERASE,TITLE=TITLE,	$
		XTITLE=XTITLE,YTITLE=YTITLE,COLOR=COLOR
;
;  Set the image display parameters, and display the image.
;
	XS = !X.S * !D.X_SIZE
	YS = !Y.S * !D.Y_SIZE
	MX = XS(1)*SZ(1)*XSCALE
	MY = YS(1)*SZ(2)*YSCALE
	IX = XS(0) + (ORIGIN(0) - XSCALE/2.)*XS(1)
	IY = YS(0) + (ORIGIN(1) - YSCALE/2.)*YS(1)
	EXPAND_TV,IMAGE,MX,MY,IX,IY,SMOOTH=SMOOTH,/NOBOX,NOSCALE=NOSCALE, $
		MISSING=MISSING,/DISABLE,COLOR=COLOR,MAX=MAX,MIN=MIN,	$
		TOP=TOP,VELOCITY=VELOCITY,COMBINED=COMBINED,LOWER=LOWER, $
		/NOSTORE
;
;  Replot the axes to refresh them, and reset the scaling behavior for future
;  plots.
;
	!P.MULTI = PMULTI
	PLOT,[X1,X2],[Y1,Y2],/NODATA,/NOERASE,COLOR=COLOR
	IF NOT KEYWORD_SET(NOSQUARE) THEN BEGIN
		SETSCALE,NOADJUST=NOADJUST
	END ELSE BEGIN
		!X.STYLE = XSTYLE
		!Y.STYLE = YSTYLE
	ENDELSE
;
;  Modify !P.MULTI.  Normally, this would happen automatically, but this has
;  been disabled for this routine.
;
	K = !P.MULTI(0)
	NX = !P.MULTI(1) > 1
	NY = !P.MULTI(2) > 1
	IF (K LE 0) OR (K GT NX*NY) THEN K = NX*NY
	!P.MULTI(0) = (K - 1) MOD (NX*NY)
;
	RETURN
	END
