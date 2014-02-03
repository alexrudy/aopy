	FUNCTION BYTSCLI ,ARR ,MIN=MIN ,MAX=MAX ,TOP=TOP
;+
; Project     :	SOHO - CDS
;
; Name        :	BYTSCLI
;
; Purpose     :	Variation on BYTSCL which allows MAX < MIN.
;
; Explanation :	BYTSCLI is a variation on the standard IDL BYTSCL routine.  It
;		allows for an inverted mapping of input values to output values
;		where the keyword MAX is set less than the keyword MIN.
;		Substituting BYTSCLI for BYTSCL should give more flexibility in
;		image display routines.
;
;		If MAX is greater than MIN, or if either MAX or MIN is not set,
;		then BYTSCLI reproduces the behavior of BYTSCL.
;
; Use         :	Result = BYTSCLI(Arr)
;
;		Default values are supplied for all keywords. If the special case
;		is recognized--namely MIN defined, MAX defined, MIN > MAX--then
;		an inverted relationship between input and output is returned,
;		otherwise the normal byte transformation is applied.
;
;		PRINT,BYTSCLI(INDGEN(11))
;		  0  25  51  76 102 127 153 178 204 229 255
;
;		PRINT,BYTSCLI(INDGEN(11),MIN=10,MAX=0)
;		  255 229 204 178 153 127 102  76  51  25   0
;
; Inputs      :	ARR = Array of data values to be scaled.
;
; Opt. Inputs :	None.
;
; Outputs     :	None.
;
; Opt. Outputs:	None.
;
; Keywords    :	MAX = The value of Array corresponding to the largest byte
;		      value to be used (TOP). If MAX is not provided, Array is
;		      searched for its maximum value.  All values greater than
;		      or equal to MAX are set equal to TOP in the result,
;		      except that if MAX & MIN are both defined & MAX lt MIN
;		      all values LESS than or equal to MAX are set equal to TOP
;		      in the result.
;
;		MIN = The value of Array corresponding to the smallest byte
;		      value to be used (zero). If MIN is not provided, Array is
;		      searched for its smallest value.  All values less than or
;		      equal to MIN are set equal to 0 in the result, except
;		      that if MAX & MIN are both defined & MAX lt MIN all
;		      values GREATER than or equal to MIN are set equal to 0 in
;		      the result.
;
;		TOP = The maximum value of the scaled result.  If TOP is not
;		      specified, 255 is used.
;
; Calls       :	None.
;
; Common      :	None.
;
; Restrictions:	As with BYTSCL, MAX, MIN & TOP must be scalar. Unlike BYTSCL,
;		ARR can also be scalar.
;
;		In general, the SERTS image display routines use several
;		non-standard system variables.  These system variables are
;		defined in the procedure IMAGELIB.  It is suggested that the
;		command IMAGELIB be placed in the user's IDL_STARTUP file.
;
;		Some routines also require the SERTS graphics devices software,
;		generally found in a parallel directory at the site where this
;		software was obtained.  Those routines have their own special
;		system variables.
;
; Side effects:	None.
;
; Category    :	Utilities, Image_display.
;
; Prev. Hist. :	Mark Hadfield, April 1993.
;
; Written     :	Mark Hadfield, April 1993.
;
; Modified    :	Version 1, William Thompson, GSFC, 22 October 1993.
;			Modified to speed up.
;			Incorporated into CDS library.
;
; Version     :	Version 1, 22 October 1993.
;-
;
	ON_ERROR,2
;
;  If TOP was not passed, then set it equal to the default.
;
	IF N_ELEMENTS(TOP) EQ 0 THEN TOP = 255
;
;  Test whether or not ISMIN and ISMAX were passed.
;
	ISMIN = N_ELEMENTS(MIN) GT 0
	ISMAX = N_ELEMENTS(MAX) GT 0
;
;  If neither MAX nor MIN were passed, then simply call BYTSCL to process the
;  array.
;
	IF (NOT ISMIN) AND (NOT ISMAX) THEN RETURN, BYTSCL(ARR, TOP=TOP)
;
;  If not, then get these values from the array.
;
	IF (NOT ISMIN) OR (NOT ISMAX) THEN BEGIN
		AMIN = MIN(ARR, MAX=AMAX)
		IF NOT ISMIN THEN MIN = AMIN
		IF NOT ISMAX THEN MAX = AMAX
	ENDIF
;
;  Make sure that MAX and MIN are not equal.
;
	IF MAX EQ MIN THEN MESSAGE,'MAX must not equal MIN'
;
;  Either call BYTSCL directly, or use the special code, depending on how the
;  routine was called.
;
	IF ISMIN AND ISMAX AND (MAX LT MIN) THEN RETURN, $
		BYTE( (TOP<255) * FLOAT(MIN-(MAX>ARR<MIN)) / FLOAT(MIN-MAX) ) $
		ELSE RETURN, BYTSCL(ARR, MIN=MIN, MAX=MAX, TOP=TOP)
;
	END
