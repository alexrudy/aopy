;+
; Project     : SOHO - CDS
;
; Name        : 
;	XLOAD
; Purpose     : 
;	Widget control of color tables, with SERTS enhancements.
; Explanation : 
;	Provides a graphical interface to allow the user to load one of the
;	standard color tables, or the special SERTS velocity color table, and
;	to interactively adjust these color tables in various ways.  The user
;	can also split the color tables into two parts: an upper and a lower
;	section, load different color tables into these two parts, and adjust
;	them separately.
; Use         : 
;	XLOAD
; Inputs      : 
;	None.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	GROUP	= The widget ID of the widget that calls XLOAD.  When this ID
;		  is specified, a death of the caller results in a death of
;		  XLOAD.
;	SILENT	= Normally, no informational message is printed when a color
;		  map is loaded.  If this keyword is present and zero, this
;		  message is printed.
;	TWO	= If set, then XLOAD goes directly to a split color display.
; Calls       : 
;	BSCALE, COMBINE_COLORS, COMBINE_VEL, INT_STRETCH, LOAD_VEL, VEL_STRETCH
; Common      : 
;	Uses the standard IDL common block COLORS (as used by LOADCT, etc.), as
;	well as COMBINE_COL from COMBINE_COLORS, and it's own XLOAD common
;	block.
; Restrictions: 
;	The graphics device must support widgets.  Requires the file
;	"colors.tbl" from distributions of IDL before v3.0.0 to be present in
;	the main IDL directory.
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
;	The variables in the COLORS and COMBINE_COL common blocks are modified.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	William Thompson, Oct 1992, from XLOADCT by Ali Bahrami and Mark
;		Rivers.
;	William Thompson, Nov 1992, added "Recenter Gamma Slider" option.
;	William Thompson, Mar 1993, fixed bug with "Velocity Options" pull-down
;		menu button in Motif.
;
;  The original XLOADCT file contained the following statement:
;
;	Copyright (c) 1991, Research Systems, Inc.  All rights reserved.
;		Unauthorized reproduction prohibited.
;
; Written     : 
;	William Thompson, GSFC, October 1992.
; Modified    : 
;	Version 1, William Thompson, GSFC, 4 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 29 October 1993.
;		Added keyword TWO.
; Version     : 
;	Version 2, 29 October 1993.
;-
;
;******************************************************************************
;  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
;******************************************************************************
	PRO XLOAD_TWO_EVENT, EVENT
;
;  Event handler for the XLOAD_TWO widget routine.
;
	COMMON COLORS, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR
	COMMON XLOAD, LEFT, RIGHT, VEL, R0, G0, B0, R1, G1, B1
	COMMON COMBINE_COL,LOWER_SET,LOWER_RED,LOWER_GREEN,LOWER_BLUE,	$
			   UPPER_SET,UPPER_RED,UPPER_GREEN,UPPER_BLUE
;
;  Get the widget event.
;
	WIDGET_CONTROL, EVENT.ID, GET_UVALUE = EVENTVAL
;
;  Get the current values of the stretch parameters.
;
	ABSTOP = !D.TABLE_SIZE -1
	WIDGET_CONTROL, LEFT.TOP,   GET_VALUE = THELTOP
	WIDGET_CONTROL, LEFT.BOT,   GET_VALUE = THELBOT
	WIDGET_CONTROL, LEFT.GAMMA, GET_VALUE = LGAMMA
	LGAMMA = 10^((LGAMMA/50.) - 1)
	WIDGET_CONTROL, RIGHT.TOP,   GET_VALUE = THERTOP
	WIDGET_CONTROL, RIGHT.BOT,   GET_VALUE = THERBOT
	WIDGET_CONTROL, RIGHT.GAMMA, GET_VALUE = RGAMMA
	RGAMMA = 10^((RGAMMA/50.) - 1)
;
;  Process the event.  If the top slider was moved, then change the top value,
;  and stretch the color table accordingly.  If the top and bottom sliders are
;  locked together, then also move the bottom slider.
;
	CASE EVENTVAL OF
		"LTOP":	BEGIN
			IF LEFT.LOCK NE 0 THEN BEGIN
				THELBOT = (THELTOP - LEFT.LOCK) > 0 < 100
				WIDGET_CONTROL, LEFT.BOT, SET_VALUE=THELBOT
			ENDIF
			GOTO, DO_STRETCH
			END
		"RTOP":	BEGIN
			IF RIGHT.LOCK NE 0 THEN BEGIN
				THERBOT = (THERTOP - RIGHT.LOCK) > 0 < 100
				WIDGET_CONTROL, RIGHT.BOT, SET_VALUE=THERBOT
			ENDIF
			GOTO, DO_STRETCH
			END
;
;  If the bottom slider was moved, then change the bottom value, and stretch
;  the color table accordingly.  If the top and bottom sliders are locked
;  together, then also move the top slider.
;
		"LBOTTOM": BEGIN
			IF LEFT.LOCK NE 0 THEN BEGIN
				THELTOP = (THELBOT + LEFT.LOCK) > 0 < 100
				WIDGET_CONTROL, LEFT.TOP, SET_VALUE=THELTOP
			ENDIF
			GOTO, DO_STRETCH
			END
		"RBOTTOM": BEGIN
			IF RIGHT.LOCK NE 0 THEN BEGIN
				THERTOP = (THERBOT + RIGHT.LOCK) > 0 < 100
				WIDGET_CONTROL, RIGHT.TOP, SET_VALUE=THERTOP
			ENDIF
			GOTO, DO_STRETCH
			END
;
;  The gamma slider was moved.
;
		"LGAMMA": BEGIN
			WIDGET_CONTROL, LEFT.GAMMA, GET_VALUE = LGAMMA
			LGAMMA = 10^((LGAMMA/50.) - 1)
			WIDGET_CONTROL, LEFT.G_LBL, SET_VALUE = STRING(LGAMMA)
			GOTO, DO_STRETCH
			END
		"RGAMMA": BEGIN
			WIDGET_CONTROL, RIGHT.GAMMA, GET_VALUE = RGAMMA
			RGAMMA = 10^((RGAMMA/50.) - 1)
			WIDGET_CONTROL, RIGHT.G_LBL, SET_VALUE = STRING(RGAMMA)
			GOTO, DO_STRETCH
			END
