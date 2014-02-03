;+
; Project     : SOHO - CDS
;
; Name        : 
;	XGAMMA
; Purpose     : 
;	Widget interface to control the screen brightness.
; Explanation : 
;	A widgets-based interface to the routine GAMMA_CT,/INTENSITY to control
;	the brightness of the screen.
; Use         : 
;	XGAMMA
; Inputs      : 
;	None.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	None.
; Calls       : 
;	None.
; Common      : 
;	COLORS:  The IDL colors common block.
;	XGAMMA:  Stores the widget labels for event handling.
; Restrictions: 
;	Only useful on displays with widget support.
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
;	If the "Read from screen" button is pressed, then the color tables in
;	the COLORS common block are replaced with whatever color tables are
;	currently in use, evaluated by interrogating the screen.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, September 1992.
; Written     : 
;	William Thompson, GSFC, September 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 4 May 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 4 May 1993.
;-
;
;==============================================================================
	PRO XGAMMA_EVENT, EVENT
;
;  Routine which responses to widget events.
;
;  Common block COLORS communicates with GAMMA_CT.  Common block XGAMMA
;  communicates with routine XGAMMA.
;
	COMMON COLORS, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR
	COMMON XGAMMA, GAMMA_SLIDER, GAMMA_LABEL
;
;  Get the widget value.
;
	WIDGET_CONTROL, GET_UVALUE=VALUE, EVENT.ID
	CASE VALUE OF
;
;  If "Done", then exit the widget.
;
		'Done':  WIDGET_CONTROL, /DESTROY, EVENT.TOP
;
;  If "Read", then read the current color tables directly from the device, and
;  store them in the common block.
;
		'Read':  BEGIN
			TVLCT,R_ORIG,G_ORIG,B_ORIG,/GET
			R_CURR = R_ORIG
			G_CURR = G_ORIG
			B_CURR = B_ORIG
			GAMMA = 1.
			WIDGET_CONTROL, GAMMA_SLIDER, SET_VALUE=50
			WIDGET_CONTROL, GAMMA_LABEL, SET_VALUE=STRTRIM(GAMMA,2)
			END
;
;  If the gamma correction slide bar was moved, then change the gamma value.
;
		'Gamma':  BEGIN
			WIDGET_CONTROL, GAMMA_SLIDER, GET_VALUE=GAMMA
			GAMMA = 10^((GAMMA/50.) - 1)
			GAMMA_CT,GAMMA,/INTENSITY
			WIDGET_CONTROL, GAMMA_LABEL, SET_VALUE=STRTRIM(GAMMA,2)
			END
	ENDCASE
	END
;
;==============================================================================
	PRO XGAMMA
;
;  Routine which sets up the widgets.
;
;  Common block XGAMMA communicates with event handler routine XGAMMA_EVENT.
;
	COMMON XGAMMA, GAMMA_SLIDER, GAMMA_LABEL
;
;  Set up the widgets in a vertical column.
;
	BASE = WIDGET_BASE(TITLE='Adjust Screen Gamma',/COLUMN)
;
;  Display the current color table in a draw widget.
;
	DRAW = WIDGET_DRAW(BASE, XSIZE=256, YSIZE=50, /FRAME, RETAIN=2)
;
;  Display buttons for exiting, and for reading the color tables from the
;  screen.
;
	W1 = WIDGET_BUTTON(BASE,VALUE='Done',UVALUE='Done')
	W1 = WIDGET_BUTTON(BASE,VALUE='Read from screen',UVALUE='Read')
;
;  Associate the gamma slide bar together with a text widget storing the
;  normalized value of gamma.
;
	W1 = WIDGET_BASE(BASE,/COLUMN,/FRAME)
	GAMMA = 1.0
	GAMMA_LABEL = WIDGET_TEXT(W1,VALUE=STRTRIM(GAMMA,2))
	GAMMA_SLIDER = WIDGET_SLIDER(W1,MINIMUM=0,MAXIMUM=100,VALUE=50,	$
		/SUPPRESS_VALUE,UVALUE='Gamma',XSIZE=256,	$
		TITLE='Gamma Correction')
;
;  Now that the widgets have been defined, then draw them on the screen.
;
	WIDGET_CONTROL,BASE,/REALIZE
;
;  Now that the widgets exist on the screen, display the current color table in
;  the draw widget.
;
	WIDGET_CONTROL, GET_VALUE=INDEX, DRAW
	WINDOW = !D.WINDOW
	WSET, INDEX
	TVSCL, INDGEN(256) # REPLICATE(1,50)
	IF WINDOW NE -1 THEN WSET, WINDOW
;
;  Start the widgets manager.
;
	XMANAGER,'XGAMMA',BASE
;
	END
