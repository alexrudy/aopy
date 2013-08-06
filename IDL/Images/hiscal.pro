	FUNCTION HISCAL,ARRAY,MISSING=MISSING,MAX=MAX,MIN=MIN
;+
; Project     : SOHO - CDS
;
; Name        : 
;	HISCAL()
; Purpose     : 
;	Performs histogram equalization on an array.
; Explanation : 
;	Scales an array such that the histogram of the output array is
;	approximately the same for all data values.
; Use         : 
;	Result = HISCAL(ARRAY)
; Inputs      : 
;	ARRAY	= Array to be scaled.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	The function returns the scaled array.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	MISSING	= Value flagging missing pixels.
;	MAX	 = The maximum value of IMAGE to be considered in calculating
;		   the histogram, as used by HISTOGRAM.  The default is the
;		   maximum value of IMAGE.
;	MIN	 = The minimum value of IMAGE to be considered in calculating
;		   the histogram, as used by HISTOGRAM.  The default is the
;		   minimum value of IMAGE.
; Calls       : 
;	GET_IM_KEYWORD, GOOD_PIXELS
; Common      : 
;	None.
; Restrictions: 
;	ARRAY must have some range of values.
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
;	William Thompson, November 1992, added MISSING, MAX and MIN keywords.
;		No longer scales into byte array.
; Written     : 
;	William Thompson, GSFC, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 25 May 1993.
;		Changed call to HISTOGRAM to be compatible with OpenVMS/ALPHA
; Version     : 
;	Version 2, 25 May 1993.
;-
;
	ON_ERROR,2
;
;  Get the maximum and minimum values of ARRAY.
;
	A = GOOD_PIXELS(ARRAY,MISSING=MISSING)
	AMIN = MIN(A,MAX=AMAX)
	IF N_ELEMENTS(MIN) EQ 1 THEN AMIN = MIN
	IF N_ELEMENTS(MAX) EQ 1 THEN AMAX = MAX
	IF AMIN EQ AMAX THEN RETURN, ARRAY
;
;  Form the histogram and sum up the elements to get the number of points up to
;  that level. 
;
	DELTA = (AMAX - AMIN) / 256.
	LEVEL = HISTOGRAM(LONG(((A<AMAX)-AMIN)/DELTA))
	LEVEL = [0,LEVEL]
	FOR I = 1,N_ELEMENTS(LEVEL)-1 DO LEVEL(I) = LEVEL(I) + LEVEL(I-1)
;
;  Rescale the image based on the histogram.
;
	LEVEL = 1.*(AMAX - AMIN) * LEVEL / MAX(LEVEL) + AMIN
	A = ((AMIN > ARRAY < AMAX) - AMIN) / DELTA
	A = LEVEL(A)
;
;  Set any missing pixels to the correct flag value.
;
	GET_IM_KEYWORD, MISSING, !IMAGE.MISSING
	IF N_ELEMENTS(MISSING) EQ 1 THEN BEGIN
		W = WHERE(ARRAY EQ MISSING, N_FOUND)
		IF N_FOUND GE 1 THEN A(W) = MISSING
	ENDIF
;
	RETURN, A
	END