;
;  The recenter gamma slider option was selected.
;
		"LCENTERGAMMA": BEGIN
			WIDGET_CONTROL, LEFT.GAMMA, SET_VALUE = 50
			LGAMMA = 1.0
			WIDGET_CONTROL, LEFT.G_LBL, SET_VALUE = STRING(LGAMMA)
			GOTO, DO_STRETCH
			END
		"RCENTERGAMMA": BEGIN
			WIDGET_CONTROL, RIGHT.GAMMA, SET_VALUE = 50
			RGAMMA = 1.0
			WIDGET_CONTROL, RIGHT.G_LBL, SET_VALUE = STRING(RGAMMA)
			GOTO, DO_STRETCH
			END
;
;  The top and bottom sliders were either locked together, or unlocked.
;  Desensitize the option selected, and sensitize the inverse option.
;
		"LLOCK": BEGIN
			IF LEFT.LOCK EQ 0 THEN $
				LEFT.LOCK = THELTOP - THELBOT $
				ELSE LEFT.LOCK = 0
			FOR I=0,1 DO WIDGET_CONTROL, LEFT.LOCK_BUTTON(I), $
				SENSITIVE = I EQ (LEFT.LOCK NE 0)
			END
		"RLOCK": BEGIN
			IF RIGHT.LOCK EQ 0 THEN $
				RIGHT.LOCK = THERTOP - THERBOT $
				ELSE RIGHT.LOCK = 0
			FOR I=0,1 DO WIDGET_CONTROL, RIGHT.LOCK_BUTTON(I), $
				SENSITIVE = I EQ (RIGHT.LOCK NE 0)
			END
;
;  Chopping was either turned on or off.  Desensitize the option selected, and
;  sensitize the inverse option.
;
		"LCHOP": BEGIN
			LEFT.CHOP = 1-LEFT.CHOP
			FOR I=0,1 DO WIDGET_CONTROL, LEFT.CHOP_BUTTON(I), $
				SENSITIVE = LEFT.CHOP EQ I
			GOTO, DO_STRETCH		;Redraw
			END
		"RCHOP": BEGIN
			RIGHT.CHOP = 1-RIGHT.CHOP
			FOR I=0,1 DO WIDGET_CONTROL, RIGHT.CHOP_BUTTON(I), $
				SENSITIVE = RIGHT.CHOP EQ I
			GOTO, DO_STRETCH		;Redraw
			END
;
;  The gamma type was changed.
;
		"GAMMATYPE": BEGIN
			WIDGET_CONTROL, RIGHT.GAMMA, SENSITIVE = LEFT.GAMMATYPE
			LEFT.GAMMATYPE = 1-LEFT.GAMMATYPE
			FOR I=0,1 DO WIDGET_CONTROL, LEFT.GAMMA_BUTTON(I), $
				SENSITIVE = LEFT.GAMMATYPE EQ I
			GOTO, DO_STRETCH
			END
;
;  Display a help message.
;
		"HELP":	BEGIN
			SERTS_HELP = GETENV("SERTS_HELP")
			IF SERTS_HELP EQ "" THEN BEGIN
				FILE = FILEPATH("xloadct.txt",SUBDIR='help')
			END ELSE FILE = SERTS_HELP + "xload.txt"
			XDISPLAYFILE, FILE, TITLE = "XLOAD Help", $
				GROUP = EVENT.TOP, $
				WIDTH = 55, $
				HEIGHT = 16
			END
;
;  Reverse the table.
;
		"LREVERSE": BEGIN
			UPPER_RED   = REVERSE(UPPER_RED)
			UPPER_GREEN = REVERSE(UPPER_GREEN)
			UPPER_BLUE  = REVERSE(UPPER_BLUE)
			GOTO, DO_STRETCH		;And redraw
			END
		"RREVERSE": BEGIN
			IF RIGHT.VEL THEN BEGIN
				RIGHT.VEL = -RIGHT.VEL
				COMBINE_VEL, LIGHTEN   = (VEL.VALUE EQ 1), $
					     GREEN     = (VEL.VALUE EQ 2), $
					     TURQUOISE = (VEL.VALUE EQ 3), $
					     REVERSE=(RIGHT.VEL EQ -1),	   $
					     /PRELOADED
			END ELSE BEGIN
				LOWER_RED   = REVERSE(LOWER_RED)
				LOWER_GREEN = REVERSE(LOWER_GREEN)
				LOWER_BLUE  = REVERSE(LOWER_BLUE)
			ENDELSE
			GOTO, DO_STRETCH		;And redraw
			END
;
;  Quit from the widget program.
;
		"DONE": BEGIN
			WIDGET_CONTROL, EVENT.TOP, /DESTROY
			R0 = 0 & G0 = 0 & B0 = 0	;Free the common block
			R1 = 0 & G1 = 0 & B1 = 0
			END
;
;  Rejoin the color tables.
;
		"REJOIN": BEGIN
			WIDGET_CONTROL, EVENT.TOP, /DESTROY
			IF LEFT.GROUP NE 0 THEN GROUP = LEFT.GROUP
			XLOAD, SILENT=LEFT.SILENT, GROUP=GROUP, /NOLOAD
			END
;
;  Select the color for the positive part of the velocity color table.
;
		"BLUE":	BEGIN
			VEL.VALUE = 0
			GOTO, SET_COLOR
			END
		"LIGHTBLUE": BEGIN
			VEL.VALUE = 1
			GOTO, SET_COLOR
			END
		"GREEN": BEGIN
			VEL.VALUE = 2
			GOTO, SET_COLOR
			END
		"TURQUOISE": BEGIN
			VEL.VALUE = 3
