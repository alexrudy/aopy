	PRO PS,FILENAME,LANDSCAPE=LANDSCAPE,PORTRAIT=PORTRAIT,TEX=TEX,  $
		COLOR=COLOR,ENCAPSULATED=ENCAPSULATED,COPY=COPY
;+
; Project     : SOHO - CDS
;
; Name        : 
;	PS
; Purpose     : 
;	Sets graphics device to PostScript file.
; Explanation : 
;	This procedure sets the system variables needed to write PostScript
;	printer plot files.  The default configuration is landscape mode.
;	Alternate modes are (TeX-compatible) encapsulated mode, portrait mode
;	using all of the paper, and color mode (either landscape or portrait)
;	which is compatible with the color printer.
;
;	SETPLOT is called to save and set the system variables.  If a new file
;	is to be opened, then DEVICE is called to set the plot window size and
;	orientation, and to open the file.
;
;	If the plot file is already open, then calling PS without any
;	parameters or keywords allows the user to write into the already opened
;	file, in the same mode as before.
;
; Use         : 
;	PS  [, FILENAME ]
;
;	PS				;Open PostScript plot file
;	   ... plotting commands ...	;Create plot
;	PSPLOT				;Close & plot file, reset to prev. dev.
;	   or
;	PSCLOSE				;Close w/o printing,  "    "   "    "
;
; Inputs      : 
;	None required unless /ENCAPSULATED switch set.  See FILENAME below.
; Opt. Inputs : 
;	FILENAME - Name of postscript file to be opened.  If not passed, and no
;		   filename was previously passed, "idl.ps" is assumed.  If the
;		   /ENCAPSULATED switch is passed, then a filename must be
;		   passed.
; Outputs     : 
;	A message is printed to the screen.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	The following keywords are listed in the order of precedence.
;
;	ENCAPSULATED = If set, then the plot is done in encapsulated landscape
;		       mode.  This is compatible with TeX/LaTeX.
;	TEX	     = A synonym for ENCAPSULATED.
;	PORTRAIT     = If set, then the plot is done in portrait mode, using
;		       all of the paper.
;	LANDSCAPE    = If set, then the plot is done in landscape mode, using
;		       all of the paper.  This is the default mode.
;
;	In addition, the following keyword can be used with any of the others.
;
;	COLOR	     = If set, then a color plot is made.
;	COPY	     = If set, (together with /COLOR) then the current color
;		       table is copied to the PostScript device.  Also, the
;		       SETFLAG routine is called to set TOP equal to the number
;		       of colors.  Also makes sure that !P.COLOR does not
;		       exceed the TOP color.  Requires the SERTS image display
;		       software.
;
; Calls       : 
;	SETPLOT, FORM_FILENAME
; Common      : 
;	PS_FILE which contains PS_FILENAME, the name of the plotting file,
;	LAST_DEVICE, which is the name of the previous graphics device, and
;	various parameters used to keep track of which configuration is being
;	used.
;
;	Also calls SETPLOT, which uses common block PLOTFILE.
;
; Restrictions: 
;	Only the routines PSPLOT and PSCLOSE can be used to close the
;	PostScript file.  It is best if the routines TEK, REGIS, etc. (i.e.
;	those routines that use SETPLOT) are used to change the plotting
;	device.
;
;	In general, the SERTS graphics devices routines use the special system
;	variables !BCOLOR and !ASPECT.  These system variables are defined in
;	the procedure DEVICELIB.  It is suggested that the command DEVICELIB be
;	placed in the user's IDL_STARTUP file.
;
; Side effects: 
;	If the filename, or one of the configuration keywords (ENCAPSULATED,
;	COLOR, PORTRAIT, or LANDSCAPE) are passed, then DEVICE is called to
;	open a new file.  Any previously opened PostScript file would be
;	closed.
;
;	If a new file has to be opened, and if none of the configuration
;	keywords are passed, then the default configuration (LANDSCAPE) is
;	used.  This is true even if the last PostScript file was in a different
;	configuration.
;
;	If not the first time this routine is called, then system variables
;	that affect plotting are reset to previous values.  If it is the first 
;	time the routine is called, !FANCY is set to 1.
;
;	In UNIX, if a new file is opened with the same name as an existing
;	file, then the old file is lost.
;
; Category    : 
;	Utilities, Devices.
; Prev. Hist. : 
;	W.T.T., Nov. 1989.
;	W.T.T., Aug. 1990, added LAST_DEVICE to common block.
;	W.T.T., Feb. 1991, added keywords LANDSCAPE, PORTRAIT, TEX, COLOR.
;	W.T.T., June 1992, fixed bug where CUR_CONFIG was not stored.
;	W.T.T., Nov. 1992, added !P.POSITION to common block.
; Written     : 
;	William Thompson, GSFC, November 1989.
; Modified    : 
;	Version 1, William Thompson, GSFC, 27 April 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 11 November 1993.
;		Added ENCAPSULATED keyword.  Relegated TEX to a synonym.
;	Version 3, William Thompson, GSFC, 14 September 1994
;		Added COPY keyword.
; Version     : 
;	Version 3, 14 September 1994
;-
;
	ON_ERROR,2
	COMMON PS_FILE, PS_FILENAME, LAST_DEVICE, CONFIGS, CUR_CONFIG,  $
		SAVE_CONFIG
