;+
; Project     : SOHO - CDS
;
; Name        : 
;	SETVIEW
; Purpose     : 
;	Switch between several plots on one page.
; Explanation : 
;	SETVIEW modifies the viewport parameters !SC1, !SC2, !SC3 and !SC4 to
;	allow several plots on one page, arranged horizontally and/or 
;	vertically.
;
;	Calling SETVIEW with nontrivial parameters also sets !NOERAS to 1.
;	New plots must be started with an explicit ERASE command.
; 
;	Calling SETVIEW without any parameters, or IX,NX and IY,NY all equal
;	to 1 resets the viewport, and sets !NOERAS to 0.
;
;	Recalling SETVIEW with the same parameters as before will restore the
;	system variables associated with that setting.  This allows the user to
;	switch between several plots without losing the scaling information
;	associated with each.  Note that when switching between windows that
;	both WSET and SETVIEW must be called each time for this to work.
;	Alternatively, SETWINDOW can be used to switch between windows.
; 
; Use         : 
;	SETVIEW  [, IX, NX  [, IY, NY  [, SX  [, SY ]]]]
; Inputs      : 
;	None required.  Calling SETVIEW without any parameters resets to the
;	default behavior.
; Opt. Inputs : 
;	IX, NX	= Relative position along X axis, expressed as position IX
;		  out of a possible NX, from left to right.  If not passed,
;		  then 1,1 is assumed. 
;	IY, NY	= Relative position along Y axis, from top to bottom.  If
;		  not passed, then 1,1 is assumed. 
;	SX	= Multiplication factor for space between plots in X 
;		  direction.  A value of SX between 0 and 1 decreases the 
;		  amount of space between plots, a value greater than 1 
;		  increases the amount of space.  If not passed, then 1 is 
;		  assumed.
;	SY	= Multiplication factor for space between plots in Y 
;		  direction.  If not passed, then 1 is assumed.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	None.
; Calls       : 
;	ADD_VIEWPORT, SETSCALE, TRIM
; Common      : 
;	VIEWPORT  = Contains data to maintain information about the viewports
;		    as a function of graphics device and window.
; Restrictions: 
;	IX must be between 1 and NX.  IY must be between 1 and NY.
;
;	SX and SY must not be negative.
;
;	This routine must be called separately for each graphics device.
;
;	In general, the SERTS graphics devices routines use the special system
;	variables !BCOLOR and !ASPECT.  These system variables are defined in
;	the procedure DEVICELIB.  It is suggested that the command DEVICELIB be
;	placed in the user's IDL_STARTUP file.
;
; Side effects: 
;	The system variable !NOERAS is changed.
;
;	Any SETSCALE settings will be lost.
;
; Category    : 
;	Utilities, Devices.
; Prev. Hist. : 
;	William Thompson	Applied Research Corporation
;	September, 1988		8201 Corporate Drive
;				Landover, MD  20785
;
;	William Thompson, Nov 1992, changed common block to allow system
;				    variables to be saved between multiple
;				    plots.  Also added call to disable
;				    possible SETSCALE settings.
; Written     : 
;	William Thompson, GSFC, September 1988.
; Modified    : 
;	Version 1, William Thompson, GSFC, 27 April 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 4 January 1994.
;		Fixed bug where original state was not being completely
;		restored.
; Version     : 
;	Version 2, 4 January 1994.
;-
;
;******************************************************************************
;  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
;******************************************************************************
	PRO ADD_VIEWPORT, SETTING, SV
;
;  Called from SETVIEW.  Used to add devices to the VIEWPORT common block.
;
	ON_ERROR,1
	COMMON VIEWPORT,NAMES,SET,XMARGIN,YMARGIN,SETTINGS,SAVE,SETTING0
;
;  Check to see if the common block variables have been initialized.  Either
;  initialize the common block with this device, or add this device to the
;  common block.
;
	IF N_ELEMENTS(SETTINGS) EQ 0 THEN BEGIN
		SETTINGS = SETTING
		SAVE = SV
	END ELSE BEGIN
		SETTINGS = [SETTINGS,SETTING]
		SAVE = [SAVE,SV]
	ENDELSE
;
	RETURN
	END
;******************************************************************************
;  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
;******************************************************************************
	PRO SETVIEW,IXX,NXX,IYY,NYY,SX,SY