SET_COLOR:
			FOR I = 0,3 DO WIDGET_CONTROL, VEL.COLOR(I),	$
				SENSITIVE = I NE VEL.VALUE
			GOTO, LOAD_VELOCITY
			END
;
;  Load the velocity color table.
;
		"VELOCITY": BEGIN
LOAD_VELOCITY:
			COMBINE_VEL, LIGHTEN   = (VEL.VALUE EQ 1),	$
				     GREEN     = (VEL.VALUE EQ 2),	$
				     TURQUOISE = (VEL.VALUE EQ 3),	$
				     /PRELOADED
			RIGHT.VEL = 1
			GOTO, SET_VELOCITY
			END
;
;  Define the current table as being either a velocity or intensity color
;  table.
;
		"SETVEL": BEGIN
			RIGHT.VEL = 1 - RIGHT.VEL
SET_VELOCITY:
			WIDGET_CONTROL, RIGHT.BOT, SENSITIVE = (1 - RIGHT.VEL)
			WIDGET_CONTROL, VEL.OPTIONS, SENSITIVE=RIGHT.VEL
			FOR I=0,1 DO WIDGET_CONTROL, RIGHT.SETV_BUTTON(I), $
				SENSITIVE = RIGHT.VEL EQ I
			GOTO, DO_STRETCH
			END
;
;  Load one of the standard color tables.
;
		ELSE: BEGIN
			C = STRMID(EVENTVAL,0,1)
			I = FIX(STRMID(EVENTVAL,1,STRLEN(EVENTVAL)-1))
			LOADCT, SILENT=LEFT.SILENT, I
			IF C EQ 'L' THEN BEGIN
				COMBINE_COLORS,/UPPER
			END ELSE BEGIN
				COMBINE_COLORS,/LOWER
				IF RIGHT.VEL NE 0 THEN BEGIN
					RIGHT.VEL = 0
					GOTO, SET_VELOCITY
				ENDIF
			ENDELSE
;
;  Transfer point for restretching the color table.  First, decide which kind
;  of gamma correction to apply:  color table shift (default) or intensity
;  shift.
;
DO_STRETCH:
			IF LEFT.GAMMATYPE THEN BEGIN
				IGAMMA = LGAMMA
				LGAMMA = 1
				RGAMMA = 1
			END ELSE IGAMMA = 1
;
;  Stretch the tables.
;
			INT_STRETCH, THELBOT*ABSTOP/100, THELTOP*ABSTOP/100, $
				LGAMMA, CHOP = LEFT.CHOP
			IF RIGHT.VEL NE 0 THEN BEGIN
				VEL_STRETCH, THERTOP/100., RGAMMA, /COMBINED
			END ELSE BEGIN
				INT_STRETCH, THERBOT*ABSTOP/100,	$
					THERTOP*ABSTOP/100, RGAMMA,	$
					CHOP = RIGHT.CHOP, /LOWER
			ENDELSE
;
;  if requested, apply the gamma correction to the intensities.
;
			IF IGAMMA NE 1 THEN	$
				GAMMA_CT, IGAMMA, /CURRENT, /INTENSITY
			END
	ENDCASE
;
	END
;******************************************************************************
;  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
;******************************************************************************
	PRO XLOAD_TWO, SILENT=SILENT, GROUP=GROUP, NOLOAD=NOLOAD
;
	COMMON COLORS, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR
	COMMON XLOAD, LEFT, RIGHT, VEL, R0, G0, B0, R1, G1, B1
	COMMON COMBINE_COL,LOWER_SET,LOWER_RED,LOWER_GREEN,LOWER_BLUE,	$
			   UPPER_SET,UPPER_RED,UPPER_GREEN,UPPER_BLUE
;
;  If a copy of XLOAD_TWO is already running, then exit.
;
	IF (XREGISTERED("xload_two") NE 0) THEN GOTO, EXIT_POINT
;
;  Initialize the common block.
;
	LEFT = {XLOAD,	VEL: 0,			$
			TOP: 0L,		$
			BOT: 0L,		$
			GAMMA: 0L,		$
			G_LBL: 0L,		$
			LOCK: 0,		$
			CHOP: 0,		$
			GAMMATYPE: 0,		$
			LOCK_BUTTON:  [0L,0L],	$
			CHOP_BUTTON:  [0L,0L],	$
			GAMMA_BUTTON: [0L,0L],	$
			SETV_BUTTON:  [0L,0L],	$
			SILENT: 0,		$
			GROUP: 0}
	RIGHT = LEFT
	VEL = {XLOAD_VEL, OPTIONS: 0L, VALUE: 0, COLOR: [0L, 0L, 0L, 0L]}
;
;  Save the value of the GROUP keyword in the common block.
;
	IF N_ELEMENTS(GROUP) NE 0 THEN LEFT.GROUP = GROUP
;
;  Parse whether the routine should print informational messages when a new
;  color table is loaded.
;
	IF (N_ELEMENTS(SILENT) EQ 1) THEN LEFT.SILENT = SILENT ELSE	$
		LEFT.SILENT = 1
;
;  Open the file containing the standard color tables, and define an associated
;  variable for reading the color table names.
;
	OPENR,LUN, FILEPATH('colors.tbl'), /BLOCK,/GET_LUN
	AA=ASSOC(LUN, BYTARR(32))	;Get name
;
;  Define some defaults.
;
	W_HEIGHT = 50			;Height of ramp
	CUR_WIN = !D.WINDOW
;
;  Define the widget base.
;
	BASE = WIDGET_BASE(TITLE="Xload", /ROW)
;
;  Define the left widget base.
;
	LBASE = WIDGET_BASE(BASE, /COLUMN, /FRAME)
