	PRO MOVE_AND_BLINK,ARRAY1,ARRAY2,ISHIFT,JSHIFT,NOSQUARE=NOSQUARE, $
		NOBOX=NOBOX,SIZE=SIZE,DISABLE=DISABLE,MISSING=MISSING
;+
; Project     : SOHO - CDS
;
; Name        : 
;	MOVE_AND_BLINK
; Purpose     : 
;	Moves and blinks two images together by modifying the color tables.
; Explanation : 
;	BLINK is used to blink together ARRAY1 and ARRAY2.  The user can then
;	move one of these images relative to the other with the keyboard.
; Use         : 
;	MOVE_AND_BLINK, ARRAY1, ARRAY2  [, ISHIFT, JSHIFT ]
; Inputs      : 
;	ARRAY1	 = First image to be blinked against the second image.
;	ARRAY2	 = Second image.  Must have the same dimensions as the first
;		   image.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	ISHIFT	 = Amount of shift in the first dimension.
;	JSHIFT	 = Amount of shift in the second dimension.
; Keywords    : 
;	NOSQUARE = If passed, then pixels are not forced to be square.
;	NOBOX	 = If passed, then box is not drawn, and no space is reserved
;		   for a border around the image.
;	SIZE	 = If passed and positive, then used to determine the scale of
;		   the image.  Returned as the value of the image scale.  May
;		   not be compatible with /NOSQUARE.
;	DISABLE  = If set, then TVSELECT not used.
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero.
; Calls       : 
;	BLINK, TRIM
; Common      : 
;	None.
; Restrictions: 
;	ARRAY1 and ARRAY2 must have the same dimensions.
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
;	The combined image formed from ARRAY1 and ARRAY2 is left on the screen.
;	It may look a little strange.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, March 1991.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
; Written     : 
;	William Thompson, March 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 13 May 1993.
;-
;
;  Check the input parameters.
;
	IF N_PARAMS() NE 2 THEN BEGIN
		PRINT,'*** MOVE_AND_BLINK must be called with two parameters:'
		PRINT,'                    ARRAY1, ARRAY2'
		RETURN
	ENDIF
;
	SZ1 = SIZE(ARRAY1)
	SZ2 = SIZE(ARRAY2)
	IF SZ1(0) NE 2 THEN BEGIN
		PRINT,'*** ARRAY1 must be two-dimensional, ' + $
			'routine MOVE_AND_BLINK.'
		RETURN
	END ELSE IF SZ2(0) NE 2 THEN BEGIN
		PRINT,'*** ARRAY2 must be two-dimensional, ' + $
			'routine MOVE_AND_BLINK.'
		RETURN
	END ELSE IF (SZ1(1) NE SZ2(1)) OR (SZ1(2) NE SZ2(2)) THEN BEGIN
		PRINT,'*** ARRAY1 and ARRAY2 must have the same ' + $
			'dimensions, routine MOVE_AND_BLINK.'
		RETURN
	ENDIF
;
	II = 0
	JJ = 0
	CHAR = ""
	PRINT,"S=slower, F=faster, L=left, R=right, U=up, D=down, Q=quit"
	WHILE STRUPCASE(CHAR) NE "Q" DO BEGIN
		TEST = SHIFT(ARRAY2,II,JJ)
		BLINK,ARRAY1,TEST,NOSQUARE=NOSQUARE,NOBOX=NOBOX,	$
			SIZE=SIZE,DISABLE=DISABLE,MISSING=MISSING,	$
			CHAR=CHAR,/NOMESSAGE
		CASE CHAR OF
			"l":  II = II - 1
			"r":  II = II + 1
			"u":  JJ = JJ + 1
			"d":  JJ = JJ - 1
			"L":  II = II - 5
			"R":  II = II + 5
			"U":  JJ = JJ + 5
			"D":  JJ = JJ - 5
			ELSE:  DUMMY = DUMMY
		ENDCASE
	ENDWHILE
;
	PRINT,'*** The final shift was ' + TRIM(II) + ', ' + TRIM(JJ)
	RETURN
	END
