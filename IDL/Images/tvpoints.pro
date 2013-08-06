	PRO TVPOINTS,XVAL,YVAL,MX,MY,SX,SY,IX,IY,CLOSE_FLAG,DISABLE=DISABLE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	TVPOINTS
; Purpose     : 
;	Selects a series of points from a displayed image.
; Explanation : 
;	Uses the cursor to select a series of points from a displayed image.
;	Called by such routines as TVPROF, POLY_VAL, etc.  The TV cursor is
;	activated, and the user is prompted to enter in a series of points.
; Use         : 
;	TVPOINTS, XVAL, YVAL, MX, MY, IX, IY
; Inputs      : 
;	MX, MY	= Size of displayed image.
;	SX, SY	= Actual size of image.
;	IX, IY	= Position of the lower left-hand corner of the image.
; Opt. Inputs : 
;	CLOSE_FLAG = If present, then last point is connected to first to form
;		     a polygon.
; Outputs     : 
;	XVAL,YVAL = The X,Y positions of the selected path.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	DISABLE  = If set, then TVSELECT not used.
; Calls       : 
;	TVSELECT, TVUNSELECT
; Common      : 
;	None.
; Restrictions: 
;	Since this routine works interactively with the cursor, the image 
;	should be displayed on the TV screen.
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
;	The selected path is drawn on the image display screen.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	W.T.T., Oct. 1987.
;	W.T.T., Feb. 1991, modified to use TVSELECT, TVUNSELECT.
; Written     : 
;	William Thompson, GSFC, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 11 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 30 November 1993.
;		Added waits between calls to CURSOR to avoid spurious points.
; Version     : 
;	Version 2, 30 November 1993.
;-
;
;  Check the input parameters.
;
	IF N_PARAMS(0) LT 8 THEN BEGIN
		PRINT,'*** TVPOINTS must be called with 8-9 parameters:'
		PRINT,'        XVAL, YVAL, MX, MY, SX, SY, IX, IY  [, CLOSE_FLAG ]'
		RETURN
	END ELSE IF N_PARAMS(0) EQ 8 THEN CLOSE_FLAG = 0
;
;  Select the image display device or window.
;
	TVSELECT, DISABLE=DISABLE
;
	PRINT,' Mark the points defining the desired path on the image.'
	PRINT,' Hit the left mouse button to select each point.'
	PRINT,' To exit, use the middle or right button (no selection made).'
;
;  Get the first point on the curve.
;
	CURSOR,XX,YY,/DEVICE
	XFIRST = XX  &	YFIRST = YY
	XLAST  = XX  &	YLAST  = YY
	NX = MX / SX
	NY = MY / SY
	XVAL = [(XX - IX) / FLOAT(NX),0]
	YVAL = [(YY - IY) / FLOAT(NY),0]
	PRINT,'   From: (',XVAL(0),',',YVAL(0),')'
	IP = 0
;
NEXT_POINT:
	IP = IP + 1
	WAIT, 0.3
	CURSOR,XX,YY,/DEVICE
	IF !ERR EQ 1 THEN BEGIN
		PLOTS,[XLAST,XX],[YLAST,YY],/DEVICE
		XLAST = XX  &  YLAST = YY
		XVAL = [XVAL(0:IP-1),(XX - IX) / FLOAT(NX)]
		YVAL = [YVAL(0:IP-1),(YY - IY) / FLOAT(NY)]
		PRINT,'   To:   (',XVAL(IP),',',YVAL(IP),')'
		GOTO,NEXT_POINT
	END ELSE BEGIN
		IP = IP - 1
		ASK,'Do you want any more points? ',ANSWER,'YN'
		IF ANSWER EQ 'Y' THEN GOTO,NEXT_POINT
	ENDELSE
;
;  Turn off the cursor.
;
;	IF (!D.NAME EQ 'SUN') OR (!D.NAME EQ 'X') THEN TVCRS,/HIDE
;
;  If requested, close the curve.
;
	IF CLOSE_FLAG THEN PLOTS,[XLAST,XFIRST],[YLAST,YFIRST],/DEVICE
	PRINT,' Total number of points = ',IP+1
;
	TVUNSELECT, DISABLE=DISABLE
	RETURN
	END
