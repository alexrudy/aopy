	PRO SELECT_BOX,MX,MY,IX,IY,DATA=DATA,INIT=INIT,FIXED_SIZE=FIXED_SIZE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	SELECT_BOX
; Purpose     : 
;	Interactive selection of a box on the graphics display.
; Explanation : 
;	If the graphics device is windows based, then BOX_CURSOR is used.
;	Otherwise, the user is prompted to enter two corners of the box.
;
;	Note that the parameter list for SELECT_BOX is in a different order
;	than BOX_CURSOR.  However, it was decided to order the parameters this
;	way to be compatible with the SERTS image display routines.
;
; Use         : 
;	SELECT_BOX, MX, MY, IX, IY
; Inputs      : 
;	None.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	MX, MY	= Size of selected box, in device coordinates.
;	IX, IY	= Coordinates of lower left-hand corner of selected box.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	DATA	= If this keyword is set, then the values are in returned in
;		  data coordinates instead of device coordinates.
;
;	The following keywords are only relevant when used on a graphics device
;	that supports windows:
;
;	INIT	   = If this keyword is set, MX, MY, and IX, IY contain the
;		     initial parameters for the box.
;
;	FIXED_SIZE = If this keyword is set, MX and MY contain the initial size
;		     of the box.  This size may not be changed by the user.
;
; Calls       : 
;	BOX_CURSOR, BOX_CRS
; Common      : 
;	None.
; Restrictions: 
;	None.
; Side effects: 
;	None.
; Category    : 
;	Utilities, User_interface.
; Prev. Hist. : 
;	William Thompson, May 1992.
;	William Thompson, Nov 1992, added DATA keyword.
; Written     : 
;	William Thompson, GSFC, May 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 30 April 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 25 June 1993.
;		Changed to call BOX_CRS for MSWindows, BOX_CURSOR otherwise.
;		Added INIT and FIXED_SIZE keywords.
; Version     : 
;	Version 2, 25 June 1993.
;-
;
	ON_ERROR,2
;
;  Check the number of parameters.
;
	IF N_PARAMS() NE 4 THEN MESSAGE,'Syntax:  SELECT_BOX, MX, MY, IX, IY'
;
;  If the graphics device is windows based, e.g. X or SUN, then use BOX_CURSOR,
;  or BOX_CRS on Microsoft Windows.
;
	IF HAVE_WINDOWS() THEN BEGIN
;
;  If either the INIT or FIXED_SIZE keywords are set, and the DATA keyword is
;  also set, then convert to device coordinates.
;
		IF (KEYWORD_SET(INIT) OR KEYWORD_SET(FIXED_SIZE)) AND	$
				KEYWORD_SET(DATA) THEN BEGIN
			SAVE_MX = ABS(MX)
			SAVE_MY = ABS(MY)
			X = [IX, IX + MX]
			Y = [IY, IY + MY]
			RESULT = CONVERT_COORD(X,Y,/DATA,/TO_DEVICE)
			IX = MIN(RESULT(0,*))
			IY = MIN(RESULT(1,*))
			MX = ABS(RESULT(0,1)-RESULT(0,0))
			MY = ABS(RESULT(1,1)-RESULT(1,0))
		ENDIF
;
		IF !D.NAME EQ 'WIN' THEN BEGIN
			BOX_CRS,IX,IY,MX,MY,/MESSAGE,INIT=INIT,	$
				FIXED_SIZE=FIXED_SIZE
		END ELSE BEGIN
			IF KEYWORD_SET(FIXED_SIZE) THEN BEGIN
				PRINT,'Left button to move box, ' +	$
					'and right to select.'
			END ELSE BEGIN
				PRINT,'Left button to move box, ' +	$
					'middle to resize, ' + $
					'and right to select.'
			ENDELSE
			BOX_CURSOR,IX,IY,MX,MY,INIT=INIT,FIXED_SIZE=FIXED_SIZE
		ENDELSE
;
		IF MX LT 0 THEN BEGIN
			IX = IX + MX
			MX = -MX
		ENDIF
		IF MY LT 0 THEN BEGIN
			IY = IY + MY
			MY = -MY
		ENDIF
;
;  Otherwise, select the corners with the cursor.  A carriage return is
;  required between the two corners to avoid problems with double clicks.
;
	END ELSE BEGIN
		PRINT,'Select the first corner of the desired box'
		CURSOR, I1, J1, /DEVICE
		ANSWER = 'String'
		READ,'Press return, and then select the other corner',ANSWER
		CURSOR, I2, J2, /DEVICE
		IX = I1 < I2
		IY = J1 < J2
		MX = ABS(I2 - I1)
		MY = ABS(J2 - J1)
	ENDELSE
;
;  If desired, convert the parameters to data coordinates.
;
	IF KEYWORD_SET(DATA) THEN BEGIN
		X = [IX, IX + MX]
		Y = [IY, IY + MY]
		RESULT = CONVERT_COORD(X,Y,/DEVICE,/TO_DATA)
		IX = MIN(RESULT(0,*))  &  MX = ABS(RESULT(0,1)-RESULT(0,0))
		IY = MIN(RESULT(1,*))  &  MY = ABS(RESULT(1,1)-RESULT(1,0))
		IF KEYWORD_SET(FIXED_SIZE) THEN BEGIN
			MX = SAVE_MX
			MY = SAVE_MY
		ENDIF
	ENDIF
;
	RETURN
	END
