	PRO QMS,FILENAME,LANDSCAPE=LANDSCAPE,PORTRAIT=PORTRAIT
;+
; Project     : SOHO - CDS
;
; Name        : 
;	QMS
; Purpose     : 
;	Sets graphics device to QMS Quikplot file.
; Explanation : 
;	This procedure sets the system variables needed to write QMS plot
;	files.  The plot is done in landscape mode, using most of the paper.
;
;	SETPLOT is called to save and set the system variables, and DEVICE is
;	called to set the plot window size and orientation, and to open the
;	file.
;
;	If the plot file is already open, then calling QMS without any
;	parameters or keywords allows the user to write into the already opened
;	file, in the same mode as before.
;
; Use         : 
;	QMS  [, FILENAME ]
;
;	QMS				;Open QMS plot file
;	   ... plotting commands ...	;Create plot
;	QMPLOT				;Close & plot file, reset to prev. dev.
;	   or
;	QMCLOSE				;Close w/o printing,  "    "   "    "
;
; Inputs      : 
;	None required.
; Opt. Inputs : 
;	FILENAME - Name of QMS plot file to be opened.  If not passed, and no
;		   filename was previously passed, "idl.bit" is assumed.
; Outputs     : 
;	A message is printed to the screen.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	LANDSCAPE = If set, then plotting is done in LANDSCAPE mode (default).
;	PORTRAIT  = If set, then plotting is done in PORTRAIT mode.  PORTRAIT
;		    takes precedent over LANDSCAPE.
; Calls       : 
;	SETPLOT, FORM_FILENAME
; Common      : 
;	QMS_FILE which contains QMS_FILENAME, the name of the plotting file,
;	and LAST_DEVICE, which is the name of the previous graphics device.
; 
;	Also calls SETPLOT, which uses common block PLOTFILE.
; 
; Restrictions: 
;	Only the routines QMPLOT and QMCLOSE can be used to close the QMS plot
;	file.  It is best if the routines TEK, REGIS, etc. (i.e. those
;	routines that use SETPLOT) are used to change the plotting device.
;
;	In general, the SERTS graphics devices routines use the special system
;	variables !BCOLOR and !ASPECT.  These system variables are defined in
;	the procedure DEVICELIB.  It is suggested that the command DEVICELIB be
;	placed in the user's IDL_STARTUP file.
;
; Side effects: 
;	If the FILENAME parameter, or either the LANDSCAPE or PORTRAIT
;	keywords, is passed then DEVICE is called to open a new file.  Any
;	previously opened QMS plot file would be closed.
; 
;	If a new file is opened, then the DEVICE routine is called with the
;	/LANDSCAPE or /PORTRAIT switch to set the size and orientation of the
;	plot window.
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
;	W.T.T., Feb. 1991, from PS.PRO.
; Written     : 
;	William Thompson, GSFC, February 1991.
; Modified    : 
;	Version 1, William Thompson, GSFC, 27 April 1993.
;		Incorporated into CDS library.
; Version     : 
;	Version 1, 27 April 1993.
;-
;
	COMMON QMS_FILE, QMS_FILENAME, LAST_DEVICE
	RESET = 0
;
;  The filename has been passed.
;
	IF N_PARAMS(0) EQ 1 THEN BEGIN
		QMS_FILENAME = FORM_FILENAME(FILENAME,'.bit')
		RESET = 1
;
;  No filename has yet been passed, or the filename is blank.  Use idl.bit.

;
	END ELSE IF N_ELEMENTS(QMS_FILENAME) EQ 0 THEN BEGIN
		QMS_FILENAME = "idl.bit"
		RESET = 1
	END ELSE IF QMS_FILENAME EQ "" THEN BEGIN
		QMS_FILENAME = "idl.bit"
		RESET = 1
	ENDIF
;
;  Store the name of the current plotting device in the common block.
;
	IF !D.NAME NE 'QMS' THEN LAST_DEVICE = !D.NAME
;
;  Set the plotting device.
;
	SETPLOT,'QMS'
;
;  Determine whether landscape or portrait mode is to be used.
;
	IF N_ELEMENTS(PORTRAIT) NE 0 THEN BEGIN
		DEVICE,/PORTRAIT
		RESET = 1
	END ELSE IF N_ELEMENTS(LANDSCAPE) NE 0 THEN BEGIN
		DEVICE,/LANDSCAPE
		RESET = 1
	END ELSE IF RESET THEN DEVICE,/LANDSCAPE
;
;  Set the filename.
;
	IF RESET THEN DEVICE,FILENAME=QMS_FILENAME
	PRINT,'Plots will now be written to the file ' + QMS_FILENAME
;
	RETURN
	END