;
;  Make sure that the common block is properly initialized.
;
	IF N_ELEMENTS(PS_FILENAME) EQ 0 THEN BEGIN
		PS_FILENAME = ''
		CONFIGS = ['LANDSCAPE','PORTRAIT','TEX','LCOLOR','PCOLOR', $
			'TCOLOR']
		CUR_CONFIG = ''
		DNAME = !D.NAME
		SETPLOT,'PS'
		SAVE = {SAVE_PS,		$
			POSITION: !P.POSITION,	$
			XMARGIN: !X.MARGIN,	$
			XWINDOW: !X.WINDOW,	$
			YMARGIN: !Y.MARGIN,	$
			YWINDOW: !Y.WINDOW,	$
			ZMARGIN: !Z.MARGIN,	$
			ZWINDOW: !Z.WINDOW,	$
			THICK:   !P.THICK,	$
			CHARTHICK: !P.CHARTHICK,$
			XTHICK:  !X.THICK,	$
			YTHICK:  !Y.THICK}
		SETPLOT,DNAME
		SAVE_CONFIG = REPLICATE(SAVE,N_ELEMENTS(CONFIGS))
;
;  Set up the defaults for color landscape mode.
;
		LCOLOR = WHERE(CONFIGS EQ 'LCOLOR')
;		SAVE_CONFIG(LCOLOR).XMARGIN = [15,10]
;		SAVE_CONFIG(LCOLOR).YMARGIN = [6,4]
		SAVE_CONFIG(LCOLOR).THICK     = 5
		SAVE_CONFIG(LCOLOR).CHARTHICK = 5
		SAVE_CONFIG(LCOLOR).XTHICK    = 5
		SAVE_CONFIG(LCOLOR).YTHICK    = 5
;
;  Set up the defaults for color portrait mode.
;
		PCOLOR = WHERE(CONFIGS EQ 'PCOLOR')
;		SAVE_CONFIG(PCOLOR).XMARGIN = [10,6]
;		SAVE_CONFIG(PCOLOR).YMARGIN = [9,7]
		SAVE_CONFIG(PCOLOR).THICK     = 5
		SAVE_CONFIG(PCOLOR).CHARTHICK = 5
		SAVE_CONFIG(PCOLOR).XTHICK    = 5
		SAVE_CONFIG(PCOLOR).YTHICK    = 5
	ENDIF
;
;  Determine which configuration is to be used.  First, look at the keywords.
;
	IF KEYWORD_SET(ENCAPSULATED) OR KEYWORD_SET(TEX) THEN BEGIN
		CONFIG = 'TEX'
		RESET = 1
		IF N_PARAMS(0) EQ 0 THEN MESSAGE,	$
			'A filename must be passed when using ' +	$
			'/ENCAPSULATED or /TEX'
	END ELSE IF KEYWORD_SET(PORTRAIT) THEN BEGIN
		RESET = 1
		CONFIG = 'PORTRAIT'
	END ELSE IF KEYWORD_SET(LANDSCAPE) THEN BEGIN
		RESET = 1
		CONFIG = 'LANDSCAPE'
;
;  If a filename has been passed, but no keywords, then reset to landscape
;  mode.
;
	END ELSE IF N_PARAMS(0) EQ 1 THEN BEGIN
		RESET = 1
		CONFIG = 'LANDSCAPE'
;
;  If no file is currently open, but no keywords have been passed, then reset
;  to landscape mode.
;
	END ELSE IF PS_FILENAME EQ '' THEN BEGIN
		RESET = 1
		CONFIG = 'LANDSCAPE'
;
;  Otherwise, no reset is necessary.
;
	END ELSE BEGIN
		RESET = 0
		CONFIG = CUR_CONFIG
	ENDELSE
;
;  Modify the configuration according to the COLOR keyword.
;
	IF KEYWORD_SET(COLOR) THEN BEGIN
		RESET = 1
		IF CONFIG EQ 'PORTRAIT'  THEN CONFIG = 'PCOLOR'
		IF CONFIG EQ 'LANDSCAPE' THEN CONFIG = 'LCOLOR'
		IF CONFIG EQ 'TEX'       THEN CONFIG = 'TCOLOR'
	ENDIF
