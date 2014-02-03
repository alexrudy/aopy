	PRO STORE_TV_SCALE, SX0, SY0, MX0, MY0, JX0, JY0, DISABLE=DISABLE, $
		ORIGIN=ORIGIN, SCALE=SCALE, DATA=DATA_ARRAY
;+
; Project     : SOHO - CDS
;
; Name        : 
;	STORE_TV_SCALE
; Purpose     : 
;	Store information about displayed images.
; Explanation : 
;	Stores information about images displayed by EXPTV, PUT, and other
;	routines.  Called from SCALE_TV.
;
;	Data arrays containing the passed parameters, as well as !D.NAME,
;	!D.WINDOW, and the parameters from SETIMAGE, are stored in the TV_SCALE
;	common block.  Each time the routine is called, if the common block
;	already contains an entry for the NAME, WINDOW and SETIMAGE variables,
;	then the other variables are updated.  Otherwise, another entry is
;	added to the database.
;
; Use         : 
;	STORE_TV_SCALE, SX, SY, MX, MY, JX, JY
; Inputs      : 
;	SX, SY	= Image size, in data pixels
;	MX, MY	= Image size, in screen pixels
;	JX, JY	= Position of lower left-hand corner of displayed image, in
;		  screen pixels.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	DISABLE  = If set, then TVSELECT not used.
;	ORIGIN	 = Two-element array containing the coordinate value in
;		   physical units of the center of the first pixel in the
;		   image.  If not passed, then [0,0] is assumed.
;	SCALE	 = Pixel scale in physical units.  Can have either one or two
;		   elements.  If not passed, then 1 is assumed in both
;		   directions.
;	DATA	 = Used to override the ORIGIN and SCALE keywords.  The value
;		   of this keyword is a structure variable containing the data
;		   needed to convert pixel coordinates into data coordinates.
;		   The main use of this keyword is to support the routine
;		   TVAXIS.
; Calls       : 
;	BOOST_ARRAY, TVSELECT, TVUNSELECT
; Common      : 
;	TV_SCALE contains the passed parameters as a function of graphics
;	device, window, and SETIMAGE settings.  The parameters needed to
;	translate pixel coordinates into data coordinates are also store in
;	this common block.
;
;	IMAGE_AREA contains switch IMAGE_SET and position IX, NX, IY, NY, from
;	SETIMAGE.
;
; Restrictions: 
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
;	William Thompson, May 1992.
; Written     : 
;	William Thompson, GSFC, May 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 12 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 1 September 1993.
;		Added calculation of data coordinates.
;		Added ORIGIN and SCALE keywords.
;		Added variable DATA to TV_SCALE common block.
;	Version 3, William Thompson, GSFC, 9 November 1993.
;		Removed (unnecessary) restriction that scales be positive.
; Version     : 
;	Version 3, 9 November 1993.
;-
;
	ON_ERROR,2
	COMMON TV_SCALE, NAME,WINDOW,IX,NX,IY,NY,SX,SY,MX,MY,JX,JY,DATA
	COMMON IMAGE_AREA, IMAGE_SET, IX0, NX0, IY0, NY0
;
;  Check the number of parameters.
;
	IF N_PARAMS() NE 6 THEN MESSAGE,	$
		'Syntax:  STORE_TV_SCALE, SX, SY, MX, MY, JX, JY'
;
;  Make sure that the IMAGE_AREA common block parameters are defined.
;
	IF N_ELEMENTS(IMAGE_SET) EQ 0 THEN BEGIN
		IMAGE_SET = 0
		IX0 = 1  &  NX0 = 1
		IY0 = 1  &  NY0 = 1
	ENDIF
;
;  Also make sure that the parameters make sense.
;
	IF NOT IMAGE_SET THEN BEGIN
		IX0 = 1  &  NX0 = 1
		IY0 = 1  &  NY0 = 1
	ENDIF
;
;  Get the image origin.
;
	IF N_ELEMENTS(ORIGIN) EQ 0 THEN BEGIN
		ORIGIN = [0,0]
	END ELSE IF N_ELEMENTS(ORIGIN) NE 2 THEN BEGIN
		MESSAGE,'ORIGIN must have two elements, using [0,0]',/CONTINUE
		ORIGIN = [0,0]
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
;  Select the image display device or window.
;
	TVSELECT, DISABLE=DISABLE
;
;  Define the data coordinates for this image, and the clip region.
;
	XSIZE = FLOAT(!D.X_SIZE)  &  YSIZE = FLOAT(!D.Y_SIZE)
	XS = !X.S  &  XS(1) = MX0 / (XSIZE * XSCALE * SX0)
	YS = !Y.S  &  YS(1) = MY0 / (YSIZE * YSCALE * SY0)
	XS(0) = JX0 / XSIZE - (ORIGIN(0) - XSCALE/2.)*XS(1)
	YS(0) = JY0 / YSIZE - (ORIGIN(1) - YSCALE/2.)*YS(1)
	CLIP = [JX0,JY0,JX0+MX0-1,JY0+MY0-1]
;
;  Define the structure containing the information about the data coordinates
;  of the image.
;
	IF N_ELEMENTS(DATA_ARRAY) EQ 1 THEN DT = DATA_ARRAY ELSE	$
		DT = {SV_TVSCL,	CLIP: CLIP,	$
				XS: XS,		$
				YS: YS}
;
;  Check to see if the TV_SCALE common block parameters are defined.  If not,
;  then initialize with the current parameters.
;
	IF N_ELEMENTS(NAME) EQ 0 THEN BEGIN
		NAME	= !D.NAME
		WINDOW	= !D.WINDOW
		IX	= IX0
		NX	= NX0
		IY	= IY0
		NY	= NY0
		SX	= SX0
		SY	= SY0
		MX	= MX0
		MY	= MY0
		JX	= JX0
		JY	= JY0
		DATA	= DT
;
;  Otherwise, search for the current settings in the database.
;
	END ELSE BEGIN
		W = WHERE((NAME EQ !D.NAME) AND (WINDOW EQ !D.WINDOW) AND $
			(IX EQ IX0) AND (NX EQ NX0) AND (IY EQ IY0) AND	  $
			(NY EQ NY0), N_FOUND)
;
;  If not found, then append the data to the common block arrays.
;
		IF N_FOUND EQ 0 THEN BEGIN
			BOOST_ARRAY,NAME,!D.NAME
			BOOST_ARRAY,WINDOW,!D.WINDOW
			BOOST_ARRAY,IX,IX0
			BOOST_ARRAY,NX,NX0
			BOOST_ARRAY,IY,IY0
			BOOST_ARRAY,NY,NY0
			BOOST_ARRAY,SX,SX0
			BOOST_ARRAY,SY,SY0
			BOOST_ARRAY,MX,MX0
			BOOST_ARRAY,MY,MY0
			BOOST_ARRAY,JX,JX0
			BOOST_ARRAY,JY,JY0
			DATA = [DATA,DT]
;
;  Otherwise, update the data at the appropriate place in the common block
;  arrays.
;
		END ELSE BEGIN
			SX(W)	= SX0
			SY(W)	= SY0
			MX(W)	= MX0
			MY(W)	= MY0
			JX(W)	= JX0
			JY(W)	= JY0
			DATA(W)	= DT
		ENDELSE
	ENDELSE
;
;  Unselect the image display device or window, and return
;
	TVUNSELECT, DISABLE=DISABLE
	RETURN
	END
