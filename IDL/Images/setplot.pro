;+
; Project     : SOHO - CDS
;
; Name        : 
;	SETPLOT
; Purpose     : 
;	Switch between plotting devices with memory about each.
; Explanation : 
;	Switches among the various available plotting devices.	The plotting
;	variables for each device are saved in a common block so that the user
;	retains the ability to reset to a previously used device and do over-
;	plots, even if plots were produced on another device in the meantime.
;
;	Calling SETPLOT with the name of the currently selected device resets
;	the system variables to either default values, or those from the last
;	time SETPLOT was called.
;
;	The !BCOLOR and !ASPECT system variables are also saved.
;
; Use         : 
;	SETPLOT, DEVICE
; Inputs      : 
;	DEVICE	- Name of the plotting device one is changing to.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	COPY = If set, then the current color table is copied to the new
;	       graphics device.  Also, the SETFLAG routine is called to set TOP
;	       equal to the number of colors.  Also makes sure that !P.COLOR
;	       does not exceed the TOP color.  Requires the SERTS image display
;	       software.
; Calls       : 
;	ADD_DEVICE, SETSCALE
; Common      : 
;	PLOTFILE - Saves system variables for later retrieval.  Not to be used 
;	by other routines.
; Restrictions: 
;	The procedure will not work correctly unless it is used exclusively to 
;	change the plotting device.
;
;	In general, the SERTS graphics devices routines use the special system
;	variables !BCOLOR and !ASPECT.  These system variables are defined in
;	the procedure DEVICELIB.  It is suggested that the command DEVICELIB be
;	placed in the user's IDL_STARTUP file.
;
; Side effects: 
;	Many system variables are manipulated by this routine--in particular
;	!P.CHARSIZE and !P.FONT.
;
;	The first time the routine is called for a particular graphics device,
;	certain plot parameters may be set to default values.
;
;	Any SETSCALE settings will be lost.
;
; Category    : 
;	Utilities, Devices.
; Prev. Hist. : 
;	W.T.T., Sept. 1987.
;	William Thompson, February, 1990.
;	William Thompson, October, 1991, added !ASPECT system variable.
;	William Thompson, November 1992, changed to save !P.NOERASE and
;					 !Z.THICK.
; Written     : 
;	William Thompson, GSFC, September 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 27 April 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 14 September 1994
;		Added COPY keyword.
; Version     : 
;	Version 2, 14 September 1994
;-
;
;******************************************************************************
;  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
;******************************************************************************
	PRO ADD_DEVICE, NAME, SV
;
;  Called from SETPLOT.  Used to add devices to the PLOTFILE common block.
;  Also used to set default values for the various devices.
;
	ON_ERROR,1
	COMMON PLOTFILE,NAMES,SAVE
;
;  Define some of the defaults for various devices.
;
	SV.BCOLOR = 0
	SV.ASPECT = 1.0
	IF NAME EQ 'QMS'   THEN BEGIN
		SV.THICK     = 3
		SV.CHARTHICK = 3
		SV.XTHICK    = 3
		SV.YTHICK    = 3
		SV.ZTHICK    = 3
	ENDIF
	IF NAME EQ 'REGIS' THEN BEGIN
		SV.BCOLOR = 1
		SV.COLOR  = 3
		SV.FONT	  = 0
	ENDIF
	IF NAME EQ 'SUN'   THEN SV.BCOLOR = 50
	IF NAME EQ 'TEK'   THEN SV.FONT   = 0
	IF NAME EQ 'X'     THEN SV.BCOLOR = 50
;
;  Check to see if the common block variables have been initialized.  Either
;  initialize the common block with this device, or add this device to the
;  common block.
;
	IF N_ELEMENTS(NAMES) EQ 0 THEN BEGIN
		NAMES = NAME
		SAVE = SV
	END ELSE BEGIN
		NAMES = [NAMES,NAME]
		SAVE = [SAVE,SV]
	ENDELSE
;
	RETURN
	END
;******************************************************************************
;  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
;******************************************************************************
	PRO STORE_INTO_SV, SV
;
;  Called from SETPLOT.  Used to initialize SV, and to store the various system
;  variables in it.
;
	SV = {SV_PLT,	CHARSIZE: !P.CHARSIZE,		$
			FONT: !P.FONT,			$
			COLOR: !P.COLOR,		$
			BACKGROUND: !P.BACKGROUND,	$
			REGION: !P.REGION,		$
			CLIP: !P.CLIP,			$
			POSITION: !P.POSITION,		$
			THICK: !P.THICK,		$
			CHARTHICK: !P.CHARTHICK,	$
			NOERASE: !P.NOERASE,		$
			XTYPE: !X.TYPE,			$
			XCRANGE: !X.CRANGE,		$
			XS: !X.S,			$
			XMARGIN: !X.MARGIN,		$
			XWINDOW: !X.WINDOW,		$
			XREGION: !X.REGION,		$
			XTHICK: !X.THICK,		$
			YTYPE: !Y.TYPE,			$
			YCRANGE: !Y.CRANGE,		$
			YS: !Y.S,			$
			YMARGIN: !Y.MARGIN,		$
			YWINDOW: !Y.WINDOW,		$
			YREGION: !Y.REGION,		$
			YTHICK: !Y.THICK,		$
			ZTYPE: !Z.TYPE,			$
			ZCRANGE: !Z.CRANGE,		$
			ZS: !Z.S,			$
			ZMARGIN: !Z.MARGIN,		$
			ZWINDOW: !Z.WINDOW,		$
			ZREGION: !Z.REGION,		$
			ZTHICK: !Z.THICK,		$
			ASPECT: !ASPECT,		$
			BCOLOR: !BCOLOR}
