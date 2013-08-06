	PRO SETFLAG,NOSQUARE=NOSQUARE,SMOOTH=SMOOTH,NOBOX=NOBOX,	$
		NOSCALE=NOSCALE,MISSING=MISSING,SIZE=SIZE,		$
		NOEXACT=NOEXACT,XALIGN=XALIGN,YALIGN=YALIGN,		$
		RELATIVE=RELATIVE,MIN=MIN,MAX=MAX,VELOCITY=VELOCITY,	$
		TOP=TOP,COMBINED=COMBINED,VMIN=VMIN,VMAX=VMAX
;+
; Project     : SOHO - CDS
;
; Name        : 
;	SETFLAG
; Purpose     : 
;	Sets flags to control behavior of image display routines.
; Explanation : 
;	Sets one of the flag fields in the !IMAGE structure.  One can use this
;	routine to set the default value of one of the SERTS keyword parameters
;	once rather than passing the relevant keyword to each and every
;	routine.  Passing the keyword to any individual routine takes
;	precedence over SETFLAG.
;
;	Use UNSETFLAG to disable any keyword set with SETFLAG.
;
;	Use ENABLEFLAG instead of SETFLAG to reenable one of the keyword that
;	takes a value, such as MISSING or SIZE, without disturbing the value
;	of that keyword.
;
;	Use SHOWFLAGS to show what flags are set, and what values they have.
;
; Use         : 
;	SETFLAG, Keyword=Value or /Keyword, ...
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
;	Version 1, William Thompson, GSFC, 12 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 12 May 1993.
;-
;
	IF KEYWORD_SET(NOSQUARE) THEN !IMAGE.NOSQUARE = 1
;
	IF KEYWORD_SET(SMOOTH) THEN !IMAGE.SMOOTH = 1
;
	IF KEYWORD_SET(NOBOX) THEN !IMAGE.NOBOX = 1
;
	IF KEYWORD_SET(NOSCALE) THEN !IMAGE.NOSCALE = 1
;
	IF N_ELEMENTS(MISSING) EQ 1 THEN BEGIN
		!IMAGE.MISSING.SET = 1
		!IMAGE.MISSING.VALUE = MISSING
	ENDIF
;
	IF N_ELEMENTS(SIZE) EQ 1 THEN BEGIN
		!IMAGE.SIZE.SET = 1
		!IMAGE.SIZE.VALUE = SIZE
	ENDIF
;
	IF KEYWORD_SET(NOEXACT) THEN !IMAGE.NOEXACT = 1
;
	IF N_ELEMENTS(XALIGN) EQ 1 THEN BEGIN
		!IMAGE.XALIGN.SET = 1
		!IMAGE.XALIGN.VALUE = XALIGN
	ENDIF
;
	IF N_ELEMENTS(YALIGN) EQ 1 THEN BEGIN
		!IMAGE.YALIGN.SET = 1
		!IMAGE.YALIGN.VALUE = YALIGN
	ENDIF
;
	IF N_ELEMENTS(RELATIVE) EQ 1 THEN BEGIN
		!IMAGE.RELATIVE.SET = 1
		!IMAGE.RELATIVE.VALUE = RELATIVE
	ENDIF
;
	IF N_ELEMENTS(MIN) EQ 1 THEN BEGIN
		IF KEYWORD_SET(VELOCITY) THEN BEGIN
			!IMAGE.MIN.SET = 1
			!IMAGE.MIN.VALUE = MIN
		END ELSE BEGIN
			!IMAGE.MIN.SET = 1
			!IMAGE.MIN.VALUE = MIN
		ENDELSE
	ENDIF
;
	IF N_ELEMENTS(MAX) EQ 1 THEN BEGIN
		IF KEYWORD_SET(VELOCITY) THEN BEGIN
			!IMAGE.MAX.SET = 1
			!IMAGE.MAX.VALUE = MAX
		END ELSE BEGIN
			!IMAGE.MAX.SET = 1
			!IMAGE.MAX.VALUE = MAX
		ENDELSE
	ENDIF
;
	IF N_ELEMENTS(VMIN) EQ 1 THEN BEGIN
		!IMAGE.VMIN.SET = 1
		!IMAGE.VMIN.VALUE = VMIN
	ENDIF
;
	IF N_ELEMENTS(VMAX) EQ 1 THEN BEGIN
		!IMAGE.VMAX.SET = 1
		!IMAGE.VMAX.VALUE = VMAX
	ENDIF
;
	IF N_ELEMENTS(TOP) EQ 1 THEN BEGIN
		!IMAGE.TOP.SET = 1
		!IMAGE.TOP.VALUE = TOP
	ENDIF
;
	IF KEYWORD_SET(COMBINED) THEN !IMAGE.COMBINED = 1
;
	RETURN
	END
