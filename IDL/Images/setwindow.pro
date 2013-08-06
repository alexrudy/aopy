;+
; Project     : SOHO - CDS
;
; Name        : 
;	SETWINDOW
; Purpose     : 
;	Switch between windows, retaining parameters for each.
; Explanation : 
;	SETWINDOW stores the plot parameters for the current window in a common
;	block, switches to the desired window, and restores the plot parameters
;	from the last time that window was used.
; Use         : 
;	SETWINDOW  [, WINDOW ]
; Inputs      : 
;	None required.
; Opt. Inputs : 
;	WINDOW	= Number of window to switch to.  If not passed, then the
;		  parameters for the current window are saved.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	SHOW  : call WSHOW
; Calls       : 
;	ADD_WINDOW, SETSCALE, TRIM
; Common      : 
;	SETWINDOW = Contains WINDOWS, and the structure SAVE which contains the
;		    graphics system variables.
; Restrictions: 
;	WINDOW must be a valid, existing window.
;
;	Creating a new window with the WINDOW command will also switch to that
;	window.  To save the settings for the current window, call SETWINDOW
;	before calling WINDOW.
;
;	In general, the SERTS graphics devices routines use the special system
;	variables !BCOLOR and !ASPECT.  These system variables are defined in
;	the procedure DEVICELIB.  It is suggested that the command DEVICELIB be
;	placed in the user's IDL_STARTUP file.
;
; Side effects: 
;	Certain system variables from the previous time the window was used are
;	recalled.
;
;	Any SETSCALE settings will be lost.
;
; Category    : 
;	Utilities, Devices.
; Prev. Hist. : 
;	William Thompson	Applied Research Corporation
;	November, 1992		8201 Corporate Drive
;				Landover, MD  20785
; Written     : 
;	William Thompson, GSFC, November 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 27 April 1993.
;		Incorporated into CDS library.
;       Version 1.1, Dominic Zarro, (ARC/GFSC), 15 December 1994.
;               Added WSHOW
; Version     : 
;	Version 1.1, 15 December 1994.
;-
;
;******************************************************************************
;  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
;******************************************************************************
	PRO ADD_WINDOW, WINDOW, SV
;
;  Called from SETWINDOW.  Used to add devices to the SETWINDOW common block.
;  Also used to set default values for the various devices.
;
	ON_ERROR,1
	COMMON SETWINDOW,WINDOWS,SAVE
;
;  Check to see if the common block variables have been initialized.  Either
;  initialize the common block with this device, or add this device to the
;  common block.
;
	IF N_ELEMENTS(WINDOWS) EQ 0 THEN BEGIN
		WINDOWS = WINDOW
		SAVE = SV
	END ELSE BEGIN
		WINDOWS = [WINDOWS,WINDOW]
		SAVE = [SAVE,SV]
	ENDELSE
;
	RETURN
	END
;******************************************************************************
;  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
;******************************************************************************
	PRO SETWINDOW, WINDOW , SHOW=SHOW
;
	ON_ERROR,2
	COMMON SETWINDOW,WINDOWS,SAVE
;
;  Check the number of parameters.
;
	IF N_PARAMS() EQ 0 THEN WINDOW = !D.WINDOW
;
;  Check the input parameters.
;
	IF N_ELEMENTS(WINDOW) NE 1 THEN MESSAGE,'WINDOW must be a scalar'
	IF WINDOW NE LONG(WINDOW)  THEN MESSAGE,'WINDOW must be an integer'
	IF WINDOW LT 0		   THEN MESSAGE,'WINDOW must be positive'
;
;  Disable any SETSCALE settings.
;
	SETSCALE
;
;  Save the current plot parameters into SV.
;
	SV = {SV_WIN,	REGION: !P.REGION,		$
			CLIP: !P.CLIP,			$
			POSITION: !P.POSITION,		$
			NOERASE: !P.NOERASE,		$
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
;  Check to see if the SETWINDOW common block has been initialized.
;
	WINDOW0 = !D.NAME + ',' + TRIM(!D.WINDOW)
	IF N_ELEMENTS(WINDOWS) EQ 0 THEN ADD_WINDOW,WINDOW0,SV
;
;  Get the number in the database of the current window, and store the current
;  parameters.
;
	I_WINDOW = WHERE(WINDOWS EQ WINDOW0, N_FOUND)
	IF N_FOUND EQ 0 THEN BEGIN
		ADD_WINDOW, WINDOW0, SV
		I_WINDOW = WHERE(WINDOWS EQ WINDOW0)
	ENDIF
	SAVE(I_WINDOW(0)) = SV
;
;  Set the window.
;
	WSET, WINDOW
        IF KEYWORD_SET(SHOW) THEN WSHOW,WINDOW
;
;  Find the saved parameters for the new window, if any
;
	WINDOW0 = !D.NAME + ',' + TRIM(!D.WINDOW)
	I_WINDOW = WHERE(WINDOWS EQ WINDOW0, N_FOUND)
	IF N_FOUND NE 0 THEN BEGIN
		SV = SAVE(I_WINDOW(0))
		!P.REGION = SV.REGION
		!P.CLIP   = SV.CLIP
		!P.POSITION = SV.POSITION
		!P.NOERASE= SV.NOERASE
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