;
	ON_ERROR,2
	COMMON VIEWPORT,NAMES,SET,XMARGIN,YMARGIN,SETTINGS,SAVE,SETTING0
;
;  Interpret the input variables.
;
	IF N_PARAMS(0) EQ 0 THEN BEGIN
		IX = 1
		NX = 1
		IY = 1
		NY = 1
	END ELSE IF N_PARAMS(0) EQ 2 THEN BEGIN
		IX = FIX(IXX)
		NX = FIX(NXX)
		IY = 1
		NY = 1
	END ELSE IF N_PARAMS(0) GE 4 THEN BEGIN
		IX = FIX(IXX)
		NX = FIX(NXX)
		IY = FIX(IYY)
		NY = FIX(NYY)
	END ELSE BEGIN
		PRINT,'*** SETVIEW must be called with up to six parameters:'
		PRINT,'        [ IX, NX  [, IY, NY  [, SX  [, SY ]]]]'
		RETURN
	ENDELSE
	IF N_PARAMS(0) LT 5 THEN SX = 1
	IF N_PARAMS(0) LT 6 THEN SY = 1
;
;  Check the input parameters.
;
	IF NX LT 1 THEN BEGIN
		PRINT,'*** NX must be GE 1, routine SETVIEW.'
		RETURN
	END ELSE IF NY LT 1 THEN BEGIN
		PRINT,'*** NY must be GE 1, routine SETVIEW.'
		RETURN
	END ELSE IF (IX LT 1) OR (IX GT NX) THEN BEGIN
                PRINT,'*** IX must be in the range 1 to ' + TRIM(FIX(NX)) + $
                        ', routine SETVIEW.'
		RETURN
	END ELSE IF (IY LT 1) OR (IY GT NY) THEN BEGIN
                PRINT,'*** IY must be in the range 1 to ' + TRIM(FIX(NY)) + $
                        ', routine SETVIEW.'
		RETURN
	ENDIF
;
;  Disable any SETSCALE settings.
;
	SETSCALE
;
;  Check to see if the common block variables have been initialized.
;
	IF N_ELEMENTS(NAMES) EQ 0 THEN BEGIN
		NAMES	= !D.NAME
		SET	= 0.
		XMARGIN	= FLTARR(2)
		YMARGIN	= FLTARR(2)
	ENDIF
;
;  Get the number of the current plotting device.
;
	I_DEVICE = WHERE(NAMES EQ !D.NAME,N_FOUND)
	IF N_FOUND EQ 0 THEN BEGIN
		NAMES	= [NAMES, !D.NAME]
		SET	= [SET,0.]
		XMARGIN	= [[XMARGIN],[FLTARR(2)]]
		YMARGIN	= [[YMARGIN],[FLTARR(2)]]
		I_DEVICE = WHERE(NAMES EQ !D.NAME)
	ENDIF
	I_DEVICE = I_DEVICE(0)
;
;  Check to see if the screen coordinates have been stored for the currently 
;  selected device.
;
	IF SET(I_DEVICE) EQ 0 THEN BEGIN
		XMARGIN(0,I_DEVICE) = !X.MARGIN
		YMARGIN(0,I_DEVICE) = !Y.MARGIN
	ENDIF
;
;  Save the current settings into SV.
;
	SV = {SV_VIEW,	REGION: !P.REGION,		$
			CLIP: !P.CLIP,			$
			POSITION: !P.POSITION,		$
			XTYPE: !X.TYPE,			$
			XCRANGE: !X.CRANGE,		$
			XS: !X.S,			$
			XWINDOW: !X.WINDOW,		$
			XREGION: !X.REGION,		$
			YTYPE: !Y.TYPE,			$
			YCRANGE: !Y.CRANGE,		$
			YS: !Y.S,			$
			YWINDOW: !Y.WINDOW,		$
			YREGION: !Y.REGION,		$
			ZTYPE: !Z.TYPE,			$
			ZCRANGE: !Z.CRANGE,		$
			ZS: !Z.S,			$
			ZWINDOW: !Z.WINDOW,		$
			ZREGION: !Z.REGION}
;
;  Check to see if the VIEWPORT common block has been initialized.
;
	IF N_ELEMENTS(SETTING0) EQ 0 THEN SETTING0 = !D.NAME + ',' +	$
		TRIM(!D.WINDOW) + ',1,1,1,1,1,1'
	IF N_ELEMENTS(SETTINGS) EQ 0 THEN ADD_VIEWPORT,SETTING0,SV