;
;  Determine what the filename is to be.
;
	IF N_PARAMS(0) EQ 1 THEN BEGIN
		PS_FILENAME = FORM_FILENAME(FILENAME,'.ps')
	END ELSE IF RESET THEN BEGIN
		PS_FILENAME = 'idl.ps'
	ENDIF
;
;  Store the name of the current plotting device in the common block.  Set the
;  plotting device to PostScript.
;
	IF !D.NAME NE 'PS' THEN LAST_DEVICE = !D.NAME
	SETPLOT,'PS',COPY=COPY
;
;  If the configuration is to be reset, then store the parameters pertaining to
;  the old configuration.
;
	IF (CONFIG NE CUR_CONFIG) AND (CUR_CONFIG NE '') THEN BEGIN
		NCONFIG = WHERE(CONFIGS EQ CUR_CONFIG)
		SAVE_CONFIG(NCONFIG).POSITION = !P.POSITION
		SAVE_CONFIG(NCONFIG).XMARGIN = !X.MARGIN
		SAVE_CONFIG(NCONFIG).XWINDOW = !X.WINDOW
		SAVE_CONFIG(NCONFIG).YMARGIN = !Y.MARGIN
		SAVE_CONFIG(NCONFIG).YWINDOW = !Y.WINDOW
		SAVE_CONFIG(NCONFIG).ZMARGIN = !Z.MARGIN
		SAVE_CONFIG(NCONFIG).ZWINDOW = !Z.WINDOW
		SAVE_CONFIG(NCONFIG).THICK   = !P.THICK
		SAVE_CONFIG(NCONFIG).CHARTHICK = !P.CHARTHICK
		SAVE_CONFIG(NCONFIG).XTHICK  = !X.THICK
		SAVE_CONFIG(NCONFIG).YTHICK  = !Y.THICK
	ENDIF
	CUR_CONFIG = CONFIG
;
;  Restore the parameters associated with the selected configuration.
;
	IF RESET THEN BEGIN
		NCONFIG = WHERE(CONFIGS EQ CONFIG)
		!P.POSITION = SAVE_CONFIG(NCONFIG).POSITION
		!X.MARGIN = SAVE_CONFIG(NCONFIG).XMARGIN
		!X.WINDOW = SAVE_CONFIG(NCONFIG).XWINDOW
		!Y.MARGIN = SAVE_CONFIG(NCONFIG).YMARGIN
		!Y.WINDOW = SAVE_CONFIG(NCONFIG).YWINDOW
		!Z.MARGIN = SAVE_CONFIG(NCONFIG).ZMARGIN
		!Z.WINDOW = SAVE_CONFIG(NCONFIG).ZWINDOW
		!P.THICK  = SAVE_CONFIG(NCONFIG).THICK
		!P.CHARTHICK = SAVE_CONFIG(NCONFIG).CHARTHICK
		!X.THICK  = SAVE_CONFIG(NCONFIG).XTHICK
		!Y.THICK  = SAVE_CONFIG(NCONFIG).YTHICK
;
;  If necessary, then set the device parameters according to the selected
;  configuration.
;
		CASE CONFIG OF
			'LANDSCAPE': DEVICE, FILENAME=PS_FILENAME, /LANDSCAPE,$
				ENCAPSULATED=0, COLOR=0
;
			'PORTRAIT':  DEVICE, FILENAME=PS_FILENAME, /PORTRAIT, $
				/INCHES, XOFFSET=0.75, YOFFSET=0.75,	      $
				XSIZE=7.0, YSIZE=9.5, ENCAPSULATED=0, COLOR=0
;
			'TEX':  DEVICE, FILENAME=PS_FILENAME, /PORTRAIT,      $
				/ENCAPSULATED, COLOR=0
;
			'LCOLOR':  DEVICE, FILENAME=PS_FILENAME, /LANDSCAPE,  $
				/COLOR, /INCHES, YOFFSET=9.75, XSIZE=8.5,     $
				ENCAPSULATED=0, BITS_PER_PIXEL=8
;
			'PCOLOR':  DEVICE, FILENAME=PS_FILENAME, /PORTRAIT,   $
				/COLOR, /INCHES, XOFFSET=0.75, YOFFSET=1.25,  $
				XSIZE=7.0, YSIZE=8.5, ENCAPSULATED=0,	      $
				BITS_PER_PIXEL=8
;
			'TCOLOR':  DEVICE, FILENAME=PS_FILENAME, /PORTRAIT,   $
				/ENCAPSULATED, /COLOR, BITS_PER_PIXEL=8
		ENDCASE
	ENDIF
;
	PRINT,'Plots will now be written to the file ' + PS_FILENAME
	RETURN
	END