;
;  Define the individual widget components.  Start with the graphics window for
;  displaying the color table, the "DONE" and "HELP" buttons.
;
	JUNK = WIDGET_LABEL(LBASE, VALUE = "Upper Table")
	LSHOW = WIDGET_DRAW(LBASE, YSIZE=W_HEIGHT, XSIZE=256, /FRAME, RETAIN=2)
	JUNK = WIDGET_BASE(LBASE, /ROW)
	DONE = WIDGET_BUTTON(JUNK, VALUE=' Done ', UVALUE = "DONE")
	JUNK1 = WIDGET_BUTTON(JUNK, VALUE=' Help ', UVALUE = "HELP")
;
;  Define the options.
;
	JUNK1 = WIDGET_BUTTON(JUNK, VALUE=' Options ', /MENU)
	LEFT.LOCK_BUTTON(0) = WIDGET_BUTTON(JUNK1, VALUE='Lock Sliders', $
		UVALUE="LLOCK")
	LEFT.LOCK_BUTTON(1) = WIDGET_BUTTON(JUNK1, VALUE='Unlock Sliders', $
		UVALUE="LLOCK")
	LEFT.CHOP_BUTTON(0) = WIDGET_BUTTON(JUNK1, VALUE='Chop Top',	$
		UVALUE="LCHOP")
	LEFT.CHOP_BUTTON(1) = WIDGET_BUTTON(JUNK1, VALUE='Clip Top',	$
		UVALUE="LCHOP")
	LEFT.GAMMA_BUTTON(0) = WIDGET_BUTTON(JUNK1, VALUE='Gamma Intensity', $
		UVALUE="GAMMATYPE")
	LEFT.GAMMA_BUTTON(1) = WIDGET_BUTTON(JUNK1, VALUE='Gamma Shift', $
		UVALUE="GAMMATYPE")
	JUNK = WIDGET_BUTTON(JUNK1, VALUE='Recenter Gamma Slider',	$
		UVALUE="LCENTERGAMMA")
	JUNK = WIDGET_BUTTON(JUNK1, VALUE='Reverse Table', UVALUE="LREVERSE")
;
;  Desensitize the inverse buttons for lock, etc.
;
	WIDGET_CONTROL, LEFT.CHOP_BUTTON(1),  SENSITIVE = 0
	WIDGET_CONTROL, LEFT.LOCK_BUTTON(1),  SENSITIVE = 0
	WIDGET_CONTROL, LEFT.GAMMA_BUTTON(1), SENSITIVE = 0
;
;  Define the top, bottom, and gamma sliders.
;
	SBASE=WIDGET_BASE(LBASE, /COLUMN)
	LEFT.BOT = WIDGET_SLIDER(SBASE, TITLE = "Stretch Bottom", MINIMUM=0, $
		MAXIMUM = 100, VALUE = 0, /DRAG, UVALUE = "LBOTTOM", XSIZE=256)
	LEFT.TOP = WIDGET_SLIDER(SBASE, TITLE = "Stretch Top", MINIMUM = 0, $
		MAXIMUM = 100, VALUE = 100, /DRAG, UVALUE = "LTOP", XSIZE=256)
	LEFT.G_LBL = WIDGET_LABEL(SBASE, VALUE = STRING(1.0))
	LEFT.GAMMA = WIDGET_SLIDER(SBASE, TITLE = "Gamma Correction", $
		MINIMUM = 0, MAXIMUM = 100, VALUE = 50, UVALUE = "LGAMMA", $
		/SUPPRESS_VALUE, XSIZE=256)
;
;  Define the buttons for the standard color tables.
;
	ROWCOL = WIDGET_BASE(LBASE, /FRAME, /EXCLUSIVE ,/COLUMN, XSIZE=256)
	FOR I = 0, 15 DO JUNK = WIDGET_BUTTON(ROWCOL, VALUE=STRING(AA(I)), $
		UVALUE = 'L'+STRTRIM(I,2), /NO_RELEASE)
;
;  Define the button for rejoining the color table into one.
;
	JUNK = WIDGET_BUTTON(LBASE, VALUE='Rejoin Color Table',UVALUE='REJOIN')
;
;  Define the right widget base.
;
	RBASE = WIDGET_BASE(BASE, /COLUMN, /FRAME)
;
;  Define the individual widget components.  Start with the graphics window for
;  displaying the color table.
;
	JUNK = WIDGET_LABEL(RBASE, VALUE = "Lower Table")
	RSHOW = WIDGET_DRAW(RBASE, YSIZE=W_HEIGHT, XSIZE=256, /FRAME, RETAIN=2)
	JUNK = WIDGET_BASE(RBASE, /ROW)
;
;  Define the options.
;
	JUNK1 = WIDGET_BUTTON(JUNK, VALUE=' Options ', /MENU)
	RIGHT.LOCK_BUTTON(0) = WIDGET_BUTTON(JUNK1, VALUE='Lock Sliders', $
		UVALUE="RLOCK")
	RIGHT.LOCK_BUTTON(1) = WIDGET_BUTTON(JUNK1, VALUE='Unlock Sliders', $
		UVALUE="RLOCK")
	RIGHT.CHOP_BUTTON(0) = WIDGET_BUTTON(JUNK1, VALUE='Chop Top',	$
		UVALUE="RCHOP")
	RIGHT.CHOP_BUTTON(1) = WIDGET_BUTTON(JUNK1, VALUE='Clip Top',	$
		UVALUE="RCHOP")
	JUNK2 = WIDGET_BUTTON(JUNK1, VALUE='Recenter Gamma Slider',	$
		UVALUE="RCENTERGAMMA")
	RIGHT.SETV_BUTTON(0) = WIDGET_BUTTON(JUNK1, VALUE='Set Velocity', $
		UVALUE="SETVEL")
	RIGHT.SETV_BUTTON(1) = WIDGET_BUTTON(JUNK1, VALUE='Unset Velocity', $
		UVALUE="SETVEL")
	JUNK2 = WIDGET_BUTTON(JUNK1, VALUE='Reverse Table', UVALUE="RREVERSE")
;
;  Desensitize the inverse buttons for lock, etc.
;
	WIDGET_CONTROL, RIGHT.CHOP_BUTTON(1), SENSITIVE = 0
	WIDGET_CONTROL, RIGHT.LOCK_BUTTON(1), SENSITIVE = 0
	WIDGET_CONTROL, RIGHT.SETV_BUTTON(1), SENSITIVE = 0