;
;  Get the number of the current setting, and store the current parameters.
;
	I_SETTING = WHERE(SETTINGS EQ SETTING0, N_FOUND)
	IF N_FOUND EQ 0 THEN BEGIN
		ADD_VIEWPORT, SETTING0, SV
		I_SETTING = WHERE(SETTINGS EQ SETTING0)
	ENDIF
	SAVE(I_SETTING(0)) = SV
;
;  Translate XMARGIN and YMARGIN into SC1, SC2, SC3 and SC4.  This routine was
;  originally written to use these old style variables.
;
	X = XMARGIN(*,I_DEVICE) * !D.X_CH_SIZE
	SC1 = X(0)
	SC2 = !D.X_SIZE - X(1)
	Y = YMARGIN(*,I_DEVICE) * !D.Y_CH_SIZE
	SC3 = Y(0)
	SC4 = !D.Y_SIZE - Y(1)
;
;  Calculate the variables needed to set the viewport.
;
	LX = SC2 - SC1
	LY = SC4 - SC3
	DX = !D.X_SIZE - LX
	DY = !D.Y_SIZE - LY
	!SC1 = SC1
	!SC2 = SC2
	!SC3 = SC3
	!SC4 = SC4
	IF SX GE 0 THEN DX = DX * SX
	IF SY GE 0 THEN DY = DY * SY
	LX = (LX - (NX - 1)*DX) / NX
	LY = (LY - (NY - 1)*DY) / NY
	IF LX LE 0 THEN BEGIN
		PRINT,'*** Cannot fit ' + TRIM(NX) +	$
			' plots along X dimension, routine SETVIEW.'
		RETURN
	END ELSE IF LY LE 0 THEN BEGIN
		PRINT,'*** Cannot fit ' + TRIM(NY) +	$
			' plots along Y dimension, routine SETVIEW.'
		RETURN
	ENDIF
;
;  Set the viewport.
;
	IF IX EQ  1 THEN !SC1 = SC1 ELSE !SC1 = SC1 + (IX -  1) * (LX + DX)
	IF IX EQ NX THEN !SC2 = SC2 ELSE !SC2 = SC1 + (IX -  1) * (LX + DX) + LX
	IF IY EQ NY THEN !SC3 = SC3 ELSE !SC3 = SC3 + (NY - IY) * (LY + DY)
	IF IY EQ  1 THEN !SC4 = SC4 ELSE !SC4 = SC3 + (NY - IY) * (LY + DY) + LY
;
;  Set the variable !NOERAS and the switch SET, depending on whether the full
;  screen, or a part of the screen was selected.
;
	IF (NX EQ 1) AND (NY EQ 1) THEN BEGIN
		SET(I_DEVICE) = 0
		!NOERAS = 0
	END ELSE BEGIN
		SET(I_DEVICE) = 1
		!NOERAS = 1
	ENDELSE
;
;  Define the new setting.
;
	SETTING0 = !D.NAME + ',' + TRIM(!D.WINDOW) + ',' + TRIM(IX) + ',' + $
		TRIM(NX) + ',' + TRIM(IY) + ',' + TRIM(NY) + ',' + TRIM(SX) + $
		',' + TRIM(SY)
;
;  Find the saved parameters for this setting, if any
;
	I_SETTING = WHERE(SETTINGS EQ SETTING0, N_FOUND)
	IF N_FOUND NE 0 THEN BEGIN
		SV = SAVE(I_SETTING(0))
		!P.REGION = SV.REGION
		!P.CLIP   = SV.CLIP
		!P.POSITION = SV.POSITION
		!X.TYPE   = SV.XTYPE
		!X.CRANGE = SV.XCRANGE
		!X.S      = SV.XS
		!X.WINDOW = SV.XWINDOW
		!X.REGION = SV.XREGION
		!Y.TYPE   = SV.YTYPE
		!Y.CRANGE = SV.YCRANGE
		!Y.S      = SV.YS
		!Y.WINDOW = SV.YWINDOW
		!Y.REGION = SV.YREGION
		!Z.TYPE   = SV.ZTYPE
		!Z.CRANGE = SV.ZCRANGE
		!Z.S      = SV.ZS
		!Z.WINDOW = SV.ZWINDOW
		!Z.REGION = SV.ZREGION
	ENDIF
;
	RETURN
	END
