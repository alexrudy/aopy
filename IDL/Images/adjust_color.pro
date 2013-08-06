	PRO ADJUST_COLOR,R,G,B,DISABLE=DISABLE,NOCURSOR=NOCURSOR
;+
; Project     : SOHO - CDS
;
; Name        : 
;	ADJUST_COLOR
; Purpose     : 
;	Adjust the color table with the cursor.
; Explanation : 
;	Use the graphics cursor to control the lower limit and range of the
;	color tables.
;
;	Cursor is repeatedly sampled.  X position is the lower limit (e.g.
;	cutoff).  Y position controls range of color table.  Initially, the
;	cutoff is set to 0 and the range is 255 with the cursor at the upper
;	left corner.  When any key is struck the lower limit and range are
;	printed and the procedure is exited.
;
; Use         : 
;	ADJUST_COLOR  [, R,G,B ]
; Inputs      : 
;	None required.
; Opt. Inputs : 
;	R = Red color gun vector, 256 elements, 0 to 255.
;		(usually read from device)
;	G = Green color gun vector.
;	B = Blue color gun vector.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	DISABLE	 = If passed, then TVSELECT is not used.
;	NOCURSOR = If passed, then TVCRS is not called.  TVCRS is not called
;		   for Tektronix terminals in any case.
; Calls       : 
;	TVSELECT, TVUNSELECT
; Common      : 
;	If the parameters are omitted, the color vectors are read using
;	TVLCT,/GET.  Regardless of the number of parameters, the colors in
;	common are not changed.
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
;	DMS, JULY, 1982. Written.
;	WTT, AUGUST, 1990.  Ported to version 2 for non-windowed devices.
;	William Thompson, April 1992, changed to use TVLCT,/GET instead of
;				      common block.
; Written     : 
;	David M. Stern, RSI, July 1982.
; Modified    : 
;	Version 1, William Thompson, GSFC, 14 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 14 May 1993.
;-
;
	ON_ERROR,2
;
;  Select the image display device/window.
;
	TVSELECT, DISABLE=DISABLE
;
;  If not passed in the command line, then read in R, G, and B.
;
	IF N_PARAMS(0) LT 3 THEN TVLCT,R,G,B,/GET
;
;  Find out whether the cursor should or should not be displayed.
;
	NO_CURSOR = KEYWORD_SET(NOCURSOR)
	IF !D.NAME EQ 'TEK' THEN NO_CURSOR = 0
;
;  Pick how big the steps will be.  Use bigger steps on Tektronix terminals.
;
	NSTEP = 1
	IF !D.NAME EQ 'TEK' THEN NSTEP = 4
;
	T = FINDGEN(!D.N_COLORS)	;Vector of subscripts
	NX = !D.X_SIZE
	NY = !D.Y_SIZE
	X0 = 0		& X = X0
	Y0 = NY - 1	& Y = Y0
	IF NOT NO_CURSOR THEN TVCRS,0,NY-1
;
	PRINT,'Left/right controls brightness, up/down controls contrast'
	PRINT,'Use shift key to move faster.'
	PRINT,'Enter:  U (up), D (down), L (left), or R (right)' +	$
		';  Return to exit'
;
;  Keep looping until the return or linefeed key is entered.
;
	KEY = ' '
	RET = STRING(13B)
	LF  = STRING(10B)
	WHILE (KEY NE RET) AND (KEY NE LF) DO BEGIN
		KEY = GET_KBRD(1)
		CASE KEY OF
;
;  Lowercase, move by NSTEP.
;
			'u':  Y = (Y + NSTEP) < (NY - 1)
			'd':  Y = (Y - NSTEP) > 0
			'r':  X = (X + NSTEP) < (NX - 1)
			'l':  X = (X - NSTEP) > 0
;
;  Uppercase, move by 10*NSTEP.
;
			'U':  Y = (Y + 10*NSTEP) < (NY - 1)
			'D':  Y = (Y - 10*NSTEP) > 0
			'R':  X = (X + 10*NSTEP) < (NX - 1)
			'L':  X = (X - 10*NSTEP) > 0
;
;  Otherwise, do nothing.
;
			ELSE:  X = X
		ENDCASE
		IF NOT NO_CURSOR THEN TVCRS,X,Y,/DEVICE
;
;  Update the color table.
;
		IF (ABS(X0-X)+ABS(Y0-Y)) GT 2 THEN BEGIN 	;Movement?
			X0 = X					;Reset
			Y0 = Y
			S = LONG( ((T-X*!D.N_COLORS/NX)>0) * (NY/(Y>5.)) )
			S = 0 > S < (!D.N_COLORS - 1)
			TVLCT,R(S),G(S),B(S)
		ENDIF
	ENDWHILE
;
;  Turn off the cursor.
;
;	IF (!D.NAME EQ 'SUN') OR (!D.NAME EQ 'X') THEN TVCRS,/HIDE
;
	PRINT,' '
	TVUNSELECT, DISABLE=DISABLE
	RETURN
	END
