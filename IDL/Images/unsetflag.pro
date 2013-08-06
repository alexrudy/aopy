	PRO UNSETFLAG,NOSQUARE=NOSQUARE,SMOOTH=SMOOTH,NOBOX=NOBOX,	$
		NOSCALE=NOSCALE,MISSING=MISSING,SIZE=SIZE,		$
		NOEXACT=NOEXACT,XALIGN=XALIGN,YALIGN=YALIGN,		$
		RELATIVE=RELATIVE,MIN=MIN,MAX=MAX,VELOCITY=VELOCITY,	$
		TOP=TOP,COMBINED=COMBINED,VMIN=VMIN,VMAX=VMAX
;+
; Project     : SOHO - CDS
;
; Name        : 
;	UNSETFLAG
; Purpose     : 
;	Unset a flag field set by SETFLAG.
; Explanation : 
;	Inverse procedure to SETFLAG and ENABLEFLAG.  Unsets one of the flag
;	fields in the !IMAGE structure.
; Use         : 
;	UNSETFLAG, /Keyword, ...
;
;	Use only the /KEYWORD form for the keywords.  Do not use KEYWORD=VALUE.
;
; Inputs      : 
;	None.  Only keyword parameters are used by this routine.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	NOSQUARE = If set, then pixels are not forced to be square.
;	SMOOTH	 = If set, then image is expanded with interpolation.
;	NOBOX	 = If set, then box is not drawn, and no space is reserved
;		   for a border around the image.
;	NOSCALE	 = If set, then the command TV is used instead of TVSCL to
;		   display the image.
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero.  Ignored if NOSCALE is set.
;	SIZE	 = If passed and positive, then used to determine the scale of
;		   the image.
;	NOEXACT  = If set, then exact scaling is not imposed.  Otherwise, the
;		   image scale will be either an integer, or one over an
;		   integer.  Ignored if SIZE is passed with a positive value.
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
;	COMBINED = Signal to FORM_VEL to scale velocity images so that they can
;		   be displayed together with intensity images.
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
;	W.T.T., Nov. 1991, added keywords MIN, MAX, VMIN, VMAX, TOP and
;			   COMBINED.
;	W.T.T., May 1992, added VELOCITY keyword, and made VMIN, VMAX alternate
;			  format.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
; Written     : 
;	William Thompson, GSFC, June 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 4 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 4 May 1993.
;-
;
	IF KEYWORD_SET(NOSQUARE) THEN !IMAGE.NOSQUARE = 0
	IF KEYWORD_SET(SMOOTH) THEN !IMAGE.SMOOTH = 0
	IF KEYWORD_SET(NOBOX) THEN !IMAGE.NOBOX = 0
	IF KEYWORD_SET(NOSCALE) THEN !IMAGE.NOSCALE = 0
	IF KEYWORD_SET(MISSING) THEN !IMAGE.MISSING.SET = 0
	IF KEYWORD_SET(SIZE) THEN !IMAGE.SIZE.SET = 0
	IF KEYWORD_SET(NOEXACT) THEN !IMAGE.NOEXACT = 0
	IF KEYWORD_SET(XALIGN) THEN !IMAGE.XALIGN.SET = 0
	IF KEYWORD_SET(YALIGN) THEN !IMAGE.YALIGN.SET = 0
	IF KEYWORD_SET(RELATIVE) THEN !IMAGE.RELATIVE.SET = 0
	IF KEYWORD_SET(VMIN) THEN !IMAGE.VMIN.SET = 0
	IF KEYWORD_SET(VMAX) THEN !IMAGE.VMAX.SET = 0
	IF KEYWORD_SET(TOP) THEN !IMAGE.TOP.SET = 0
	IF KEYWORD_SET(COMBINED) THEN !IMAGE.COMBINED = 0
;
	IF KEYWORD_SET(MIN) THEN IF KEYWORD_SET(VELOCITY) THEN	$
		!IMAGE.VMIN.SET = 0 ELSE !IMAGE.MIN.SET=0
	IF KEYWORD_SET(MAX) THEN IF KEYWORD_SET(VELOCITY) THEN	$
		!IMAGE.VMAX.SET = 0 ELSE !IMAGE.MAX.SET = 0
;
	RETURN
	END