;
;  Define the velocity options.
;
	VEL.OPTIONS = WIDGET_BUTTON(JUNK, VALUE=' Velocity Options ', /MENU)
	VEL.COLOR(0) = WIDGET_BUTTON(VEL.OPTIONS, VALUE='Blue', UVALUE="BLUE")
	VEL.COLOR(1) = WIDGET_BUTTON(VEL.OPTIONS, VALUE='Light Blue',	$
		UVALUE="LIGHTBLUE")
	VEL.COLOR(2) = WIDGET_BUTTON(VEL.OPTIONS, VALUE='Green',	$
		UVALUE="GREEN")
	VEL.COLOR(3) = WIDGET_BUTTON(VEL.OPTIONS, VALUE='Turquoise',	$
		UVALUE="TURQUOISE")
;
;  Desensitize the velocity options, and the blue color button.
;
	WIDGET_CONTROL, VEL.OPTIONS,  SENSITIVE = 0
	WIDGET_CONTROL, VEL.COLOR(0), SENSITIVE = 0
;
;  Define the top, bottom, and gamma sliders.
;
	SBASE=WIDGET_BASE(RBASE, /COLUMN)
	RIGHT.BOT = WIDGET_SLIDER(SBASE, TITLE = "Stretch Bottom", MINIMUM=0, $
		MAXIMUM = 100, VALUE = 0, /DRAG, UVALUE = "RBOTTOM", XSIZE=256)
	RIGHT.TOP = WIDGET_SLIDER(SBASE, TITLE = "Stretch Top", MINIMUM = 0, $
		MAXIMUM = 100, VALUE = 100, /DRAG, UVALUE = "RTOP", XSIZE=256)
	RIGHT.G_LBL = WIDGET_LABEL(SBASE, VALUE = STRING(1.0))
	RIGHT.GAMMA = WIDGET_SLIDER(SBASE, TITLE = "Gamma Correction", $
		MINIMUM = 0, MAXIMUM = 100, VALUE = 50, UVALUE = "RGAMMA", $
		/SUPPRESS_VALUE, XSIZE=256)
;
;  Define the buttons for the standard color tables, and close the color table
;  file.
;
	ROWCOL = WIDGET_BASE(RBASE, /FRAME, /EXCLUSIVE ,/COLUMN, XSIZE=256)
	FOR I = 0, 15 DO JUNK = WIDGET_BUTTON(ROWCOL, VALUE=STRING(AA(I)), $
		UVALUE = 'R' + STRTRIM(I,2), /NO_RELEASE)
	FREE_LUN, LUN
;
;  Define the button for loading the velocity table.
;
	JUNK = WIDGET_BUTTON(RBASE, VALUE='Load Velocity Table',	$
		UVALUE="VELOCITY")
;
;  Realize the widget.
;
	WIDGET_CONTROL, BASE, /REALIZE
;
;  If no combined color table has yet been loaded, then load the current in
;  either or both the upper and lower parts of the color table.
;
	IF NOT KEYWORD_SET(LOWER_SET) THEN COMBINE_COLORS,/LOWER
	IF NOT KEYWORD_SET(UPPER_SET) THEN COMBINE_COLORS,/UPPER
;
;  Force the combined color tables to be displayed.
;
	COMBINE_COLORS,LOWER=0,UPPER=0
;
;  If no color table has yet been loaded, then load the current table.  Store
;  the current tables in the XLOAD common block.
;
	IF (N_ELEMENTS(R_ORIG) LE 0) THEN TVLCT, R_ORIG, G_ORIG, B_ORIG, /GET
	IF NOT KEYWORD_SET(NOLOAD) THEN BEGIN
		R0 = R_CURR		;Save original colors
		G0 = G_CURR
		B0 = B_CURR
		R1 = R_ORIG
		G1 = G_ORIG
		B1 = B_ORIG
	ENDIF
;
;  Show the current color tables in the graphics widgets.
;
	WIDGET_CONTROL, LSHOW, GET_VALUE=SHOW_WIN
	WSET, SHOW_WIN
	A = INDGEN(256) # REPLICATE(1,W_HEIGHT)
	BSCALE, A, /COMBINED
	TV, A
	WIDGET_CONTROL, RSHOW, GET_VALUE=SHOW_WIN
	WSET, SHOW_WIN
	A = INDGEN(256) # REPLICATE(1,W_HEIGHT)
	BSCALE, A, /COMBINED, /LOWER
	TV, A
	IF (CUR_WIN NE -1) THEN WSET, CUR_WIN
;
;  Start the widget manager.
;
	XMANAGER, "xload_two", BASE, GROUP_LEADER = GROUP
;
EXIT_POINT:
	END
;******************************************************************************
;  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
;******************************************************************************
	PRO XLOAD_EVENT, EVENT
;
;  Event handler for the XLOAD widget routine.
;
	COMMON COLORS, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR
	COMMON XLOAD, LEFT, RIGHT, VEL, R0, G0, B0, R1, G1, B1
;
;  Get the widget event.
;
	WIDGET_CONTROL, EVENT.ID, GET_UVALUE = EVENTVAL
;
;  Get the current values of the stretch parameters.
;
	ABSTOP = !D.TABLE_SIZE -1
	WIDGET_CONTROL, LEFT.TOP,   GET_VALUE = THETOP
	WIDGET_CONTROL, LEFT.BOT,   GET_VALUE = THEBOT
	WIDGET_CONTROL, LEFT.GAMMA, GET_VALUE = GAMMA
	GAMMA = 10^((GAMMA/50.) - 1)