;
	RETURN
	END
;******************************************************************************
;  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
;******************************************************************************
	PRO SETPLOT, DEVICE, COPY=COPY
;
	ON_ERROR,1
	COMMON PLOTFILE,NAMES,SAVE
;
;  Check the number of parameters.
;
	IF N_PARAMS(0) EQ 0 THEN BEGIN
		PRINT,'*** SETPLOT must be called with one parameter:'
		PRINT,'                   DEVICE'
		RETURN
	ENDIF
;
;  Disable any SETSCALE settings.
;
	SETSCALE
;
;  Define the structure.
;
	STORE_INTO_SV, SV
;
;  Check to see if the common block variables have been initialized.
;
	IF N_ELEMENTS(NAMES) EQ 0 THEN ADD_DEVICE,!D.NAME,SV
;
;  Get the number of the current plot device.
;
	I_DEVICE = WHERE(NAMES EQ !D.NAME, N_FOUND)
	IF N_FOUND EQ 0 THEN BEGIN
		ADD_DEVICE,!D.NAME,SV
		I_DEVICE = WHERE(NAMES EQ !D.NAME)
	ENDIF
	I_DEVICE = I_DEVICE(0)
;
;  If the device is being changed, then store the current system variables.
;
	IF STRUPCASE(DEVICE) NE !D.NAME THEN BEGIN
		SAVE(I_DEVICE) = SV
;
;  Get the current maximum number of colors.
;
		N_COLORS = !D.N_COLORS
;
;  Change the plotting device.
;
		SET_PLOT,DEVICE,COPY=KEYWORD_SET(COPY)
;
;  If copy was set, then set the top color to be equal to the maximum number of
;  colors.
;
		IF KEYWORD_SET(COPY) THEN BEGIN
			TOP = N_COLORS - 1
			SETFLAG,TOP=TOP
			IF !P.COLOR GT TOP THEN !P.COLOR = TOP
		ENDIF
;
;  Get the number of the new plotting device.
;
		I_DEVICE = WHERE(NAMES EQ !D.NAME,N_FOUND)
		IF N_FOUND EQ 0 THEN BEGIN
			STORE_INTO_SV, SV
			ADD_DEVICE,!D.NAME,SV
			I_DEVICE = WHERE(NAMES EQ !D.NAME)
		ENDIF
		I_DEVICE = I_DEVICE(0)
	ENDIF
;
;  Restore the system variables from the saved arrays.  This is done even if
;  the plotting device is not changed.  By using SETPLOT on the device one is
;  already set to, one can reinitialize the system variables.
;
	SV = SAVE(I_DEVICE)
	!P.CHARSIZE   = SV.CHARSIZE
	!P.FONT       = SV.FONT
	!P.COLOR      = SV.COLOR
	!P.BACKGROUND = SV.BACKGROUND
	!P.REGION     = SV.REGION
	!P.CLIP       = SV.CLIP
	!P.POSITION   = SV.POSITION
	!P.THICK      = SV.THICK
	!P.CHARTHICK  = SV.CHARTHICK
	!P.NOERASE    = SV.NOERASE
	!X.TYPE       = SV.XTYPE
	!X.CRANGE     = SV.XCRANGE
	!X.S	      = SV.XS
	!X.MARGIN     = SV.XMARGIN
	!X.WINDOW     = SV.XWINDOW
	!X.REGION     = SV.XREGION
	!X.THICK      = SV.XTHICK
	!Y.TYPE       = SV.YTYPE
	!Y.CRANGE     = SV.YCRANGE
	!Y.S	      = SV.YS
	!Y.MARGIN     = SV.YMARGIN
	!Y.WINDOW     = SV.YWINDOW
	!Y.REGION     = SV.YREGION
	!Y.THICK      = SV.YTHICK
	!Z.TYPE       = SV.ZTYPE
	!Z.CRANGE     = SV.ZCRANGE
	!Z.S	      = SV.ZS
	!Z.MARGIN     = SV.ZMARGIN
	!Z.WINDOW     = SV.ZWINDOW
	!Z.REGION     = SV.ZREGION
	!Z.THICK      = SV.ZTHICK
	!ASPECT	      = SV.ASPECT
	!BCOLOR       = SV.BCOLOR
;
	RETURN
	END
