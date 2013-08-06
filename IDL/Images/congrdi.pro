	FUNCTION CONGRDI,ARRAY,NXP,NYP
;+
; Project     : SOHO - CDS
;
; Name        : 
;	CONGRDI()
; Purpose     : 
;	Interpolates an array into another array.
; Explanation : 
;	This procedure interpolates an array into another array.  It emulates
;	CONGRIDI, except that the image is smoothed from edge to edge.
;	Consequently, the points will not interpolate the same way.  CONGRIDI
;	uses the formula:
;
;		I_NEW = I_OLD * N_NEW / N_OLD
;
;	where I_OLD is a point in the original array, N_OLD is the size of the
;	old array (in one of the dimensions), and N_NEW is the size of the new
;	array.  CONGRDI, on the other hand, uses the formula:
;
;		I_NEW = I_OLD * (N_NEW - 1) / (N_OLD - 1)
;
;	In this case, a point on the edge I_OLD = N_OLD-1 will transform to
;	N_NEW-1.
;
; Use         : 
;	NEW_ARRAY = CONGRDI( ARRAY, NXP, NYP )
; Inputs      : 
;	ARRAY		= The two-dimensional array to be interpolated.
;	NXP, NYP	= The dimensions of the output array.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	The function returns the interpolated array.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	None.
; Calls       : 
;	None.
; Common      : 
;	None.
; Restrictions: 
;	ARRAY must be two-dimensional, and NXP and NYP must both be > 1.
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
; Written     : 
;	William Thompson, GSFC, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 13 May 1993.
;-
;
	ON_ERROR,2
;
;  Check the number of parameters passed.
;
	IF N_PARAMS(0) NE 3 THEN BEGIN
	    PRINT,'*** CONGRDI must be called with three parameters:'
	    PRINT,'                ARRAY, NXP, NYP'
	    RETURN,ARRAY
;
;  Check the parameters NXP and NYP.
;
	END ELSE IF ((NXP LE 1) OR (NYP LE 1)) THEN BEGIN
	    PRINT,'*** The dimensions NXP,NYP must be > 1, routine CONGRDI.'
	    RETURN,ARRAY
	ENDIF
;
;  Check the parameter ARRAY.
;
	S = SIZE(ARRAY)
	IF S(0) NE 2 THEN BEGIN
	    PRINT,'*** Variable must be two-dimensional, name= ARRAY, routine CONGRDI.'
	    RETURN,ARRAY
	ENDIF
;
;  Use POLY_2D to perform the interpolation.
;
	SX = [ [ 0 , (S(1) - 1.) / (NXP - 1.) ] , [ 0 , 0 ] ]
	SY = [ [ 0 , 0 ] , [ (S(2) - 1.) / (NYP - 1.) , 0 ] ]
	RESULT = POLY_2D(FLOAT(ARRAY),SX,SY,1,NYP,NXP)
	RESULT = TRANSPOSE(RESULT)
;
	RETURN,RESULT
	END