;
;  Process the event.  If the top slider was moved, then change the top value,
;  and stretch the color table accordingly.  If the top and bottom sliders are
;  locked together, then also move the bottom slider.
;
	CASE EVENTVAL OF
		"TOP":	BEGIN
			IF LEFT.LOCK NE 0 THEN BEGIN
				THEBOT = (THETOP - LEFT.LOCK) > 0 < 100
				WIDGET_CONTROL, LEFT.BOT, SET_VALUE=THEBOT
			ENDIF
			GOTO, DO_STRETCH
			END
;
;  If the bottom slider was moved, then change the bottom value, and stretch
;  the color table accordingly.  If the top and bottom sliders are locked
;  together, then also move the top slider.
;
		"BOTTOM": BEGIN
			IF LEFT.LOCK NE 0 THEN BEGIN
				THETOP = (THEBOT + LEFT.LOCK) > 0 < 100
				WIDGET_CONTROL, LEFT.TOP, SET_VALUE=THETOP
			ENDIF
			GOTO, DO_STRETCH
			END
;
;  The gamma slider was moved.
;
		"GAMMA": BEGIN
			WIDGET_CONTROL, LEFT.GAMMA, GET_VALUE = GAMMA
			GAMMA = 10^((GAMMA/50.) - 1)
			WIDGET_CONTROL, LEFT.G_LBL, SET_VALUE = STRING(GAMMA)
			GOTO, DO_STRETCH
			END
;
;  The top and bottom sliders were either locked together, or unlocked.
;  Desensitize the option selected, and sensitize the inverse option.
;
		"LOCK":	BEGIN
			IF LEFT.LOCK EQ 0 THEN $
				LEFT.LOCK = THETOP - THEBOT $
				ELSE LEFT.LOCK = 0
			FOR I=0,1 DO WIDGET_CONTROL, LEFT.LOCK_BUTTON(I), $
				SENSITIVE = I EQ (LEFT.LOCK NE 0)
			END
;
;  Chopping was either turned on or off.  Desensitize the option selected, and
;  sensitize the inverse option.
;
		"CHOP":	BEGIN
			LEFT.CHOP = 1-LEFT.CHOP
			FOR I=0,1 DO WIDGET_CONTROL, LEFT.CHOP_BUTTON(I), $
				SENSITIVE = LEFT.CHOP EQ I
			GOTO, DO_STRETCH		;Redraw
			END
;
;  The gamma type was changed.
;
		"GAMMATYPE": BEGIN
			LEFT.GAMMATYPE = 1-LEFT.GAMMATYPE
			FOR I=0,1 DO WIDGET_CONTROL, LEFT.GAMMA_BUTTON(I), $
				SENSITIVE = LEFT.GAMMATYPE EQ I
			GOTO, DO_STRETCH
			END
;
;  The recenter gamma slider option was selected.
;
		"CENTERGAMMA": BEGIN
			WIDGET_CONTROL, LEFT.GAMMA, SET_VALUE = 50
			GAMMA = 1.0
			WIDGET_CONTROL, LEFT.G_LBL, SET_VALUE = STRING(GAMMA)
			GOTO, DO_STRETCH
			END
;
;  Display a help message.
;
		"HELP":	BEGIN
			SERTS_HELP = GETENV("SERTS_HELP")
			IF SERTS_HELP EQ "" THEN BEGIN
				FILE = FILEPATH("xloadct.txt",SUBDIR='help')
			END ELSE FILE = SERTS_HELP + "xload.txt"
			XDISPLAYFILE, FILE, TITLE = "XLOAD Help", $
				GROUP = EVENT.TOP, $
				WIDTH = 55, $
				HEIGHT = 16
			END
;
;  Restore the original tables.
;
		"RESTORE": BEGIN
			R_CURR = R0
			G_CURR = G0
			B_CURR = B0
			R_ORIG = R1
			G_ORIG = G1
			B_ORIG = B1
			TVLCT, R0, G0, B0
			WIDGET_CONTROL, LEFT.TOP,   SET_VALUE = 100
			WIDGET_CONTROL, LEFT.BOT,   SET_VALUE = 0
			WIDGET_CONTROL, LEFT.GAMMA, SET_VALUE = 50
			WIDGET_CONTROL, LEFT.G_LBL, SET_VALUE = STRING(1.0)
			END
;
;  Reverse the table.
;
		"REVERSE": BEGIN
			IF LEFT.VEL THEN BEGIN
				LEFT.VEL = -LEFT.VEL
				LOAD_VEL, LIGHTEN   = (VEL.VALUE EQ 1),	$
					  GREEN     = (VEL.VALUE EQ 2),	$
					  TURQUOISE = (VEL.VALUE EQ 3), $
					  REVERSE = (LEFT.VEL EQ -1)
			END ELSE BEGIN
				R_ORIG = REVERSE(R_ORIG)
				G_ORIG = REVERSE(G_ORIG)
				B_ORIG = REVERSE(B_ORIG)
			ENDELSE
			GOTO, DO_STRETCH		;And redraw
			END
;
;  Quit from the widget program.
;
		"DONE": BEGIN
			WIDGET_CONTROL, EVENT.TOP, /DESTROY
			R0 = 0 & G0 = 0 & B0 = 0	;Free the common block
			R1 = 0 & G1 = 0 & B1 = 0
			END
;
;  Split the color tables.
;
		"SPLIT": BEGIN
			WIDGET_CONTROL, EVENT.TOP, /DESTROY
			IF LEFT.GROUP NE 0 THEN GROUP = LEFT.GROUP
			XLOAD_TWO, SILENT=LEFT.SILENT, GROUP=GROUP, /NOLOAD
			END
;
;  Select the color for the positive part of the velocity color table.
;
		"BLUE":	BEGIN
			VEL.VALUE = 0
			GOTO, SET_COLOR
			END
		"LIGHTBLUE": BEGIN
			VEL.VALUE = 1
			GOTO, SET_COLOR
			END
		"GREEN": BEGIN
			VEL.VALUE = 2
			GOTO, SET_COLOR
			END
		"TURQUOISE": BEGIN
			VEL.VALUE = 3
