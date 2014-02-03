	FUNCTION GRADIENT,ARRAY,MISSING=MISSING
;+
; Project     : SOHO - CDS
;
; Name        : 
;	GRADIENT()
; Purpose     : 
;	Calculate the absolute value of the gradient of an array.
; Explanation : 
;	The numerical derivative is calculated in the X and Y directions, and
;	then combined as the root of the sum of the squares.
; Use         : 
;	Result = GRADIENT(ARRAY)
; Inputs      : 
;	ARRAY	= Image to take gradient of.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	Result of function is the absolute value of the gradient of the array.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	MISSING	 = Value flagging missing pixels.  Any such pixels are not
;		   included in calculating the gradient.  The output value for
;		   any point with a missing pixel adjacent to it will be set to
;		   the missing pixel value.
; Calls       : 
;	GET_IM_KEYWORD
; Common      : 
;	None.
; Restrictions: 
;	The image array must be two-dimensional.
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
;	William Thompson, March 1991.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
; Written     : 
;	William Thompson, GSFC, March 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 13 May 1993.
;-
;
	GET_IM_KEYWORD, MISSING, !IMAGE.MISSING
;
;  Check the size of the image array.
;
	S = SIZE(ARRAY)
	IF S(0) NE 2 THEN BEGIN
		PRINT,'*** Variable must be two-dimensional, name= ARRAY, ' + $
			'routine GRADIENT.'
		RETURN,0
	ENDIF
	NX = S(1)
	NY = S(2)
;
;  Calculate the numerical derivatives in the center of the image array, ...
;
	DX = 0.*ARRAY  &  DY = DX
	DX(1,0) = (ARRAY(2:NX-1,*) - ARRAY(0:NX-3,*)) / 2.
	DY(0,1) = (ARRAY(*,2:NY-1) - ARRAY(*,0:NY-3)) / 2.
;
;  ... and on the edges.
;
	DX(0,0) = ARRAY(1,*) - ARRAY(0,*)
	DY(0,0) = ARRAY(*,1) - ARRAY(*,0)
	DX(NX-1,0) = ARRAY(NX-1,*) - ARRAY(NX-2,*)
	DY(0,NY-1) = ARRAY(*,NY-1) - ARRAY(*,NY-2)
;
;  Calculate the gradient as the sum of the squares.
;
	GRAD = SQRT(DX^2 + DY^2)
;
;  If the missing pixel flag is set, calculate the X and Y positions of the
;  missing pixels.
;
	IF N_ELEMENTS(MISSING) EQ 1 THEN BEGIN
		W = WHERE(ARRAY EQ MISSING, N_FOUND)
		IF N_FOUND GT 0 THEN BEGIN
			X = W MOD NX
			Y = W / NX
;
;  Set all pixels next to a missing pixel equal to the missing pixel flag
;  value.
;
			GRAD( ((X-1) > 0)      + NX*Y ) = MISSING	;Left
			GRAD( ((X+1) < (NX-1)) + NX*Y ) = MISSING	;Right
			GRAD( X + ((Y-1) > 0)     *NX ) = MISSING	;Below
			GRAD( X + ((Y+1) < (NX-1))*NX ) = MISSING	;Above
		ENDIF
	ENDIF
;
	RETURN, GRAD
	END
