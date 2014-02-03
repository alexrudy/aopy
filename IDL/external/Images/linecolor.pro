	PRO LINECOLOR,I_COLOR,S_COLOR,SET=SET,DISABLE=DISABLE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	LINECOLOR
; Purpose     : 
;	Set a color index to a particular color.
; Explanation : 
;	Set one particular element in each of the red, green and blue color
;	tables to some standard values for line plotting.
; Use         : 
;	LINECOLOR,I_COLOR,S_COLOR
; Inputs      : 
;	I_COLOR = Color table element to be used for line plotting.  Must be in
;		  the range [0,!D.NCOLORS-1].  If SET is set, then the system
;		  variable !COLOR is set to I_COLOR.
;	S_COLOR = String variable denoting the color.  May be upper or lower
;		  case.  Acceptable values are 'RED', 'GREEN', 'BLUE',
;		  'YELLOW', 'ORANGE', 'PURPLE', 'MAGENTA', 'BROWN',
;		  'TURQUOISE', 'BLACK' and 'WHITE'.
;	DISABLE	= If set, then TVSELECT not used.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	SET	= If set, then !COLOR is changed by this procedure.
; Calls       : 
;	TRIM, TVSELECT, TVUNSELECT
; Common      : 
;	None.
; Restrictions: 
;	The variable S_COLOR must be of type string.
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
;	If SET is set, then the variable !COLOR is set to I_COLOR.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson	Applied Research Corporation
;	July, 1986		8201 Corporate Drive
;				Landover, MD  20785
;
;	William Thompson, April 1992, changed to use TVLCT,/GET instead of
;				      common block, and added DISABLE keyword.
; Written     : 
;	William Thompson, GSFC, July 1986.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 13 May 1993.
;-
;
	ON_ERROR,2
;
	IF N_PARAMS(0) LT 2 THEN BEGIN
		PRINT,'*** LINECOLOR must be called with 2 parameters:'
		PRINT,'               I_COLOR , S_COLOR'
		RETURN
	ENDIF
;
	TVSELECT,DISABLE=DISABLE
	MAXCOLOR = !D.N_COLORS - 1
	IF ((I_COLOR LT 0) OR (I_COLOR GT MAXCOLOR)) THEN BEGIN
		PRINT,'*** I_COLOR must be between 0 and ' +	$
			TRIM(MAXCOLOR) + ', procedure LINECOLOR.'
		TVUNSELECT,DISABLE=DISABLE
		RETURN
	ENDIF
;
	TVLCT,RED,GREEN,BLUE,/GET
;
	CASE STRUPCASE(S_COLOR) OF
		'RED':  BEGIN
			RED(I_COLOR) = 255
			GREEN(I_COLOR) = 0
			BLUE(I_COLOR) = 0
			END
		'GREEN':  BEGIN
			RED(I_COLOR) = 0
			GREEN(I_COLOR) = 255
			BLUE(I_COLOR) = 0
			END
		'BLUE':  BEGIN
			RED(I_COLOR) = 0
			GREEN(I_COLOR) = 0
			BLUE(I_COLOR) = 255
			END
		'YELLOW':  BEGIN
			RED(I_COLOR) = 255
			GREEN(I_COLOR) = 255
			BLUE(I_COLOR) = 0
			END
		'ORANGE':  BEGIN
			RED(I_COLOR) = 255
			GREEN(I_COLOR) = 127
			BLUE(I_COLOR) = 0
			END
		'PURPLE':  BEGIN
			RED(I_COLOR) = 255
			GREEN(I_COLOR) = 0
			BLUE(I_COLOR) = 255
			END
		'MAGENTA':  BEGIN
			RED(I_COLOR) = 255
			GREEN(I_COLOR) = 100
			BLUE(I_COLOR) = 150
			END
		'BROWN':  BEGIN
			RED(I_COLOR) = 200
			GREEN(I_COLOR) = 127
			BLUE(I_COLOR) = 100
			END
		'TURQUOISE':  BEGIN
			RED(I_COLOR) = 0
			GREEN(I_COLOR) = 255
			BLUE(I_COLOR) = 255
			END
		'BLACK':  BEGIN
			RED(I_COLOR) = 0
			GREEN(I_COLOR) = 0
			BLUE(I_COLOR) = 0
			END
		'WHITE':  BEGIN
			RED(I_COLOR) = 255
			GREEN(I_COLOR) = 255
			BLUE(I_COLOR) = 255
			END
		ELSE:  BEGIN
			PRINT,' Unrecognized color: ',S_COLOR
			PRINT,' Valid colors are: RED, GREEN, BLUE, YELLOW, ORANGE, PURPLE,'
			PRINT,'                   MAGENTA, BROWN, TURQUOISE, BLACK, WHITE'
			TVUNSELECT,DISABLE=DISABLE
			RETURN
			END
	ENDCASE
;
	IF KEYWORD_SET(SET) THEN !COLOR = I_COLOR
	TVLCT,RED,GREEN,BLUE
	TVUNSELECT,DISABLE=DISABLE
;
	RETURN
	END