SET_COLOR:
			FOR I = 0,3 DO WIDGET_CONTROL, VEL.COLOR(I),	$
				SENSITIVE = I NE VEL.VALUE
			GOTO, LOAD_VELOCITY
			END
;
;  Load the velocity color table.
;
		"VELOCITY": BEGIN
LOAD_VELOCITY:
			LOAD_VEL, LIGHTEN   = (VEL.VALUE EQ 1),	$
				  GREEN     = (VEL.VALUE EQ 2),	$
				  TURQUOISE = (VEL.VALUE EQ 3)
			LEFT.VEL = 1
			GOTO, SET_VELOCITY
			END
;
;  Define the current table as being either a velocity or intensity color
;  table.
;
		"SETVEL": BEGIN
			LEFT.VEL = 1 - LEFT.VEL
SET_VELOCITY:
			WIDGET_CONTROL, LEFT.BOT, SENSITIVE = (1 - LEFT.VEL)
			WIDGET_CONTROL, VEL.OPTIONS, SENSITIVE=LEFT.VEL
			FOR I=0,1 DO WIDGET_CONTROL, LEFT.SETV_BUTTON(I), $
				SENSITIVE = LEFT.VEL EQ I
			GOTO, DO_STRETCH
			END
;
;  Load one of the standard color tables.
;
		ELSE: BEGIN
			I = FIX(EVENTVAL)
			LOADCT, SILENT=LEFT.SILENT, I
			IF LEFT.VEL NE 0 THEN BEGIN
				LEFT.VEL = 0
				GOTO, SET_VELOCITY
			ENDIF
;
;  Transfer point for restretching the color table.  First, decide which kind
;  of gamma correction to apply:  color table shift (default) or intensity
;  shift.
;
DO_STRETCH:
			IF LEFT.GAMMATYPE THEN BEGIN
				IGAMMA = GAMMA
				GAMMA = 1
			END ELSE IGAMMA = 1
;
;  Stretch the color table.
;
			IF LEFT.VEL NE 0 THEN BEGIN
				VEL_STRETCH, THETOP/100., GAMMA
			END ELSE BEGIN
				STRETCH,THEBOT*ABSTOP/100,THETOP*ABSTOP/100,$
					GAMMA, CHOP = LEFT.CHOP
			ENDELSE
;
;  if requested, apply the gamma correction to the intensities.
;
			IF IGAMMA NE 1 THEN	$
				GAMMA_CT, IGAMMA, /CURRENT, /INTENSITY
			END
	ENDCASE
;
	END
;******************************************************************************
;  ****    ****    ****    ****    ****    ****    ****    ****    ****    ****
;******************************************************************************
	PRO XLOAD, SILENT=SILENT, GROUP=GROUP, NOLOAD=NOLOAD, TWO=TWO
;
	COMMON COLORS, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR
	COMMON XLOAD, LEFT, RIGHT, VEL, R0, G0, B0, R1, G1, B1
;
;  If a copy of XLOAD is already running, then exit.
;
	IF (XREGISTERED("xload") NE 0) THEN GOTO, EXIT_POINT
;
;  If the keyword TWO is set, then call XLOAD_TWO.
;
	IF KEYWORD_SET(TWO) THEN BEGIN
		XLOAD_TWO, SILENT=SILENT, GROUP=GROUP, NOLOAD=NOLOAD
		RETURN
	ENDIF
;
;  Initialize the common block.
;
	LEFT = {XLOAD,	VEL: 0,			$
			TOP: 0L,		$
			BOT: 0L,		$
			GAMMA: 0L,		$
			G_LBL: 0L,		$
			LOCK: 0,		$
			CHOP: 0,		$
			GAMMATYPE: 0,		$
			LOCK_BUTTON:  [0L,0L],	$
			CHOP_BUTTON:  [0L,0L],	$
			GAMMA_BUTTON: [0L,0L],	$
			SETV_BUTTON:  [0L,0L],	$
			SILENT: 0,		$
			GROUP: 0}
	VEL = {XLOAD_VEL, OPTIONS: 0L, VALUE: 0, COLOR: [0L, 0L, 0L, 0L]}
;
;  Save the value of the GROUP keyword in the common block.
;
	IF N_ELEMENTS(GROUP) NE 0 THEN LEFT.GROUP = GROUP
;
;  Parse whether the routine should print informational messages when a new
;  color table is loaded.
;
	IF (N_ELEMENTS(SILENT) EQ 1) THEN LEFT.SILENT = SILENT ELSE	$
		LEFT.SILENT = 1
;
;  Open the file containing the standard color tables, and define an associated
;  variable for reading the color table names.
;
	OPENR,LUN, FILEPATH('colors.tbl'), /BLOCK,/GET_LUN
	AA=ASSOC(LUN, BYTARR(32))	;Get name
;
;  Define some defaults.
;
	W_HEIGHT = 50			;Height of ramp
	CUR_WIN = !D.WINDOW
;
;  Define the widget base.
;
	BASE = WIDGET_BASE(TITLE="Xload", /COLUMN)
;
;  Define the individual widget components.  Start with the graphics window for
;  displaying the color table, the "DONE" and "HELP" buttons.
;
	SHOW = WIDGET_DRAW(BASE, YSIZE=W_HEIGHT, XSIZE=256, /FRAME, RETAIN = 2)
	JUNK = WIDGET_BASE(BASE, /ROW)
	DONE = WIDGET_BUTTON(JUNK, VALUE=' Done ', UVALUE = "DONE")
	JUNK1 = WIDGET_BUTTON(JUNK, VALUE=' Help ', UVALUE = "HELP")
