	PRO ENABLEFLAG,MISSING=MISSING,SIZE=SIZE,XALIGN=XALIGN,YALIGN=YALIGN, $
		RELATIVE=RELATIVE,MIN=MIN,MAX=MAX,VELOCITY=VELOCITY,TOP=TOP,  $
		VMIN=VMIN,VMAX=VMAX
;+
; Project     : SOHO - CDS
;
; Name        : 
;	ENABLEFLAG
; Purpose     : 
;	Reenable a previously set but disabled image display flag.
; Explanation : 
;	Reenables one of the previously set flag fields in the !IMAGE
;	structure.  Only use this routine if the value has already been set by
;	SETFLAG, but the value was disabled with UNSETFLAG.
;
;	Keywords that take only true/false values, such as "NOBOX", are
;	controlled solely by the SETFLAG and UNSETFLAG routines.
;
; Use         : 
;	ENABLEFLAG, /Keyword, ...
;
;	Use only the /KEYWORD form for the keywords.  Do not use KEYWORD=VALUE.
;
; Inputs      : 
;	None.  Only keyword parameters are used by this routine.
; Opt. Inputs : 
;	Noen.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero.  Ignored if NOSCALE is set.
;	SIZE	 = If passed and positive, then used to determine the scale of
;		   the image.
;	XALIGN	 = Alignment within the image display area.  Ranges between 0
;		   (left) to 1 (right).  Default is 0.5 (centered).
;	YALIGN	 = Alignment within the image display area.  Ranges between 0
;		   (bottom) to 1 (top).  Default is 0.5 (centered).
;	RELATIVE = Size of area to be used for displaying the image, relative
;		   to the total size available.  Must be between 0 and 1.
;		   Default is 1.  Passing SIZE explicitly will override this
;		   keyword.
;	MAX	 = The maximum value to be considered in scaling images, as
;		   used by BYTSCL.
;	MIN	 = The minimum value to be considered in scaling images, as
;		   used by BYTSCL.
;	VELOCITY = If set then the MIN and MAX values pertain to velocity
;		   images rather than intensity images.  (An alternate way to
;		   do the same thing is to use the keywords VMIN and VMAX.)
;	TOP	 = The maximum value of the scaled image array, as used by
;		   BYTSCL.
; Calls       : 
;	None.
; Common      : 
;	None.
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
;	William Thompson, June 1991.
;	W.T.T., Nov. 1991, added keywords MIN, MAX, VMIN, VMAX, and TOP.
;	W.T.T., May 1992, added VELOCITY keyword, and made VMIN, VMAX alternate
;			  format.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
; Written     : 
;	William Thompson, GSFC, June 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 13 May 1993.
;-
;
	IF KEYWORD_SET(MISSING) THEN !IMAGE.MISSING.SET = 1
	IF KEYWORD_SET(SIZE) THEN !IMAGE.SIZE.SET = 1
	IF KEYWORD_SET(XALIGN) THEN !IMAGE.XALIGN.SET = 1
	IF KEYWORD_SET(YALIGN) THEN !IMAGE.YALIGN.SET = 1
	IF KEYWORD_SET(RELATIVE) THEN !IMAGE.RELATIVE.SET = 1
	IF KEYWORD_SET(VMIN) THEN !IMAGE.VMIN.SET = 1
	IF KEYWORD_SET(VMAX) THEN !IMAGE.VMAX.SET = 1
	IF KEYWORD_SET(TOP) THEN !IMAGE.TOP.SET = 1
;
	IF KEYWORD_SET(MIN) THEN IF KEYWORD_SET(VELOCITY) THEN	$
		!IMAGE.VMIN.SET = 1 ELSE !IMAGE.MIN.SET = 1
	IF KEYWORD_SET(MAX) THEN IF KEYWORD_SET(VELOCITY) THEN	$
		!IMAGE.VMAX.SET = 1 ELSE !IMAGE.MAX.SET = 1
;
	RETURN
	END
