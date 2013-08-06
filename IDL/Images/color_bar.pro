	PRO COLOR_BAR,P0,P1,P2,P3,P4,DISABLE=DISABLE,COLOR=COLOR,MAX=MAX,  $
		MIN=MIN,TOP=TOP,VELOCITY=VELOCITY,COMBINED=COMBINED,	$
		LOWER=LOWER,MISSING=MISSING,ABOVE=ABOVE,RIGHT=RIGHT,	$
		TITLE=TITLE,TICKLEN=TICKLEN,TICKNAME=TICKNAME,TICKS=TICKS, $
		TICKV=TICKV,TYPE=TYPE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	COLOR_BAR
; Purpose     : 
;	Display a color bar on an image display screen.
; Explanation : 
;	Unless the optional parameters are set, the user is prompted to enter
;	in where the color bar should be placed.
; Use         : 
;	COLOR_BAR  [, ARRAY ]  [, MX, MY, IX, IY ]
; Inputs      : 
;	None required.
; Opt. Inputs : 
;	ARRAY	= Image array to use in determining the scale.
;	MX, MY	= Dimensions of color bar, in device coordinates
;	IX, IY	= Position of lower left-hand corner of color bar.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	COLOR	 = Color used for drawing the box around the color bar.
;	MAX	 = The maximum value of ARRAY to be considered in scaling the
;		   color bar, as used by BYTSCL.  The default is either the
;		   highest color index available, or the value set by SETFLAG.
;	MIN	 = The minimum value of ARRAY to be considered in scaling the
;		   color bar, as used by BYTSCL.  The default is either zero
;		   or the value set by SETFLAG.
;	TOP	 = The maximum value of the scaled color bar, as used by
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
;	MISSING	 = Value flagging missing pixels.  Used when passing ARRAY to
;		   help determine the scale.
;	ABOVE	 = If set, and the color bar is horizontal, then the axis label
;		   is drawn above the color bar rather than below.
;	RIGHT	 = If set, and the color bar is vertical, then the axis label
;		   is drawn to the right of the color bar, instead of the left.
;	TITLE	 = Character string label to apply to color bar.  Default is
;		   none.
;	TICKLEN	 = Length of tick marks.  Default is !TICKLEN.
;	TICKNAME = String array giving the annotation of each tick.
;	TICKS	 = Number of major tick intervals to draw.
;	TICKV	 = Array of values for each tick mark.
;	TYPE	 = If 1, then the scaling is logarithmic.  If this option is
;		   used, then the scale must be explicitly set, with the
;		   minimum and maximum values being greater than zero.
; Calls       : 
;	EXPAND_TV, GET_IM_KEYWORD, SELECT_BOX, TVAXIS, TVSELECT, TVUNSELECT
; Common      : 
;	None.
; Restrictions: 
;	To get the best results, care must be taken to make the color bar range
;	match that of the displayed image.  The easiest way to do this is to
;	use SETFLAG,MIN=...,MAX=... to control the range for both displaying
;	the image and the color bar.  Or one can pass the image array to this
;	routine to calculate the scale from.
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
;	Messages about the size and position of the displayed image are printed
;	to the terminal screen.  This can be turned off by setting !QUIET to 1.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, May 1992.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
;	William Thompson, September 1992, use COMBINED keyword in place of
;					  INTENSITY.
; Written     : 
;	William Thompson, GSFC, May 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 14 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 19 October 1994
;		Added keywords TICKLEN,TICKNAME,TICKS,TICKV,TYPE
; Version     : 
;	Version 2, 19 October 1994
;-
;
	ON_ERROR,2
	GET_IM_KEYWORD, MISSING, !IMAGE.MISSING
;
;  Check the number of parameters.
;
	IF (N_PARAMS() GT 1) AND (N_PARAMS() LT 4) THEN MESSAGE,	$
		'Syntax:  COLOR_BAR  [, ARRAY ]  [, MX, MY, IX, IY ]'
;
;  Select the image display device.
;
	TVSELECT, DISABLE=DISABLE
;
;  Get the position of the color bar.
;
	IF N_PARAMS() LT 4 THEN BEGIN
		SELECT_BOX,MX,MY,IX,IY
	END ELSE IF N_PARAMS() EQ 4 THEN BEGIN
		MX = P0
		MY = P1
		IX = P2
		IY = P3
	END ELSE BEGIN
		MX = P1
		MY = P2
		IX = P3
		IY = P4
	ENDELSE