;
;  Define the options.
;
	JUNK1 = WIDGET_BUTTON(JUNK, VALUE=' Options ', /MENU)
	LEFT.LOCK_BUTTON(0) = WIDGET_BUTTON(JUNK1, VALUE='Lock Sliders', $
		UVALUE="LOCK")
	LEFT.LOCK_BUTTON(1) = WIDGET_BUTTON(JUNK1, VALUE='Unlock Sliders', $
		UVALUE="LOCK")
	LEFT.CHOP_BUTTON(0) = WIDGET_BUTTON(JUNK1, VALUE='Chop Top',	$
		UVALUE="CHOP")
	LEFT.CHOP_BUTTON(1) = WIDGET_BUTTON(JUNK1, VALUE='Clip Top',	$
		UVALUE="CHOP")
	LEFT.GAMMA_BUTTON(0) = WIDGET_BUTTON(JUNK1, VALUE='Gamma Intensity', $
		UVALUE="GAMMATYPE")
	LEFT.GAMMA_BUTTON(1) = WIDGET_BUTTON(JUNK1, VALUE='Gamma Shift', $
		UVALUE="GAMMATYPE")
	JUNK = WIDGET_BUTTON(JUNK1, VALUE='Recenter Gamma Slider',	$
		UVALUE="CENTERGAMMA")
	LEFT.SETV_BUTTON(0) = WIDGET_BUTTON(JUNK1, VALUE='Set Velocity', $
		UVALUE="SETVEL")
	LEFT.SETV_BUTTON(1) = WIDGET_BUTTON(JUNK1, VALUE='Unset Velocity', $
		UVALUE="SETVEL")
	JUNK = WIDGET_BUTTON(JUNK1, VALUE='Reverse Table', UVALUE="REVERSE")
	JUNK = WIDGET_BUTTON(JUNK1, VALUE='Restore Original Table', $
		UVALUE="RESTORE")
;
;  Desensitize the inverse buttons for lock, etc.
;
	WIDGET_CONTROL, LEFT.CHOP_BUTTON(1),  SENSITIVE = 0
	WIDGET_CONTROL, LEFT.LOCK_BUTTON(1),  SENSITIVE = 0
	WIDGET_CONTROL, LEFT.GAMMA_BUTTON(1), SENSITIVE = 0
	WIDGET_CONTROL, LEFT.SETV_BUTTON(1),  SENSITIVE = 0
;
;  Define the top, bottom, and gamma sliders.
;
	SBASE=WIDGET_BASE(BASE, /COLUMN)
	LEFT.BOT = WIDGET_SLIDER(SBASE, TITLE = "Stretch Bottom", MINIMUM=0, $
		MAXIMUM = 100, VALUE = 0, /DRAG, UVALUE = "BOTTOM", XSIZE=256)
	LEFT.TOP = WIDGET_SLIDER(SBASE, TITLE = "Stretch Top", MINIMUM = 0, $
		MAXIMUM = 100, VALUE = 100, /DRAG, UVALUE = "TOP", XSIZE=256)
	LEFT.G_LBL = WIDGET_LABEL(SBASE, VALUE = STRING(1.0))
	LEFT.GAMMA = WIDGET_SLIDER(SBASE, TITLE = "Gamma Correction", $
		MINIMUM = 0, MAXIMUM = 100, VALUE = 50, UVALUE = "GAMMA", $
		/SUPPRESS_VALUE, XSIZE=256)
;
;  Define the buttons for the standard color tables, and close the color table
;  file.
;
	ROWCOL = WIDGET_BASE(BASE, /FRAME, /EXCLUSIVE ,/COLUMN, XSIZE=256)
	FOR I = 0, 15 DO JUNK = WIDGET_BUTTON(ROWCOL, VALUE=STRING(AA(I)), $
		UVALUE = STRING(I), /NO_RELEASE)
	FREE_LUN, LUN
;
;  Define the button for loading the velocity table.
;
	JUNK = WIDGET_BUTTON(BASE, VALUE='Load Velocity Table',	$
		UVALUE="VELOCITY")
;
;  Define the velocity options.
;
	JUNK = WIDGET_BASE(BASE,/ROW)
	VEL.OPTIONS = WIDGET_BUTTON(JUNK, VALUE=' Velocity Options ', /MENU)
	VEL.COLOR(0) = WIDGET_BUTTON(VEL.OPTIONS, VALUE='Blue', UVALUE="BLUE")
	VEL.COLOR(1) = WIDGET_BUTTON(VEL.OPTIONS, VALUE='Light Blue',	$
		UVALUE="LIGHTBLUE")
	VEL.COLOR(2) = WIDGET_BUTTON(VEL.OPTIONS, VALUE='Green',	$
		UVALUE="GREEN")
	VEL.COLOR(3) = WIDGET_BUTTON(VEL.OPTIONS, VALUE='Turquoise',	$
		UVALUE="TURQUOISE")
;
;  Desensitize the velocity options, and the blue color button.
;
	WIDGET_CONTROL, VEL.OPTIONS,  SENSITIVE = 0
	WIDGET_CONTROL, VEL.COLOR(0), SENSITIVE = 0
;
;  Define the button for splitting the color table into two.
;
	JUNK = WIDGET_BUTTON(BASE, VALUE='Split Color Table', UVALUE='SPLIT')
;
;  Realize the widget.
;
	WIDGET_CONTROL, BASE, /REALIZE
;
;  If no color table has yet been loaded, then load the current table.  Store
;  the current tables in the XLOAD common block.
;
	IF (N_ELEMENTS(R_ORIG) LE 0) THEN TVLCT, R_ORIG, G_ORIG, B_ORIG, /GET
	IF NOT KEYWORD_SET(NOLOAD) THEN BEGIN
		R0 = R_CURR		;Save original colors
		G0 = G_CURR
		B0 = B_CURR
		R1 = R_ORIG
		G1 = G_ORIG
		B1 = B_ORIG
	ENDIF
;
;  Show the current color table in the graphics widget.
;
	WIDGET_CONTROL, SHOW, GET_VALUE=SHOW_WIN
	WSET, SHOW_WIN
	TVSCL, INDGEN(256) # REPLICATE(1, W_HEIGHT)
	IF (CUR_WIN NE -1) THEN WSET, CUR_WIN
;
;  Start the widget manager.
;
	XMANAGER, "xload", BASE, GROUP_LEADER = GROUP
;
EXIT_POINT:
	END
