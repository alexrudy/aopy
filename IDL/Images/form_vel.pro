	FUNCTION FORM_VEL,IMAGE,MIN=VMIN,MAX=VMAX,MISSING=MISSING,	$
		COMBINED=COMBINED
;+
; Project     : SOHO - CDS
;
; Name        : 
;	FORM_VEL()
; Purpose     : 
;	Scales a velocity image for display.
; Explanation : 
;	Takes a velocity image, and scales it into a byte array suitable for 
;	use with the velocity color table created by LOAD_VEL.
;
;	This function scales an array into the range 1 to MAXCOLOR (either
;	!D.N_COLORS-1 or (!D.N_COLORS - 1)/2, depending on the value of
;	combined), with values of zero scaling to (MAXCOLOR+1)/2.  If passed,
;	only values of IMAGE within the range MIN to MAX will be used to set
;	the scaling.  Missing pixels (MISSING) are scaled to zero.  When used
;	with LOAD_VEL, positive velocities will be shown in blue, negative
;	velocities in red (or visa-versa), velocities at or near zero will be
;	shown in grey, and missing pixels will be black.
; 
; Use         : 
;	Result = FORM_VEL(IMAGE)
;
;	The following example shows how to put a 256 by 256 intensity image I
;	next to its corresponding velocity image V.  Standard color table #3 is
;	used for the intensity image.
; 
;	LOADCT,3			   ;Select color table for intensity
;	COMBINE_VEL			   ;Combine with velocity color table
;	TV,FORM_INT(I),0,128		   ;Display intensity image on left
;	TV,FORM_VEL(V,/COMBINED),256,128   ;And velocity on right
; 
; Inputs      : 
;	IMAGE	= Velocity image to be scaled.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	This function returns the scaled image.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	MIN	   = Lower limit placed on velocity image when selecting scale.
;	MAX	   = Upper limit placed on velocity image when selecting scale.
;		     If neither MIN or MAX are passed, then the scaling is
;		     derived from the image.  If both MIN and MAX are passed,
;		     then the scale is set by the least restrictive of the two
;		     values.
;	MISSING	   = Value flagging missing pixels.
;	COMBINED   = If passed, then velocities are scaled into the bottom half
;		     of the color table, so that intensities can be displayed
;		     using the top half of the color table.
; Calls       : 
;	GET_IM_KEYWORD, IM_KEYWORD_SET
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
;	W.T.T., Oct. 1987.
;	W.T.T., Nov. 1990.  Modified for version 2 of IDL.
;	W.T.T., Dec. 1990.  Added COMBINED keyword.
;	W.T.T., Jan. 1991.  Changed FLAG to keyword BADPIXEL.
;	W.T.T., Nov. 1991.  Changed VMIN and VMAX to keywords MIN and MAX.
;			    Added support for flag variables VMIN, VMAX and
;			    COMBINED.
;	W.T.T., Jun. 1992.  Changed so that topmost color reserved for
;			    overplotting with white lines.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
; Written     : 
;	William Thompson, GSFC, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 13 May 1993.
;-
;
	GET_IM_KEYWORD, MISSING, !IMAGE.MISSING
	GET_IM_KEYWORD,VMIN,!IMAGE.VMIN
	GET_IM_KEYWORD,VMAX,!IMAGE.VMAX
	BANG_C = !C
;
;  Find the range to scale the data to.
;
	IF (N_ELEMENTS(VMIN) EQ 1) AND (N_ELEMENTS(VMAX) EQ 1) THEN BEGIN
		IMAX = ABS(VMIN) > ABS(VMAX)
	END ELSE IF N_ELEMENTS(VMIN) EQ 1 THEN BEGIN
		IMAX = ABS(VMIN)
	END ELSE IF N_ELEMENTS(VMAX) EQ 1 THEN BEGIN
		IMAX = ABS(VMAX)
	END ELSE IF N_ELEMENTS(MISSING) EQ 1 THEN BEGIN
		W = WHERE(IMAGE NE MISSING)
		IMAX = MAX(ABS(IMAGE(W)))
	END ELSE BEGIN
		IMAX = MAX(ABS(IMAGE))
	ENDELSE
;
;  Scale the good values.
;
	MAXCOLOR = !D.N_COLORS - 1
	IF IM_KEYWORD_SET(COMBINED,!IMAGE.COMBINED) THEN MAXCOLOR = MAXCOLOR/2
	MAXCOLOR = MAXCOLOR - 1
	COLORRANGE = FIX((MAXCOLOR - 1) / 2) * 1.
	ZEROCOLOR  = FIX((MAXCOLOR + 1) / 2)
	IM = BYTE( 1 > (ZEROCOLOR + IMAGE * COLORRANGE / IMAX) < MAXCOLOR )
;
;  Scale the missing values (if any).
;
	IF N_ELEMENTS(MISSING) EQ 1 THEN BEGIN
		W = WHERE(IMAGE EQ MISSING,COUNT)
		IF COUNT NE 0 THEN IM(W) = 0B
	ENDIF
;
	!C = BANG_C
	RETURN,IM
	END