;
;  Decide if the color bar is horizontal or vertical.  Let the bar vary from -1
;  to +1.  That way it can be used for either intensity or velocity color
;  tables.
;
	MMX = MX < 256
	MMY = MY < 256
	IF MX GE MY THEN BEGIN
		BAR = 2*FINDGEN(MMX)/(MMX-1) - 1
		BAR = BAR # REPLICATE(1,MMY)
	END ELSE BEGIN
		BAR = 2*FINDGEN(MMY)/(MMY-1) - 1
		BAR = REPLICATE(1,MMX) # BAR
	ENDELSE
;
;  Display the color bar.
;
	EXPAND_TV,/DISABLE,BAR,MX,MY,IX,IY,NOBOX=0,MAX=1,MIN=-1,TOP=TOP, $
		VELOCITY=VELOCITY,COMBINED=COMBINED,LOWER=LOWER,	$
		COLOR=COLOR,/NOSTORE
;
;  Choose the minimum and maximum values for the axis.  Use velocity scaling if
;  the VELOCITY keyword is set.
;
	IF KEYWORD_SET(VELOCITY) THEN BEGIN
		GET_IM_KEYWORD,MIN,!IMAGE.VMIN
		GET_IM_KEYWORD,MAX,!IMAGE.MAX
		IF (N_ELEMENTS(MIN) EQ 1) AND (N_ELEMENTS(MAX) EQ 1) THEN BEGIN
			IMAX = ABS(MIN) > ABS(MAX)
		END ELSE IF N_ELEMENTS(MIN) EQ 1 THEN BEGIN
			IMAX = ABS(MIN)
		END ELSE IF N_ELEMENTS(MAX) EQ 1 THEN BEGIN
			IMAX = ABS(MAX)
		END ELSE IF (N_PARAMS() EQ 1) OR (N_PARAMS() EQ 5) THEN BEGIN
			IF N_ELEMENTS(MISSING) EQ 1 THEN BEGIN
				W = WHERE(P0 NE MISSING)
				IMAX = MAX(ABS(P0(W)))
			END ELSE BEGIN
				IMAX = MAX(ABS(P0))
			ENDELSE
		END ELSE BEGIN
			IMAX = 1
		ENDELSE
		IMIN = -IMAX
;
;  Otherwise, use intensity scaling.
;
	END ELSE BEGIN
		IF (N_PARAMS() EQ 1) OR (N_PARAMS() EQ 5) THEN BEGIN
			IF N_ELEMENTS(MISSING) EQ 1 THEN BEGIN
				W = WHERE(P0 NE MISSING)
				IMAX = MAX(P0(W),MIN=IMIN)
			END ELSE BEGIN
				IMAX = MAX(P0,MIN=IMIN)
			ENDELSE
		END ELSE BEGIN
			IMIN = 0
			IMAX = !D.N_COLORS-1
		ENDELSE
		GET_IM_KEYWORD,MIN,!IMAGE.MIN
		GET_IM_KEYWORD,MAX,!IMAGE.MAX
		IF N_ELEMENTS(MIN) EQ 1 THEN IMIN = MIN
		IF N_ELEMENTS(MAX) EQ 1 THEN IMAX = MAX
	ENDELSE
;
;  Plot the axis.
;
	IF N_ELEMENTS(TITLE) EQ 0 THEN TITLE = ''
	IF MX GE MY THEN BEGIN
		TVAXIS,BAR,MX,MY,IX,IY,XAXIS=KEYWORD_SET(ABOVE),	$
			XRANGE=[IMIN,IMAX],XTITLE=TITLE,COLOR=COLOR,	$
			XTICKLEN=TICKLEN,XTICKNAME=TICKNAME,XTICKS=TICKS, $
			XTICKV=TICKV,XTYPE=TYPE,/DISABLE
	END ELSE BEGIN
		TVAXIS,BAR,MX,MY,IX,IY,YAXIS=KEYWORD_SET(RIGHT),	$
			YRANGE=[IMIN,IMAX],YTITLE=TITLE,COLOR=COLOR,	$
			YTICKLEN=TICKLEN,YTICKNAME=TICKNAME,YTICKS=TICKS, $
			YTICKV=TICKV,YTYPE=TYPE,/DISABLE
	ENDELSE
;
	TVUNSELECT,DISABLE=DISABLE
	RETURN
	END
