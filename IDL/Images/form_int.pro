	FUNCTION FORM_INT,IMAGE,MIN=IMIN,MAX=IMAX,MISSING=MISSING,LOWER=LOWER
;+
; Project     : SOHO - CDS
;
; Name        : 
;	FORM_INT()
; Purpose     : 
;	Scales an intensity image for use with split color tables.
; Explanation : 
;	Takes an intensity image, and scales it into a byte array suitable for 
;	use with the combined intensity/velocity color table created by
;	COMBINE_VEL.
;
;	Alternatively, two intensity images can be displayed with different
;	color tables merged via COMBINE_VEL, if the /LOWER switch is used for
;	one of them.
;
;	This function scales an array into the upper (or lower) half of the
;	color table.  If passed, only values of IMAGE within the range IMIN to
;	IMAX will be used to set the scaling.  Missing pixels (MISSING) are
;	scaled to zero.
; 
; Use         : 
;	B = FORM_INT(IMAGE)
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
;	The following example shows how to put one 256 by 256 intensity image I1
;	using color table #3 next to another image of the same size I2 using
;	color table #5.
; 
;	LOADCT,3			   ;Select first color table
;	COMBINE_COLORS,/LOWER		   ;Save lower color table
;	LOADCT,5			   ;Select second color table
;	COMBINE_COLORS			   ;Combine the color tables
;	TV,FORM_INT(I1,/LOWER),0,128	   ;Display first image on left
;	TV,FORM_INT(I2),128		   ;And second image on right
;
; Inputs      : 
;	IMAGE	= Intensity image to be scaled.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	This function returns the scaled image.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	MIN	   = Lower limit placed on intensity image when selecting scale.
;	MAX	   = Upper limit placed on intensity image when selecting scale.
;	MISSING	   = Value flagging missing pixels.
;	LOWER	   = If set, then the image is placed in the lower part of the
;		     color table, rather than the upper.
; Calls       : 
;	BYTSCLI, GET_IM_KEYWORD
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
;	W.T.T., Dec. 1990.  Created from FORM_VEL.
;	W.T.T., Nov. 1991.  Changed IMIN and IMAX to keywords MIN and MAX.
;			    Added support for flag variables VMIN and VMAX.
;	W.T.T., Feb. 1992.  Added LOWER keyword.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
; Written     : 
;	William Thompson, GSFC, December 1990.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 22 October 1993.
;		Modified to call BYTSCLI instead of BYTSCL.
; Version     : 
;	Version 2, 22 October 1993.
;-
;
	GET_IM_KEYWORD, MISSING, !IMAGE.MISSING
	GET_IM_KEYWORD,IMIN,!IMAGE.MIN
	GET_IM_KEYWORD,IMAX,!IMAGE.MAX
	BANG_C = !C
;
;  Scale the good values.
;
	MAXCOLOR = (!D.N_COLORS - 1) / 2
	COMMAND = 'IM = BYTSCLI(IMAGE,TOP=MAXCOLOR'
	IF N_ELEMENTS(MISSING) EQ 1 THEN BEGIN
		IF (N_ELEMENTS(IMIN) NE 1) OR (N_ELEMENTS(IMAX) NE 1) THEN $
			I1 = MIN(IMAGE(WHERE(IMAGE NE MISSING)),MAX=I2)
		IF N_ELEMENTS(IMIN) EQ 1		THEN	$
			COMMAND = COMMAND + ',MIN=IMIN'	ELSE	$
			COMMAND = COMMAND + ',MIN=I1'
		IF N_ELEMENTS(IMAX) EQ 1		THEN	$
			COMMAND = COMMAND + ',MAX=IMAX'	ELSE	$
			COMMAND = COMMAND + ',MAX=I2'
	END ELSE BEGIN
		IF N_ELEMENTS(IMIN) EQ 1 THEN COMMAND = COMMAND + ',MIN=IMIN'
		IF N_ELEMENTS(IMAX) EQ 1 THEN COMMAND = COMMAND + ',MAX=IMAX'
	ENDELSE
	TEST = EXECUTE(COMMAND + ')')
;
;  Put into the top half of the color table.
;
	IF NOT KEYWORD_SET(LOWER) THEN IM = IM + BYTE(!D.N_COLORS/2)
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
